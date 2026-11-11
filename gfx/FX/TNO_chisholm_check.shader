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
		float FlexiblePageDistance(float distanceFromHinge, float scale, float turn, float bandCode, float role)
		{
			float band = bandCode - 1.0f;
			float distanceStart = role < 0.5f ? band * 0.25f : (3.0f - band) * 0.25f;
			float distanceEnd = distanceStart + 0.25f;
			float bend = sin(turn * 3.14159265f) * 0.12f;
			float projectedStart = distanceStart * scale - sin(distanceStart * 3.14159265f) * bend;
			float projectedEnd = distanceEnd * scale - sin(distanceEnd * 3.14159265f) * bend;
			float withinBand = (distanceFromHinge - distanceStart) * 4.0f;
			return lerp(projectedStart, projectedEnd, withinBand);
		}

		float FlexiblePageSideBow(float distanceFromHinge, float turn, float bandCode, float role)
		{
			float band = bandCode - 1.0f;
			float distanceStart = role < 0.5f ? band * 0.25f : (3.0f - band) * 0.25f;
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
			float encoded = floor(Offset.x * 11.0f + 0.5f);
			float payState = floor(encoded / 10000.0f);
			encoded -= payState * 10000.0f;
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
			float minimumFlipScale = 0.025f;


			if (role < 0.5f)
			{
				if (mode > 0.5f && mode < 1.5f)
				{
					float turn = smoothstep(0.10f, 0.58f, elapsed);
					float scale = lerp(1.0f, minimumFlipScale, turn);
					float distanceFromHinge = (pageHeight - originalY) / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode, role) : distanceFromHinge * scale;
					pos.y = pageHeight - projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode, role);
				}
				else if (mode > 1.5f && mode < 2.5f)
				{
					float turn = smoothstep(0.42f, 0.90f, elapsed);
					float scale = lerp(minimumFlipScale, 1.0f, turn);
					float distanceFromHinge = (pageHeight - originalY) / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode, role) : distanceFromHinge * scale;
					pos.y = pageHeight - projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode, role);
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
			else if (role > 2.5f)
			{
				if (mode > 0.5f && mode < 1.5f)
				{
					float turn = smoothstep(0.42f, 0.90f, elapsed);
					float scale = lerp(minimumFlipScale, 1.0f, turn);
					float distanceFromHinge = originalY / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode, role) : distanceFromHinge * scale;
					pos.y = projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode, role);
				}
				else if (mode > 1.5f && mode < 2.5f)
				{
					float turn = smoothstep(0.10f, 0.58f, elapsed);
					float scale = lerp(1.0f, minimumFlipScale, turn);
					float distanceFromHinge = originalY / pageHeight;
					float projectedDistance = bandCode > 0.5f ? FlexiblePageDistance(distanceFromHinge, scale, turn, bandCode, role) : distanceFromHinge * scale;
					pos.y = projectedDistance * pageHeight;
					pos.x += distanceFromHinge * sin(turn * 3.14159265f) * 8.0f;
					if (bandCode > 0.5f) pos.x += FlexiblePageSideBow(distanceFromHinge, turn, bandCode, role);
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
		float4 SampleFrame(float frame, float2 uv)
		{
			return tex2D(MapTexture, float2((frame + uv.x) / 11.0f, uv.y));
		}

		float4 AlphaOver(float4 baseColor, float4 overlayColor)
		{
			float outputAlpha = overlayColor.a + baseColor.a * (1.0f - overlayColor.a);
			float3 numerator = overlayColor.rgb * overlayColor.a + baseColor.rgb * baseColor.a * (1.0f - overlayColor.a);
			return float4(numerator / max(outputAlpha, 0.0001f), outputAlpha);
		}

		float4 SampleLetter(float code, float2 uv, float4 tint)
		{
			if (code < -0.5f)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float row = floor(code / 13.0f);
			float column = code - row * 13.0f;

			float2 sourcePixel = float2(column * 20.0f + 5.0f + uv.x * 10.0f, row * 32.0f + 12.0f + uv.y * 18.0f);

			sourcePixel = floor(sourcePixel) + 0.5f;
			float4 glyph = tex2D(MapTexture, float2((2.0f + sourcePixel.x / 352.0f) / 11.0f, sourcePixel.y / 158.0f));
			return float4(tint.rgb, smoothstep(0.30f, 0.70f, glyph.a) * tint.a);
		}

		float4 DrawLetter(float2 pixel, float2 origin, float2 size, float code, float4 tint)
		{
			if (code < -0.5f || pixel.x < origin.x || pixel.x >= origin.x + size.x || pixel.y < origin.y || pixel.y >= origin.y + size.y)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			return SampleLetter(code, (pixel - origin) / size, tint);
		}


		float LookupByte(float x, float row)
		{
			float2 sourcePixel = float2(x + 0.5f, 105.5f + row);
			float4 data = tex2D(MapTexture, float2((2.0f + sourcePixel.x / 352.0f) / 11.0f, sourcePixel.y / 158.0f));
			return floor(data.a * 255.0f + 0.5f);
		}

		float LookupLength(float row)
		{
			return LookupByte(309.0f, row);
		}

		float LookupLetter(float row, float index)
		{
			return LookupByte(310.0f + index, row) - 2.0f;
		}

		float4 DrawTextRow(float2 pixel, float2 origin, float2 glyphSize, float advance, float lookupRow, float visibleLetters, float4 tint)
		{
			float overlap = max(glyphSize.x - advance, 0.0f);
			if (pixel.x < origin.x || pixel.x >= origin.x + visibleLetters * advance + overlap || pixel.y < origin.y || pixel.y >= origin.y + glyphSize.y)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float index = floor((pixel.x - origin.x) / advance);
			float4 outputColor = float4(0.0f, 0.0f, 0.0f, 0.0f);
			if (index < visibleLetters)
				outputColor = DrawLetter(pixel, float2(origin.x + index * advance, origin.y), glyphSize, LookupLetter(lookupRow, index), tint);
			if (index > 0.5f && index - 1.0f < visibleLetters)
				outputColor = AlphaOver(outputColor, DrawLetter(pixel, float2(origin.x + (index - 1.0f) * advance, origin.y), glyphSize, LookupLetter(lookupRow, index - 1.0f), tint));
			return outputColor;
		}

		float4 DrawGroupLabel(float2 pixel, float2 origin, float group, float writeProgress, float4 tint)
		{
			float labelWidth = 162.0f;
			if (pixel.x < origin.x || pixel.x >= origin.x + labelWidth || pixel.y < origin.y || pixel.y >= origin.y + 22.0f)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);

			float labelFrame = 4.0f + floor(group / 4.0f);
			float labelRow = group - floor(group / 4.0f) * 4.0f;
			float2 sourcePixel = floor(pixel - origin) + 0.5f;
			float4 glyph = tex2D(MapTexture, float2((labelFrame + sourcePixel.x / 352.0f) / 11.0f, (labelRow * 30.0f + sourcePixel.y) / 158.0f));
			float2 labelUV = (pixel - origin) / float2(labelWidth, 22.0f);
			float strokeOrder = labelUV.x;
			strokeOrder += sin(labelUV.y * 31.0f + labelUV.x * 9.0f) * 0.018f;
			strokeOrder += sin(labelUV.y * 67.0f + 1.4f) * 0.008f;
			float visibility = writeProgress > 0.999f ? 1.0f : 1.0f - smoothstep(writeProgress - 0.018f, writeProgress + 0.018f, strokeOrder);
			float wetInk = 1.0f - smoothstep(0.0f, 0.045f, abs(strokeOrder - writeProgress));
			float3 ink = tint.rgb + wetInk * float3(0.08f, 0.05f, 0.01f);
			return float4(ink, glyph.a * visibility * tint.a);
		}

		float4 SampleAtlasRect(float2 pixel, float2 outputOrigin, float2 outputSize, float2 sourceOrigin, float2 sourceSize)
		{
			if (pixel.x < outputOrigin.x || pixel.x >= outputOrigin.x + outputSize.x || pixel.y < outputOrigin.y || pixel.y >= outputOrigin.y + outputSize.y)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float2 uv = (pixel - outputOrigin) / outputSize;
			float2 sourcePixel = sourceOrigin + uv * sourceSize;
			return tex2D(MapTexture, float2((3.0f + sourcePixel.x / 352.0f) / 11.0f, sourcePixel.y / 158.0f));
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float encoded = floor(Offset.x * 11.0f + 0.5f);
			float payState = floor(encoded / 10000.0f);
			encoded -= payState * 10000.0f;
			float bandCode = floor(encoded / 1000.0f);
			float packed = encoded - bandCode * 1000.0f;
			float role = floor(packed / 100.0f);
			packed -= role * 100.0f;
			float mode = floor(packed / 10.0f);
			float group = packed - mode * 10.0f;
			float elapsed = Time - AnimationTime;
			float payDisabled = payState;
			float alpha = 1.0f;

			if (role > 0.5f && role < 1.5f && mode > 0.5f && mode < 2.5f)
				alpha = step(0.90f, elapsed);
			else if (role > 3.5f)
				alpha = 0.0f;
			else if ((role < 0.5f || role > 2.5f) && mode < 0.5f)
				alpha = 0.0f;
			else if (role < 0.5f && mode > 0.5f && mode < 1.5f)
				alpha = 1.0f - smoothstep(0.48f, 0.60f, elapsed);
			else if (role < 0.5f && mode > 1.5f && mode < 2.5f)
				alpha = smoothstep(0.38f, 0.50f, elapsed);
			else if (role > 2.5f && mode > 0.5f && mode < 1.5f)
				alpha = smoothstep(0.38f, 0.50f, elapsed);
			else if (role > 2.5f && mode > 1.5f && mode < 2.5f)
				alpha = 1.0f - smoothstep(0.48f, 0.60f, elapsed);
			else if (role > 2.5f && mode > 2.5f)
				alpha = 0.0f;
			else if (role < 0.5f && mode > 2.5f)
				alpha = 1.0f;
			else if (role > 0.5f && role < 1.5f && mode > 2.5f)
				alpha = 1.0f;

			float2 renderUV = v.vLocalUV;
			float2 pixel = renderUV * float2(352.0f, 158.0f);
			float4 outputColor = SampleFrame(role > 1.5f ? 1.0f : 0.0f, renderUV);
			float bandMask = 1.0f;
			if (bandCode > 0.5f && bandCode < 4.5f)
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

			if (role < 1.5f)
			{
				float4 cyan = float4(0.34f, 0.93f, 0.96f, 1.0f);
				float4 yellow = float4(1.0f, 0.89f, 0.14f, 1.0f);

				float labelWriteProgress = 1.0f;
				if (role < 0.5f && mode > 0.5f && mode < 1.5f)
					labelWriteProgress = 1.0f - smoothstep(0.05f, 0.55f, elapsed);
				else if (role > 0.5f && role < 1.5f && mode > 0.5f && mode < 1.5f)
					labelWriteProgress = smoothstep(0.90f, 1.45f, elapsed);
				else if (mode > 1.5f && mode < 2.5f)
					labelWriteProgress = smoothstep(0.90f, 1.45f, elapsed);

				outputColor = AlphaOver(outputColor, DrawGroupLabel(pixel, float2(67.0f, 45.0f), group, labelWriteProgress, yellow));
				float4 requestArt = SampleAtlasRect(pixel, float2(196.0f, 93.0f), float2(52.0f, 23.0f), float2(0.0f, 0.0f), float2(52.0f, 23.0f));
				float4 payArt = SampleAtlasRect(pixel, float2(271.0f, 93.0f), float2(40.0f, 23.0f), float2(64.0f, 0.0f), float2(40.0f, 23.0f));
				if (payDisabled > 0.5f)
				{
					float gray = dot(payArt.rgb, float3(0.299f, 0.587f, 0.114f));
					payArt.rgb = float3(gray, gray, gray) * 0.58f;
				}
				outputColor = AlphaOver(outputColor, requestArt);
				outputColor = AlphaOver(outputColor, payArt);

			}

			if ((role < 0.5f || role > 2.5f) && mode > 0.5f && mode < 2.5f)
			{
				float turn = 0.0f;
				if ((role < 0.5f && mode < 1.5f) || (role > 2.5f && mode > 1.5f))
					turn = smoothstep(0.10f, 0.58f, elapsed);
				else
					turn = smoothstep(0.42f, 0.90f, elapsed);
				float distanceFromHinge = role < 0.5f ? v.vLocalUV.y : 1.0f - v.vLocalUV.y;
				float centreFold = sin(distanceFromHinge * 3.14159265f) * sin(turn * 3.14159265f);
				outputColor.rgb *= 1.0f - centreFold * 0.18f;
				outputColor.rgb += centreFold * float3(0.02f, 0.055f, 0.06f);
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
