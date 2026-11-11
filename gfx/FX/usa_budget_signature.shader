Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
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
			MipMapLodBias = -0.8
		}
		MaskTexture =
		{
			Index = 1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture =
		{
			Index = 2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		MaskTexture2 =
		{
			Index = 3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture2 =
		{
			Index = 4
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		MaskingTexture =
		{
			Index = 5
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
	float4  vPosition : PDX_POSITION;
	float2  vTexCoord : TEXCOORD0;
};

VertexShader =
{
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v )
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
	MainCode PixelShaderTransparent
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			return float4(0.f, 0.f, 0.f, 0.f);
		}
	]]

	MainCode PixelShaderOpaque
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			return float4(0.467f, 0.769f, 0.757f, tex2D(MapTexture, v.vTexCoord).a * 0.5f);
		}
	]]

	MainCode PixelShaderAnimated
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float vTime = (Time - AnimationTime);
			float vFactor = 2.f;
			float vEnd = (3.141592f / (vFactor * 2.f));
			bool HasSignedBudget = (Offset.x + 1.f) == 2;
			if(HasSignedBudget && (v.vTexCoord.x <= sin(vTime * vFactor) || vTime > vEnd)){
				return float4(0.467f, 0.769f, 0.757f, tex2D(MapTexture, v.vTexCoord).a);
			}
			else {
				return float4(0.f, 0.f, 0.f, 0.f);
			}
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
	PixelShader = "PixelShaderAnimated"
}

Effect Down
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderOpaque"
}

Effect Disable
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderTransparent"
}

Effect Over
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderOpaque"
}