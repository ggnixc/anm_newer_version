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
			Out.vLocalUV = float2(v.vTexCoord.x * 11.0f, v.vTexCoord.y);
			Out.vEncodedFrame = floor(Offset.x * 11.0f + 1.5f);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float DigitValue(float value, float slot, float digits)
		{
			float power = digits - slot - 1.0f;
			float divisor = power > 2.5f ? 1000.0f : (power > 1.5f ? 100.0f : (power > 0.5f ? 10.0f : 1.0f));
			return floor(value / divisor) - floor(value / (divisor * 10.0f)) * 10.0f;
		}

		float4 SampleDigit(float digit, float2 uv, float4 tint, float compact)
		{
			float cellWidth = compact > 0.5f ? 16.0f : 20.0f;
			float cellHeight = compact > 0.5f ? 21.0f : 32.0f;
			float rowTop = compact > 0.5f ? 48.0f : 0.0f;
			float2 sourcePixel = float2(digit * cellWidth + uv.x * cellWidth, rowTop + uv.y * cellHeight);
			return float4(tint.rgb, tex2D(MapTexture, float2((6.0f + sourcePixel.x / 352.0f) / 11.0f, sourcePixel.y / 316.0f)).a * tint.a);
		}

		float4 DrawDigit(float2 pagePixel, float2 origin, float2 size, float digit, float4 tint, float compact)
		{
			if (pagePixel.x < origin.x || pagePixel.x >= origin.x + size.x || pagePixel.y < origin.y || pagePixel.y >= origin.y + size.y)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			return SampleDigit(digit, (pagePixel - origin) / size, tint, compact);
		}

		float4 AlphaOver(float4 baseColor, float4 overlayColor)
		{
			float outputAlpha = overlayColor.a + baseColor.a * (1.0f - overlayColor.a);
			float3 numerator = overlayColor.rgb * overlayColor.a + baseColor.rgb * baseColor.a * (1.0f - overlayColor.a);
			return float4(numerator / max(outputAlpha, 0.0001f), outputAlpha);
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

		float4 DrawPageNumbers(float2 pageUV, float kind, float value, float interest)
		{
			float2 pagePixel = pageUV * float2(352.0f, 158.0f);
			float4 outputColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
			if (kind < 0.5f)
			{
				for (int slot = 0; slot < 3; ++slot)
				{
					float4 glyph = DrawDigit(pagePixel, float2(238.0f + float(slot) * 37.0f, 34.0f), float2(20.0f, 32.0f), DigitValue(value, float(slot), 3.0f), float4(0.42f, 0.95f, 1.0f, 1.0f), 0.0f);
					outputColor = AlphaOver(outputColor, glyph);
				}
			}
			else
			{
				for (int slot = 0; slot < 4; ++slot)
				{
					float4 glyph = DrawDigit(pagePixel, float2(44.0f + float(slot) * 13.0f, 123.0f), float2(16.0f, 21.0f), DigitValue(value, float(slot), 4.0f), float4(1.0f, 0.42f, 0.42f, 1.0f), 1.0f);
					outputColor = AlphaOver(outputColor, glyph);
				}
				if (interest >= 10.0f)
				{
					outputColor = AlphaOver(outputColor, DrawDigit(pagePixel, float2(114.0f, 123.0f), float2(16.0f, 21.0f), DigitValue(interest, 0.0f, 2.0f), float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
					outputColor = AlphaOver(outputColor, DrawDigit(pagePixel, float2(127.0f, 123.0f), float2(16.0f, 21.0f), DigitValue(interest, 1.0f, 2.0f), float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
				}
				else
				{
					outputColor = AlphaOver(outputColor, DrawDigit(pagePixel, float2(114.0f, 123.0f), float2(16.0f, 21.0f), interest, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
				}
				float percentX = interest >= 10.0f ? 140.0f : 127.0f;
				outputColor = AlphaOver(outputColor, DrawDigit(pagePixel, float2(percentX, 123.0f), float2(16.0f, 21.0f), 10.0f, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
			}
			return outputColor;
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float code = max(0.0f, v.vEncodedFrame - 1.0f);
			float state = floor(code / 1000000.0f);
			float payload = code - state * 1000000.0f;
			float kind = floor(state / 4.0f);
			float mode = state - kind * 4.0f;
			float interest = floor(payload / 10000.0f);
			float value = payload - interest * 10000.0f;
			float oldAmount = floor(payload / 1000.0f);
			float newAmount = payload - oldAmount * 1000.0f;
			float elapsed = max(0.0f, Time - AnimationTime);
			float duration = 0.90f;

			if (mode < 0.5f || elapsed >= duration)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);

			float direction = mode < 1.5f ? 1.0f : -1.0f;
			float2 screenUV = v.vLocalUV;
			float4 color = float4(0.0f, 0.0f, 0.0f, 0.0f);

			bool onBottom = screenUV.y >= 0.5f;
			float2 bottomUV = float2(screenUV.x, (screenUV.y - 0.5f) * 2.0f);
			if (kind < 0.5f)
			{
				if (onBottom)
					color = DrawPageNumbers(bottomUV, 0.0f, direction > 0.0f ? newAmount : oldAmount, 0.0f);
			}
			else if (kind < 1.5f)
			{
				if (direction < 0.0f && onBottom)
					color = DrawPageNumbers(bottomUV, 1.0f, value, interest);
			}
			else
			{
				if (direction > 0.0f && onBottom)
					color = DrawPageNumbers(bottomUV, 1.0f, value, interest);
			}

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
