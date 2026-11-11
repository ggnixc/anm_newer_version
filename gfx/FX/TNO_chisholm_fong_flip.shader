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
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vLocalUV = float2(v.vTexCoord.x * 8.0f, v.vTexCoord.y);
			Out.vEncodedFrame = floor(Offset.x * 8.0f + 1.5f);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 SampleFront(float group, float2 uv)
		{
			return tex2D(MapTexture, float2((group + uv.x) / 8.0f, uv.y * 0.5f));
		}

		float4 SampleBack(float group, float2 uv)
		{
			return tex2D(MapTexture, float2((group + uv.x) / 8.0f, 0.5f + uv.y * 0.5f));
		}

		float FoldedSourceY(float sourceY, float depth)
		{
			return saturate(sourceY + sin(sourceY * 12.56637061f) * depth * 0.018f);
		}

		float FoldSideShift(float sourceY, float depth)
		{
			return depth * (sin(sourceY * 12.56637061f) * 0.014f + sin(sourceY * 6.28318531f) * 0.007f);
		}

		float FoldLight(float sourceY, float depth)
		{
			return 1.0f - cos(sourceY * 12.56637061f) * depth * 0.11f;
		}

		float PhasedFoldDepth(float distanceFromHinge, float phase, float depth)
		{
			float foldPhase = saturate(phase * 1.5f - distanceFromHinge * 0.5f);
			return sin(foldPhase * 3.14159265f) * (0.55f + depth * 0.45f);
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float code = max(0.0f, v.vEncodedFrame - 1.0f);
			float payDisabled = floor(code / 100.0f);
			code -= payDisabled * 100.0f;
			float fromGroup = floor(code / 10.0f);
			float toGroup = code - fromGroup * 10.0f;
			float direction = toGroup >= fromGroup ? 1.0f : -1.0f;
			float steps = abs(toGroup - fromGroup);
			float elapsed = max(0.0f, Time - AnimationTime);
			float stepDuration = 0.90f;

			if (steps < 0.5f || elapsed >= steps * stepDuration)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);

			float stepIndex = min(steps - 1.0f, floor(elapsed / stepDuration));
			float phase = saturate((elapsed - stepIndex * stepDuration) / stepDuration);
			float currentGroup = fromGroup + direction * stepIndex;
			float nextGroup = currentGroup + direction;
			float2 screenUV = v.vLocalUV;
			if (screenUV.y < 0.5f)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float backgroundGroup = direction > 0.0f ? nextGroup : currentGroup;
			float2 pageUV = float2(screenUV.x, (screenUV.y - 0.5f) * 2.0f);
			float4 outputColor = SampleFront(backgroundGroup, pageUV);
			float2 pagePixel = pageUV * float2(352.0f, 158.0f);
			if (pagePixel.x >= 67.0f && pagePixel.x < 229.0f && pagePixel.y >= 45.0f && pagePixel.y < 67.0f)
			{
				float4 blankColor = SampleBack(backgroundGroup, pageUV);
				float2 labelUV = (pagePixel - float2(67.0f, 45.0f)) / float2(162.0f, 22.0f);
				float writeProgress = direction > 0.0f ? 0.0f : 1.0f - smoothstep(0.05f, 0.65f, phase);
				float strokeOrder = labelUV.x;
				strokeOrder += sin(labelUV.y * 31.0f + labelUV.x * 9.0f) * 0.018f;
				strokeOrder += sin(labelUV.y * 67.0f + 1.4f) * 0.008f;
				float visibility = writeProgress > 0.999f ? 1.0f : 1.0f - smoothstep(writeProgress - 0.018f, writeProgress + 0.018f, strokeOrder);
				float wetInk = 1.0f - smoothstep(0.0f, 0.045f, abs(strokeOrder - writeProgress));
				float inkMask = saturate((abs(outputColor.r - blankColor.r) + abs(outputColor.g - blankColor.g) + abs(outputColor.b - blankColor.b)) * 5.0f);
				outputColor = lerp(blankColor, outputColor, visibility);
				outputColor.rgb += wetInk * inkMask * float3(0.08f, 0.05f, 0.01f);
			}
			if (payDisabled > 0.5f && pagePixel.x >= 271.0f && pagePixel.x < 311.0f && pagePixel.y >= 93.0f && pagePixel.y < 116.0f)
			{
				float brightest = max(outputColor.r, max(outputColor.g, outputColor.b));
				if (brightest > 0.20f)
				{
					float gray = dot(outputColor.rgb, float3(0.299f, 0.587f, 0.114f));
					outputColor.rgb = float3(gray, gray, gray) * 0.58f;
				}
			}
			return outputColor * Color;
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
