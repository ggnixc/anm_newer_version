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
	float2 vLocalPixel : TEXCOORD0;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float progress = smoothstep(0.0f, 0.62f, max(0.0f, Time - AnimationTime));
			float2 position = v.vPosition.xy;
			position.y -= (1.0f - progress) * 90.0f;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.0f));
			Out.vLocalPixel = float2(v.vTexCoord.x * 10.0f * 204.0f, v.vTexCoord.y * 24.0f);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float DigitAt(float value, float place)
		{
			return floor(value / place) - floor(value / (place * 10.0f)) * 10.0f;
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float value = min(9999999.0f, max(0.0f, floor(Offset.x * 10.0f + 0.5f)));
			float counterX = v.vLocalPixel.x;
			if (counterX < 0.0f || counterX >= 112.0f)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float slot = floor(counterX / 16.0f);
			float digitCount = 1.0f;
			if (value >= 1000000.0f) digitCount = 7.0f;
			else if (value >= 100000.0f) digitCount = 6.0f;
			else if (value >= 10000.0f) digitCount = 5.0f;
			else if (value >= 1000.0f) digitCount = 4.0f;
			else if (value >= 100.0f) digitCount = 3.0f;
			else if (value >= 10.0f) digitCount = 2.0f;
			if (slot >= digitCount)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);
			float place = pow(10.0f, digitCount - slot - 1.0f);
			float digit = DigitAt(value, place);
			float sourceX = digit * 16.0f + frac(counterX / 16.0f) * 16.0f;
			return tex2D(MapTexture, float2(sourceX / 2040.0f, v.vLocalPixel.y / 24.0f));
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

