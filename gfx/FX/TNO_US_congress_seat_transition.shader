Includes = {
	"buttonstate.fxh"
}

PixelShader = {
	Samplers = {
		MapTexture = {
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

VertexStruct VS_OUTPUT {
	float4 vPosition : PDX_POSITION;
	float2 vLocalUV : TEXCOORD0;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			// Dynamic-list icon frames are delivered through NextOffset. Unlike
			// Offset, this is already the one-based scripted frame divided by six.
			// mode * 1000000 + (splitY + 8) * 10000 + side * 1000
			// + sourceFrame * 10 + targetFrame.
			float encoded = floor(NextOffset.x * 6.0f + 0.5f);
			float elapsed = clamp((Time - AnimationTime) / 0.75f, 0.0f, 1.0f);
			float progress = elapsed * elapsed * (3.0f - 2.0f * elapsed);
			float2 position = v.vPosition.xy;

			// 400000..441615 is the compact vote-to-vote payload. Decode from
			// the least-significant mixed-base fields back toward the old split.
			if (encoded >= 400000.0f && encoded < 500000.0f)
			{
				float payload = encoded - 400000.0f;
				payload = floor(payload / 6.0f); // target frame
				payload = floor(payload / 6.0f); // source frame
				float newSideBit = mod(payload, 2.0f);
				payload = floor(payload / 2.0f);
				float newSplitY = mod(payload, 17.0f) - 8.0f;
				payload = floor(payload / 17.0f);
				float oldSideBit = mod(payload, 2.0f);
				payload = floor(payload / 2.0f);
				float oldSplitY = mod(payload, 17.0f) - 8.0f;

				float oldDirection = oldSideBit < 0.5f ? -1.0f : 1.0f;
				float newDirection = newSideBit < 0.5f ? -1.0f : 1.0f;
				float2 oldOffset = float2(oldDirection * 8.0f, oldDirection * oldSplitY);
				float2 newOffset = float2(newDirection * 8.0f, newDirection * newSplitY);
				position += lerp(oldOffset, newOffset, progress);
			}
			else
			{
				float directFrame = encoded < 1000.0f ? 1.0f : 0.0f;
				float mode = directFrame > 0.5f ? 0.0f : floor(encoded / 1000000.0f);
				float remainder = encoded - mode * 1000000.0f;
				float splitYCode = floor(remainder / 10000.0f);
				float splitY = splitYCode - 8.0f;
				remainder -= splitYCode * 10000.0f;
				float side = floor(remainder / 1000.0f);
				float splitAmount = 0.0f;
				if (mode > 0.5f && mode < 1.5f)
					splitAmount = progress;
				else if (mode > 1.5f && mode < 2.5f)
					splitAmount = 1.0f;
				else if (mode > 2.5f && mode < 3.5f)
					splitAmount = 1.0f - progress;
				float direction = side < 1.5f ? -1.0f : 1.0f;
				position.x += direction * 8.0f * splitAmount;
				position.y += direction * splitY * splitAmount;
			}

			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.0f));
			// vTexCoord remains local to the first of the six physical atlas frames;
			// Offset carries the scripted frame metadata separately.
			Out.vLocalUV = float2(v.vTexCoord.x * 6.0f, v.vTexCoord.y);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 SampleAuthoredFrame(float frame, float2 uv)
		{
			return tex2D(MapTexture, float2((frame + uv.x) / 6.0f, uv.y));
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float encoded = floor(NextOffset.x * 6.0f + 0.5f);
			if (encoded < 1000.0f)
			{
				float authoredFrame = clamp(encoded - 1.0f, 0.0f, 5.0f);
				return SampleAuthoredFrame(authoredFrame, v.vLocalUV) * Color;
			}
			float elapsed = clamp((Time - AnimationTime) / 0.75f, 0.0f, 1.0f);
			float progress = elapsed * elapsed * (3.0f - 2.0f * elapsed);
			float sourceFrame = 0.0f;
			float targetFrame = 0.0f;
			float colorBlend = progress;

			if (encoded >= 400000.0f && encoded < 500000.0f)
			{
				float payload = encoded - 400000.0f;
				targetFrame = mod(payload, 6.0f);
				payload = floor(payload / 6.0f);
				sourceFrame = mod(payload, 6.0f);
			}
			else
			{
				float mode = floor(encoded / 1000000.0f);
				float remainder = encoded - mode * 1000000.0f;
				float splitYCode = floor(remainder / 10000.0f);
				remainder -= splitYCode * 10000.0f;
				float side = floor(remainder / 1000.0f);
				remainder -= side * 1000.0f;
				sourceFrame = floor(remainder / 10.0f);
				targetFrame = remainder - sourceFrame * 10.0f;
				colorBlend = (mode > 0.5f && mode < 1.5f) || (mode > 2.5f && mode < 3.5f) ? progress : (mode > 1.5f ? 1.0f : 0.0f);
			}

			float4 sourceColor = SampleAuthoredFrame(sourceFrame, v.vLocalUV);
			float4 targetColor = SampleAuthoredFrame(targetFrame, v.vLocalUV);
			float4 outputColor = lerp(sourceColor, targetColor, colorBlend);
			return outputColor * Color;
		}
	]]
}

BlendState BlendState {
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}

Effect Up {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
Effect Down {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
Effect Disable {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
Effect Over {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
