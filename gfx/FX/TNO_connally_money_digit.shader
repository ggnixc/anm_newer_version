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
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vLocalUV = float2(v.vTexCoord.x * 10.0f, v.vTexCoord.y);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float PositiveModulo10(float value)
		{
			return value - floor(value / 10.0f) * 10.0f;
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			// Packed frame: place * 1000 + direction * 100 + old * 10 + target.
			// Direction 1 counts up, direction 2 counts down, and 0 is stationary.
			float packed = floor(Offset.x * 10.0f + 0.5f);
			float place = floor(packed / 1000.0f);
			packed -= place * 1000.0f;
			float direction = floor(packed / 100.0f);
			packed -= direction * 100.0f;
			float oldDigit = floor(packed / 10.0f);
			float targetDigit = packed - oldDigit * 10.0f;

			float elapsed = max(0.0f, Time - AnimationTime);
			float duration = 1.95f + (6.0f - place) * 0.10f;
			float normalizedTime = saturate(elapsed / duration);
			float payoutCurve = 0.5f - 0.5f * cos(normalizedTime * 3.14159265f);
			float speedEnvelope = sin(normalizedTime * 3.14159265f);

			float sign = direction < 1.5f ? 1.0f : -1.0f;
			float forwardDelta = PositiveModulo10(targetDigit - oldDigit);
			float backwardDelta = PositiveModulo10(oldDigit - targetDigit);
			float landingDelta = direction < 1.5f ? forwardDelta : backwardDelta;
			// The less significant reels make more complete turns and settle later.
			float fullTurns = 2.0f + (6.0f - place);
			float totalSteps = fullTurns * 10.0f + landingDelta;
			float travel = payoutCurve * totalSteps;

			float reelPosition = targetDigit + v.vLocalUV.y;
			if (direction > 0.5f)
				reelPosition = oldDigit + sign * travel + v.vLocalUV.y;
			float sourceDigit = PositiveModulo10(floor(reelPosition));
			float sourceY = frac(reelPosition);
			float2 sourceUV = float2((sourceDigit + v.vLocalUV.x) / 10.0f, sourceY);
			float4 result = tex2D(MapTexture, sourceUV);

			float flicker = 0.5f + 0.5f * sin(elapsed * 25.0f + place * 1.7f);
			float flash = speedEnvelope * (0.07f + flicker * 0.08f);
			result.rgb = result.rgb * (1.0f + flash) + float3(0.06f, 0.035f, 0.0f) * flash * result.a;
			return result;
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
