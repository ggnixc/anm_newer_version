Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
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
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1));
			Out.vTexCoord = v.vTexCoord;
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderCircle
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float packedValue = determineValue(Offset, NextOffset);
			float startValue = floor(packedValue / 1000.f);
			float endValue = packedValue - (startValue * 1000.f);

			float animationProgress = saturate((Time - AnimationTime) / 0.65f);
			animationProgress = 0.5f - (0.5f * cos(animationProgress * 3.14159265f));
			float currentValue = lerp(startValue, endValue, animationProgress);

			float2 radialPosition = float2(0.25f - v.vTexCoord.x, v.vTexCoord.y - 0.5f);
			float angle = atan2TNO(radialPosition) + 3.14159265f;
			float cutoff = saturate(currentValue / 100.f) * 3.14159265f * 2.f;
			float blend = saturate((angle - cutoff) * 50.f);

			float4 filled = tex2D(MapTexture, v.vTexCoord);
			float4 empty = tex2D(MapTexture, float2(v.vTexCoord.x + 0.5f, v.vTexCoord.y));
			return lerp(filled, empty, blend);
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
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderCircle"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderCircle"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderCircle"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderCircle"
}
