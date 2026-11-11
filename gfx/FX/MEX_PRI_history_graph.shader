Includes = {
	"buttonstate.fxh"
	"tno_functions.fxh"
}

PixelShader =
{
	Samplers =
	{
		MapTexture =
		{
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
	float2 vTexCoord : TEXCOORD0;
};

VertexShader =
{
	MainCode VertexShaderGraph
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.f));
			Out.vTexCoord = v.vTexCoord;
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderGraph
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float packed = floor(determineValue(Offset, NextOffset) + 0.5f);
			float endValue = mod(packed, 101.f);
			packed = floor(packed / 101.f);
			float startValue = mod(packed, 101.f);
			packed = floor(packed / 101.f);
			float segmentIndex = mod(packed, 12.f);
			float style = floor(packed / 12.f);

			float2 canvasSize = float2(34.f, 145.f);
			float localX = frac(v.vTexCoord.x * 2.f);
			float2 currentPosition = float2(localX * canvasSize.x, v.vTexCoord.y * canvasSize.y);
			float top = 3.f;
			float graphHeight = 139.f;
			float2 startPoint = float2(-1.f, top + (100.f - startValue) * graphHeight / 100.f);
			float2 endPoint = float2(35.f, top + (100.f - endValue) * graphHeight / 100.f);

			float2 lineVector = endPoint - startPoint;
			float2 direction = normalize(lineVector);
			float2 perpendicular = float2(direction.y, -direction.x);
			float distanceFromLine = abs(dot(perpendicular, startPoint - currentPosition));

			float elapsed = Time - AnimationTime;
			float drawHead = saturate(elapsed / 0.65f) * 11.f;
			float reveal = saturate(drawHead - segmentIndex);
			reveal = reveal * reveal * (3.f - 2.f * reveal);
			float revealX = reveal * canvasSize.x;
			float revealMask = (1.f - smoothstep(revealX - 1.25f, revealX + 0.75f, currentPosition.x)) * step(0.0001f, reveal);
			if (reveal > 0.999f)
				revealMask = 1.f;

			float3 lineColor = float3(133.f, 234.f, 142.f) / 255.f;
			if (style > 0.5f && style < 1.5f)
				lineColor = float3(220.f, 218.f, 80.f) / 255.f;
			else if (style > 1.5f)
				lineColor = float3(156.f, 16.f, 25.f) / 255.f;

			float antialiasWidth = clamp(fwidth(distanceFromLine), 0.55f, 1.f);
			float lineAlpha = 1.f - smoothstep(1.55f, 1.55f + antialiasWidth, distanceFromLine);
			float headGlow = saturate(1.f - abs(currentPosition.x - revealX) / 5.f) * step(reveal, 0.999f);
			lineColor = lerp(lineColor, float3(1.f, 1.f, 0.88f), headGlow * 0.45f);

			return float4(lineColor, lineAlpha * revealMask);
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
	VertexShader = "VertexShaderGraph"
	PixelShader = "PixelShaderGraph"
}

Effect Down
{
	VertexShader = "VertexShaderGraph"
	PixelShader = "PixelShaderGraph"
}

Effect Disable
{
	VertexShader = "VertexShaderGraph"
	PixelShader = "PixelShaderGraph"
}

Effect Over
{
	VertexShader = "VertexShaderGraph"
	PixelShader = "PixelShaderGraph"
}
