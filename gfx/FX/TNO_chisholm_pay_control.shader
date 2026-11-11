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
			MagFilter = "Nearest"
			MinFilter = "Nearest"
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
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vTexCoord = v.vTexCoord;
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode InvisiblePixelShader
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			return float4(0.0f, 0.0f, 0.0f, 0.001f);
		}
	]]
}

PixelShader =
{
	MainCode DisabledPixelShader
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float4 source = tex2D(MapTexture, v.vTexCoord);
			float gray = dot(source.rgb, float3(0.299f, 0.587f, 0.114f));
			float alpha = max(source.a, 0.001f);
			return float4(float3(gray, gray, gray) * 0.58f, alpha) * Color;
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
	PixelShader = "InvisiblePixelShader"
}

Effect Down
{
	VertexShader = "VertexShaderMain"
	PixelShader = "InvisiblePixelShader"
}

Effect Disable
{
	VertexShader = "VertexShaderMain"
	PixelShader = "DisabledPixelShader"
}

Effect Over
{
	VertexShader = "VertexShaderMain"
	PixelShader = "InvisiblePixelShader"
}
