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
		float FlexiblePageDistance(float distanceFromHinge, float scale, float turn, float bandCode)
		{
			float band = bandCode - 1.0f;
			float distanceStart = band * 0.25f;
			float distanceEnd = distanceStart + 0.25f;
			float bend = sin(turn * 3.14159265f) * 0.12f;
			float projectedStart = distanceStart * scale - sin(distanceStart * 3.14159265f) * bend;
			float projectedEnd = distanceEnd * scale - sin(distanceEnd * 3.14159265f) * bend;
			float withinBand = (distanceFromHinge - distanceStart) * 4.0f;
			return lerp(projectedStart, projectedEnd, withinBand);
		}

		float FlexiblePageSideBow(float distanceFromHinge, float turn, float bandCode)
		{
			float band = bandCode - 1.0f;
			float distanceStart = band * 0.25f;
			float distanceEnd = distanceStart + 0.25f;
			float bowStrength = sin(turn * 3.14159265f) * 11.0f;
			float bowStart = sin(distanceStart * 3.14159265f) * bowStrength;
			float bowEnd = sin(distanceEnd * 3.14159265f) * bowStrength;
			float withinBand = (distanceFromHinge - distanceStart) * 4.0f;
			return lerp(bowStart, bowEnd, withinBand);
		}

		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float raw = floor(Offset.x * 11.0f + 0.5f);
			float state = floor(raw / 500000.0f);
			float bandCode = 0.0f;
			float role = 0.0f;
			if (state > 11.5f)
			{
				float bandPair = floor((state - 12.0f) / 2.0f);
				bandCode = bandPair + 1.0f;
			}
			else
			{
				float rollDirection = floor(state / 4.0f);
				state -= rollDirection * 4.0f;
				float kind = floor(state / 2.0f);
				role = state - kind * 2.0f;
			}
			float payload = raw - floor(raw / 500000.0f) * 500000.0f;
			float mode = floor(payload / 100000.0f);
			float elapsed = Time - AnimationTime;
			float2 pos = v.vPosition.xy;
			float originalX = pos.x;
			float originalY = pos.y;
			float pageHeight = 158.0f;
			float minimumFlipScale = 0.025f;

			if (role < 0.5f)
			{
				if (mode > 0.5f && mode < 1.5f)
				{
					float turn = smoothstep(0.10f, 0.58f, elapsed);
					float scale = lerp(1.0f, minimumFlipScale, turn);
					float distanceFromHinge = (pageHeight - originalY) / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode) : distanceFromHinge * scale;
					pos.y = pageHeight - projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode);
				}
				else if (mode > 1.5f && mode < 2.5f)
				{
					float turn = smoothstep(0.42f, 0.90f, elapsed);
					float scale = lerp(minimumFlipScale, 1.0f, turn);
					float distanceFromHinge = (pageHeight - originalY) / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode) : distanceFromHinge * scale;
					pos.y = pageHeight - projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode);
				}
				else if (mode > 2.5f && bandCode > 0.5f && bandCode < 1.5f)
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
		float DigitValue(float value, float slot)
		{
			float divisor = slot < 0.5f ? 1000.0f : (slot < 1.5f ? 100.0f : (slot < 2.5f ? 10.0f : 1.0f));
			return floor(value / divisor) - floor(value / (divisor * 10.0f)) * 10.0f;
		}

		float CompactDigitValue(float value, float slot)
		{
			float divisor = slot < 0.5f ? 10.0f : 1.0f;
			return floor(value / divisor) - floor(value / (divisor * 10.0f)) * 10.0f;
		}

		float4 SampleDigit(float digit, float2 uv, float4 tint, float dueDigit)
		{
			// Frame 6 contains native Aldrich cells: 20x32 for the large amount
			// digits and 16x21 for the compact due/rate digits.
			float cellWidth = dueDigit > 0.5f ? 16.0f : 20.0f;
			float cellHeight = dueDigit > 0.5f ? 21.0f : 32.0f;
			float rowTop = dueDigit > 0.5f ? 48.0f : 0.0f;
			float2 sourcePixel = float2(digit * cellWidth + uv.x * cellWidth, rowTop + uv.y * cellHeight);
			float4 glyph = tex2D(MapTexture, float2((6.0f + sourcePixel.x / 352.0f) / 11.0f, sourcePixel.y / 158.0f));
			return float4(tint.rgb, glyph.a * tint.a);
		}

		float4 DrawDigit(float2 pixel, float2 origin, float2 size, float digit, float rollDirection, float progress, float4 tint, float dueDigit)
		{
			if (pixel.x < origin.x || pixel.x >= origin.x + size.x || pixel.y < origin.y || pixel.y >= origin.y + size.y)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float2 uv = (pixel - origin) / size;
			if (rollDirection < 0.5f)
				return SampleDigit(digit, uv, tint, dueDigit);

			float oldDigit = rollDirection < 1.5f ? digit - 1.0f : digit + 1.0f;
			if (oldDigit < 0.0f) oldDigit += 10.0f;
			if (oldDigit > 9.0f) oldDigit -= 10.0f;
			float shiftedY = rollDirection < 1.5f ? uv.y + progress : uv.y - progress;
			if (shiftedY >= 0.0f && shiftedY < 1.0f)
				return SampleDigit(oldDigit, float2(uv.x, shiftedY), tint, dueDigit);
			float newY = rollDirection < 1.5f ? shiftedY - 1.0f : shiftedY + 1.0f;
			return SampleDigit(digit, float2(uv.x, newY), tint, dueDigit);
		}

		float4 AlphaOver(float4 baseColor, float4 overlayColor)
		{
			float outputAlpha = overlayColor.a + baseColor.a * (1.0f - overlayColor.a);
			float3 numerator = overlayColor.rgb * overlayColor.a + baseColor.rgb * baseColor.a * (1.0f - overlayColor.a);
			return float4(numerator / max(outputAlpha, 0.0001f), outputAlpha);
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float raw = floor(Offset.x * 11.0f + 0.5f);
			float packedState = floor(raw / 500000.0f);
			float state = packedState;
			float bandCode = 0.0f;
			float rollDirection = 0.0f;
			float kind = 0.0f;
			float role = 0.0f;
			if (state > 11.5f)
			{
				float bandPair = floor((state - 12.0f) / 2.0f);
				bandCode = bandPair + 1.0f;
				kind = (state - 12.0f) - bandPair * 2.0f;
			}
			else
			{
				rollDirection = floor(state / 4.0f);
				state -= rollDirection * 4.0f;
				kind = floor(state / 2.0f);
				role = state - kind * 2.0f;
			}
			float payload = raw - packedState * 500000.0f;
			float mode = floor(payload / 100000.0f);
			payload -= mode * 100000.0f;
			float interest = floor(payload / 10000.0f);
			float value = payload - interest * 10000.0f;

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
			else if (role < 0.5f && mode > 2.5f)
				alpha = 1.0f;
			else if (role > 0.5f && mode > 2.5f)
				alpha = 1.0f;

			float2 pixel = v.vLocalUV * float2(352.0f, 158.0f);
			float bandMask = 1.0f;
			if (bandCode > 0.5f)
			{
				float band = bandCode - 1.0f;
				if (mode > 2.5f)
				{
					if (bandCode > 1.5f)
						bandMask = 0.0f;
				}
				else
				{
					float bandTop = band * 0.25f;
					float bandBottom = bandTop + 0.25f;
					if (v.vLocalUV.y < bandTop || v.vLocalUV.y >= bandBottom)
						bandMask = 0.0f;
				}
			}
			float progress = smoothstep(0.08f, 0.46f, elapsed);
			float4 outputColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
			if (kind < 0.5f)
			{
				for (int slot = 0; slot < 3; ++slot)
				{
					float slotRollDirection = abs(interest - (float(slot) + 1.0f)) < 0.5f ? rollDirection : 0.0f;

					float4 glyph = DrawDigit(pixel, float2(238.0f + float(slot) * 37.0f, 34.0f), float2(20.0f, 32.0f), DigitValue(value, float(slot) + 1.0f), slotRollDirection, progress, float4(0.42f, 0.95f, 1.0f, 1.0f), 0.0f);
					outputColor = AlphaOver(outputColor, glyph);
				}
			}
			else
			{
				for (int slot = 0; slot < 4; ++slot)
				{
					float4 glyph = DrawDigit(pixel, float2(44.0f + float(slot) * 13.0f, 123.0f), float2(16.0f, 21.0f), DigitValue(value, float(slot)), rollDirection, progress, float4(1.0f, 0.42f, 0.42f, 1.0f), 1.0f);
					outputColor = AlphaOver(outputColor, glyph);
				}
				if (interest >= 10.0f)
				{
					outputColor = AlphaOver(outputColor, DrawDigit(pixel, float2(114.0f, 123.0f), float2(16.0f, 21.0f), CompactDigitValue(interest, 0.0f), 0.0f, progress, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
					outputColor = AlphaOver(outputColor, DrawDigit(pixel, float2(127.0f, 123.0f), float2(16.0f, 21.0f), CompactDigitValue(interest, 1.0f), 0.0f, progress, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
				}
				else
				{
					outputColor = AlphaOver(outputColor, DrawDigit(pixel, float2(114.0f, 123.0f), float2(16.0f, 21.0f), interest, rollDirection, progress, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
				}
				float percentX = interest >= 10.0f ? 140.0f : 127.0f;
				outputColor = AlphaOver(outputColor, DrawDigit(pixel, float2(percentX, 123.0f), float2(16.0f, 21.0f), 10.0f, 0.0f, progress, float4(0.42f, 0.95f, 1.0f, 1.0f), 1.0f));
			}

			outputColor *= Color;
			if (bandCode > 0.5f && mode > 0.5f && mode < 2.5f)
			{
				float turn = mode < 1.5f ? smoothstep(0.10f, 0.58f, elapsed) : smoothstep(0.42f, 0.90f, elapsed);
				float centreFold = sin(v.vLocalUV.y * 3.14159265f) * sin(turn * 3.14159265f);
				outputColor.rgb *= 1.0f - centreFold * 0.18f;
				outputColor.rgb += centreFold * float3(0.02f, 0.055f, 0.06f);
			}
			float hingeShadow = 1.0f - smoothstep(0.0f, 0.10f, v.vLocalUV.y);
			outputColor.rgb *= 1.0f - hingeShadow * 0.36f;
			float hingeRim = 1.0f - smoothstep(0.0f, 0.018f, v.vLocalUV.y);
			outputColor.rgb += hingeRim * float3(0.015f, 0.07f, 0.075f);
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
