Includes = {
	"buttonstate.fxh"
}

PixelShader = {
	Samplers = {
		MapTexture = {
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
	float2 vTexCoord : TEXCOORD0;
	float vProgress : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float progress = saturate((Time - AnimationTime) / 0.30f);
			float eased = progress * progress * (3.f - 2.f * progress);
			float scale = lerp(1.60f, 1.f, eased);

			// reticle.dds is 210x210 and the icon is centre-positioned.
			float2 centre = float2(105.f, 105.f);
			float2 position = (v.vPosition.xy - centre) * scale + centre;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.f));
			Out.vTexCoord = v.vTexCoord;
			Out.vProgress = progress;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float4 color = tex2D(MapTexture, v.vTexCoord) * Color;
			// A short fade-in softens the first oversized frame. The reticle then
			// remains fully visible after the one-shot contraction finishes.
			color.a *= smoothstep(0.f, 0.18f, v.vProgress);
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
