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
	float vEncodedFrame : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.f));
			Out.vLocalUV = float2(v.vTexCoord.x * 2.f, v.vTexCoord.y);
			Out.vEncodedFrame = floor(Offset.x * 2.f + 1.5f);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float code = max(0.f, v.vEncodedFrame - 1.f);
			float flipSteps = floor(code / 1000.f);
			float targetValue = code - flipSteps * 1000.f;
			float delay = flipSteps * 0.42f + 0.08f;
			float progressTime = saturate((Time - AnimationTime - delay) / 0.62f);
			float eased = progressTime * progressTime * (3.f - 2.f * progressTime);
			float fillPoint = saturate(targetValue / 100.f) * eased;

			if (v.vLocalUV.x > fillPoint)
				return float4(0.f, 0.f, 0.f, 0.f);

			float4 color = tex2D(MapTexture, float2(v.vLocalUV.x * 0.5f, v.vLocalUV.y)) * Color;
			float leadingEdge = 1.f - saturate((fillPoint - v.vLocalUV.x) / 0.045f);
			color.rgb += leadingEdge * float3(0.18f, 0.28f, 0.27f) * (1.f - progressTime * 0.35f);
			return color;
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
