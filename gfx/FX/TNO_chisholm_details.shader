Includes = {
	"buttonstate.fxh"
}

PixelShader =
{
	Samplers =
	{
		MapTexture =
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
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
};

VertexShader =
{
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float encoded = floor(Offset.x * 11.0f + 0.5f);
			float bandCode = floor(encoded / 1000.0f);
			float packed = encoded - bandCode * 1000.0f;
			float role = floor(packed / 100.0f);
			packed -= role * 100.0f;
			float mode = floor(packed / 10.0f);
			float elapsed = Time - AnimationTime;
			float2 pos = v.vPosition.xy;
			float originalX = pos.x;
			float originalY = pos.y;
			float pageHeight = 158.0f;


			if (role < 0.5f && mode > 0.5f && mode < 2.5f)
			{
				float turn = mode < 1.5f ? smoothstep(0.10f, 0.58f, elapsed) : smoothstep(0.42f, 0.90f, elapsed);
				float scale = mode < 1.5f ? lerp(1.0f, 0.025f, turn) : lerp(0.025f, 1.0f, turn);
				float distanceFromHinge = (pageHeight - pos.y) / pageHeight;
				pos.y = pageHeight - distanceFromHinge * scale * pageHeight;
				pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
			}
			else if (role < 0.5f && mode > 2.5f && bandCode > 0.5f && bandCode < 1.5f)
			{
				float ripProgress = smoothstep(0.72f, 1.76f, elapsed);
				float carry = smoothstep(0.58f, 1.0f, ripProgress);
				float horizontal = originalX / 352.0f;
				float leftPull = smoothstep(0.0f, 0.45f, ripProgress);
				float rightPull = smoothstep(0.55f, 1.0f, ripProgress);
				float leftCurl = sin(leftPull * 3.14159265f);
				float rightCurl = sin(rightPull * 3.14159265f);
				float pull = lerp(leftPull, rightPull, horizontal);
				float curl = lerp(leftCurl, rightCurl, horizontal);
				pos.x = originalX - 28.0f * pull - 260.0f * carry - originalY / pageHeight * curl * 24.0f;
				pos.y = originalY * (1.0f - curl * 0.24f) - 34.0f * pull - 190.0f * carry;
			}

			Out.vPosition = mul(WorldViewProjectionMatrix, float4(pos, v.vPosition.z, 1.0f));
			Out.vLocalUV = float2(v.vTexCoord.x * 11.0f, v.vTexCoord.y);
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float encoded = floor(Offset.x * 11.0f + 0.5f);
			float bandCode = floor(encoded / 1000.0f);
			float packed = encoded - bandCode * 1000.0f;
			float role = floor(packed / 100.0f);
			packed -= role * 100.0f;
			float mode = floor(packed / 10.0f);
			float elapsed = Time - AnimationTime;
			float alpha = 1.0f;

			if (bandCode < 0.5f && role > 0.5f && mode > 0.5f && mode < 2.5f)
				alpha = step(0.90f, elapsed);
			else if (role < 0.5f && mode < 0.5f)
				alpha = 0.0f;
			else if (role < 0.5f && mode > 0.5f && mode < 1.5f)
				alpha = 1.0f - smoothstep(0.48f, 0.60f, elapsed);
			else if (role < 0.5f && mode > 1.5f && mode < 2.5f)
				alpha = smoothstep(0.38f, 0.50f, elapsed);

			float bandMask = 1.0f;
			if (bandCode > 0.5f && bandCode < 4.5f)
			{
				float band = bandCode - 1.0f;
				if (mode > 2.5f)
				{
					if (bandCode > 1.5f)
						bandMask = 0.0f;
				}
				else if (v.vLocalUV.y < band * 0.25f || v.vLocalUV.y >= (band + 1.0f) * 0.25f)
					bandMask = 0.0f;
			}

			float2 pagePixel = v.vLocalUV * float2(352.0f, 158.0f);
			float4 outputColor = tex2D(MapTexture, float2(v.vLocalUV.x / 11.0f, v.vLocalUV.y));

			if (pagePixel.x >= 193.0f && pagePixel.x < 319.0f && pagePixel.y >= 126.0f && pagePixel.y < 147.0f)
			{
				float signatureVisibility = 0.0f;
				if (role < 0.5f && mode > 2.5f && bandCode > 0.5f && bandCode < 1.5f)
				{
					float2 signatureUV = (pagePixel - float2(193.0f, 126.0f)) / float2(126.0f, 21.0f);
					float writeProgress = smoothstep(0.08f, 0.66f, elapsed);
					float strokeOrder = signatureUV.x;
					strokeOrder += sin(signatureUV.y * 31.0f + signatureUV.x * 9.0f) * 0.018f;
					strokeOrder += sin(signatureUV.y * 67.0f + 1.4f) * 0.008f;
					signatureVisibility = 1.0f - smoothstep(writeProgress - 0.018f, writeProgress + 0.018f, strokeOrder);
					float wetInk = 1.0f - smoothstep(0.0f, 0.045f, abs(strokeOrder - writeProgress));
					outputColor.rgb += wetInk * outputColor.a * float3(0.08f, 0.15f, 0.14f);
				}
				outputColor.a *= signatureVisibility;
			}
			float ripShade = 1.0f;
			float ripFade = 1.0f;
			if (role < 0.5f && mode > 2.5f && bandCode > 0.5f && bandCode < 1.5f)
			{
				float ripProgress = smoothstep(0.72f, 1.76f, elapsed);
				float pointPull = smoothstep(v.vLocalUV.x * 0.55f, v.vLocalUV.x * 0.55f + 0.45f, ripProgress);
				float curl = sin(pointPull * 3.14159265f);
				ripShade = 1.0f - curl * 0.34f;
				ripFade = 1.0f - smoothstep(0.88f, 1.0f, ripProgress);
			}
			outputColor *= Color;
			outputColor.rgb *= ripShade;
			outputColor.a *= alpha * bandMask * ripFade;
			return outputColor;
		}
	]]
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}

Effect Up
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Down
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Disable
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Over
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
