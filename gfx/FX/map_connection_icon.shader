Includes = {
	"buttonstate.fxh"
}

PixelShader =
{
	Samplers =
	{
	}
}

VertexStruct VS_OUTPUT
{
	float4 vPosition : PDX_POSITION;
	float2 vTexCoord : TEXCOORD0;
};

VertexShader =
{
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.f));
			// The source texture has two identical transparent frames. Folding
			// the horizontal UV recovers a stable 0..1 coordinate inside either.
			Out.vTexCoord = float2(frac(v.vTexCoord.x * 2.f), v.vTexCoord.y);
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderMain
	[[
		float BucketSize(float difference)
		{
			float result = 32.f;
			if (difference > 3.f) result = 64.f;
			if (difference > 6.f) result = 128.f;
			if (difference > 12.f) result = 256.f;
			if (difference > 25.f) result = 512.f;
			if (difference > 51.f) result = 1024.f;
			if (difference > 102.f) result = 2048.f;
			if (difference > 204.f) result = 4096.f;
			return result;
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float frameDifference = max(abs(NextOffset.x - Offset.x), 0.000001f);
			float packed = floor(max(Offset.x, NextOffset.x) / frameDifference + 0.5f);
			float style = floor(packed / 32768.f);
			float geometry = mod(packed, 32768.f);
			float diagonal = floor(geometry / 16384.f);
			geometry = mod(geometry, 16384.f);
			float xDiff = floor(geometry / 64.f);
			float yDiff = mod(geometry, 64.f);
			float2 canvasSize = float2(BucketSize(xDiff), BucketSize(yDiff));

			float3 lineColor = float3(0.349f, 0.780f, 0.760f);
			float lineAlpha = 0.6f;
			float lineWidth = 2.5f;
			float arrowBias = 0.5f;

			if (style == 1.f || style == 17.f || style == 18.f) {
				lineColor = float3(0.086f, 0.729f, 0.129f);
				lineAlpha = 0.8f;
			}
			else if (style == 2.f) {
				lineColor = float3(0.698f, 0.788f, 0.760f);
				lineAlpha = 1.f;
				lineWidth = 3.5f;
			}
			else if (style == 3.f) {
				lineColor = float3(0.698f, 0.788f, 0.760f);
			}
			else if (style >= 4.f && style <= 9.f) {
				lineColor = float3(0.878f, 0.509f, 0.509f);
				if (style <= 6.f) {
					lineAlpha = 1.f;
					lineWidth = 3.5f;
				}
				if (style == 4.f || style == 7.f) arrowBias = 1.f;
				if (style == 5.f || style == 8.f) arrowBias = 0.f;
			}
			else if (style >= 10.f && style <= 15.f) {
				lineColor = float3(0.588f, 0.451f, 0.318f);
				if (style == 14.f || style == 15.f)
					lineColor = float3(0.698f, 0.553f, 0.420f);
				if (style == 11.f) lineColor = float3(0.878f, 0.509f, 0.509f);
				if (style <= 12.f) {
					lineAlpha = 1.f;
					lineWidth = 3.5f;
				}
				if (style == 10.f || style == 13.f) arrowBias = 1.f;
				if (style == 11.f || style == 14.f) arrowBias = 0.f;
			}
			else if (style == 16.f) {
				lineAlpha = 1.f;
				lineWidth = 3.5f;
			}

			float2 p1 = float2(0.f, 0.f);
			float2 p2 = float2(xDiff * 10.f, yDiff * 10.f);
			if (diagonal > 0.5f) {
				p1 = float2(xDiff * 10.f, 0.f);
				p2 = float2(0.f, yDiff * 10.f);
			}

			float2 currentP = float2(
				canvasSize.x * v.vTexCoord.x,
				canvasSize.y - canvasSize.y * v.vTexCoord.y
			);
			if (xDiff < 1.f) lineWidth *= 1.75f;
			if (yDiff < 1.f) lineWidth *= 1.5f;

			float2 lineVector = p2 - p1;
			float lineLength = max(length(lineVector), 1.f);
			float2 lineDirection = lineVector / lineLength;
			float2 perpendicular = float2(lineDirection.y, -lineDirection.x);
			float distanceFromLine = abs(dot(perpendicular, p1 - currentP));

			if (currentP.y > max(p1.y, p2.y) || currentP.y < min(p1.y, p2.y))
				distanceFromLine = max(distanceFromLine, min(abs(p1.y - currentP.y), abs(p2.y - currentP.y)));
			if (currentP.x > max(p1.x, p2.x) || currentP.x < min(p1.x, p2.x))
				distanceFromLine = max(distanceFromLine, min(abs(p1.x - currentP.x), abs(p2.x - currentP.x)));

			float4 outputColor = float4(lineColor, 1.f);
			float pointDistance = distance(p1, currentP) + (arrowBias - 0.5f) * 2.5f * distanceFromLine;
			float gap = 10.f;
			float gapSize = gap / 2.f;
			float pattern = saturate(max(mod(pointDistance, gap), gapSize - mod(pointDistance, gap)) / gapSize);
			pattern = pow(pattern, 10.f);
			outputColor.rgb *= pattern;

			if (style == 17.f || style == 18.f) {
				float elapsed = Time - AnimationTime;
				float duration = 1.25f;
				if (elapsed >= 0.f && elapsed < duration) {
					float alongLine = dot(currentP - p1, lineDirection);
					if (style == 18.f) alongLine = lineLength - alongLine;
					float streakWidth = 42.f;
					float progress = saturate(elapsed / duration);
					float streakCenter = progress * (lineLength + streakWidth * 2.f) - streakWidth;
					float pulse = saturate(1.f - abs(alongLine - streakCenter) / streakWidth);
					pulse *= pulse;
					outputColor.rgb = lerp(outputColor.rgb, float3(0.86f, 1.f, 0.88f), pulse);
				}
			}

			float intensity = saturate((lineWidth - distanceFromLine) / 1.4f);
			float shadowIntensity = saturate((lineWidth + 1.5f - distanceFromLine) / 1.4f);
			outputColor.a *= intensity;
			float finalAlpha = lineAlpha * (outputColor.a + (1.f - outputColor.a) * shadowIntensity);
			return float4(outputColor.rgb, finalAlpha);
		}
	]]
}

BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
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
