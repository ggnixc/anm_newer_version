Includes = {
	"buttonstate.fxh"
}

PixelShader = {
	Samplers = {
		MapTexture = {
			Index = 0
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

VertexStruct VS_OUTPUT
{
	float4 vPosition : PDX_POSITION;
	float2 vLocalUV : TEXCOORD0;
	float vEncodedFrame : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.f));
			Out.vLocalUV = float2(v.vTexCoord.x * 6.f, v.vTexCoord.y);
			Out.vEncodedFrame = floor(Offset.x * 6.f + 1.5f);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 SampleTop(float contact, float2 uv)
		{
			float paddedX = uv.x * 493.f / 533.f;
			return tex2D(MapTexture, float2((contact + paddedX) / 6.f, uv.y * 0.5f));
		}

		float4 SampleBottom(float contact, float2 uv)
		{
			float paddedX = uv.x * 493.f / 533.f;
			return tex2D(MapTexture, float2((contact + paddedX) / 6.f, 0.5f + uv.y * 0.5f));
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float code = max(0.f, v.vEncodedFrame - 1.f);
			float fromContact = floor(code / 10.f);
			float toContact = code - fromContact * 10.f;
			float direction = toContact >= fromContact ? 1.f : -1.f;
			float steps = abs(toContact - fromContact);
			float elapsed = max(0.f, Time - AnimationTime);
			float stepDuration = 0.42f;

			if (steps < 0.5f || elapsed >= steps * stepDuration)
				return float4(0.f, 0.f, 0.f, 0.f);

			float stepIndex = min(steps - 1.f, floor(elapsed / stepDuration));
			float phase = saturate((elapsed - stepIndex * stepDuration) / stepDuration);
			float currentContact = fromContact + direction * stepIndex;
			float nextContact = currentContact + direction;
			float angle = phase * 3.14159265f;
			float projection = cos(angle);
			float projectedHeight = max(0.002f, abs(projection) * 0.5f);
			float depth = sin(angle);
			float cardX = v.vLocalUV.x * 533.f / 493.f;
			float sourceX = cardX;
			// Match the Chisholm page-turn perspective: the hinge remains fixed
			// while the loose edge shifts to the right as it rises off the page.
			// The shift is applied after finding distance from the hinge, keeping
			// the card continuous instead of rotating its left and right edges.
			float rightShift = depth * 0.05f;

			float4 color = float4(0.f, 0.f, 0.f, 0.f);
			if (cardX >= 0.f && cardX <= 1.f && v.vLocalUV.y < 0.5f) {
				float backgroundContact = direction > 0.f ? nextContact : currentContact;
				color = SampleTop(backgroundContact, float2(cardX, v.vLocalUV.y * 2.f));
			} else if (cardX >= 0.f && cardX <= 1.f) {
				color = SampleBottom(currentContact, float2(cardX, (v.vLocalUV.y - 0.5f) * 2.f));
			}

			if (direction > 0.f) {
				if (projection >= 0.f && v.vLocalUV.y >= 0.5f - projectedHeight && v.vLocalUV.y <= 0.5f) {
					float sourceY = (v.vLocalUV.y - (0.5f - projectedHeight)) / projectedHeight;
					float movingX = sourceX - (1.f - sourceY) * rightShift;
					if (movingX >= 0.f && movingX <= 1.f) {
						color = SampleTop(currentContact, float2(movingX, sourceY));
						color.rgb *= 0.62f + abs(projection) * 0.38f;
					}
				} else if (projection < 0.f && v.vLocalUV.y >= 0.5f && v.vLocalUV.y <= 0.5f + projectedHeight) {
					float sourceY = (v.vLocalUV.y - 0.5f) / projectedHeight;
					float movingX = sourceX - sourceY * rightShift;
					if (movingX >= 0.f && movingX <= 1.f) {
						color = SampleBottom(currentContact, float2(movingX, sourceY));
						color.rgb *= 0.52f + abs(projection) * 0.32f;
					}
				}
			} else {
				if (projection >= 0.f && v.vLocalUV.y >= 0.5f && v.vLocalUV.y <= 0.5f + projectedHeight) {
					float sourceY = (v.vLocalUV.y - 0.5f) / projectedHeight;
					float movingX = sourceX - sourceY * rightShift;
					if (movingX >= 0.f && movingX <= 1.f) {
						color = SampleBottom(currentContact, float2(movingX, sourceY));
						color.rgb *= 0.52f + abs(projection) * 0.32f;
					}
				} else if (projection < 0.f && v.vLocalUV.y >= 0.5f - projectedHeight && v.vLocalUV.y <= 0.5f) {
					float sourceY = (v.vLocalUV.y - (0.5f - projectedHeight)) / projectedHeight;
					float movingX = sourceX - (1.f - sourceY) * rightShift;
					if (movingX >= 0.f && movingX <= 1.f) {
						color = SampleTop(nextContact, float2(movingX, sourceY));
						color.rgb *= 0.62f + abs(projection) * 0.38f;
					}
				}
			}

			float hingeShadow = 1.f - depth * 0.22f * saturate(1.f - abs(v.vLocalUV.y - 0.5f) * 18.f);
			color.rgb *= hingeShadow;
			return color * Color;
		}
	]]
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}

Effect Up { VertexShader = "VertexShaderMain" PixelShader = "PixelShaderMain" }
Effect Down { VertexShader = "VertexShaderMain" PixelShader = "PixelShaderMain" }
Effect Disable { VertexShader = "VertexShaderMain" PixelShader = "PixelShaderMain" }
Effect Over { VertexShader = "VertexShaderMain" PixelShader = "PixelShaderMain" }
