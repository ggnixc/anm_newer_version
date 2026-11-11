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
	float vFrame : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderHoverOut
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float progress = 1.f - saturate((Time - AnimationTime) * 7.f);
			progress = progress * progress * (3.f - 2.f * progress);
			float2 centre = float2(100.f, 25.f);
			float scale = 1.f + progress * 0.08f;
			float2 position = (v.vPosition.xy - centre) * scale + centre;
			position.y -= progress * 2.f;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.f));
			Out.vLocalUV = float2(v.vTexCoord.x * 6.f, v.vTexCoord.y);
			Out.vFrame = floor(Offset.x * 6.f + 0.5f) + progress * 0.f;
			return Out;
		}
	]]

	MainCode VertexShaderHoverIn
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float progress = saturate((Time - AnimationTime) * 7.f);
			progress = progress * progress * (3.f - 2.f * progress);
			float2 centre = float2(100.f, 25.f);
			float scale = 1.f + progress * 0.08f;
			float2 position = (v.vPosition.xy - centre) * scale + centre;
			position.y -= progress * 2.f;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.f));
			Out.vLocalUV = float2(v.vTexCoord.x * 6.f, v.vTexCoord.y);
			Out.vFrame = floor(Offset.x * 6.f + 0.5f) + progress * 0.f;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderHoverOut
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float progress = 1.f - saturate((Time - AnimationTime) * 7.f);
			progress = progress * progress * (3.f - 2.f * progress);
			float2 atlasUV = float2((v.vFrame + v.vLocalUV.x) / 6.f, v.vLocalUV.y);
			float4 color = tex2D(MapTexture, atlasUV) * Color;
			color.a *= progress;
			return color;
		}
	]]

	MainCode PixelShaderHoverIn
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float progress = saturate((Time - AnimationTime) * 7.f);
			progress = progress * progress * (3.f - 2.f * progress);
			float2 atlasUV = float2((v.vFrame + v.vLocalUV.x) / 6.f, v.vLocalUV.y);
			float4 color = tex2D(MapTexture, atlasUV) * Color;
			color.a *= progress;
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
	VertexShader = "VertexShaderHoverOut"
	PixelShader = "PixelShaderHoverOut"
}

Effect Down
{
	VertexShader = "VertexShaderHoverIn"
	PixelShader = "PixelShaderHoverIn"
}

Effect Disable
{
	VertexShader = "VertexShaderHoverOut"
	PixelShader = "PixelShaderHoverOut"
}

Effect Over
{
	VertexShader = "VertexShaderHoverIn"
	PixelShader = "PixelShaderHoverIn"
}
