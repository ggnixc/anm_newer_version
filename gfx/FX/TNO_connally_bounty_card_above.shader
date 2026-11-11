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
	float2 vTexCoord : TEXCOORD0;
	float vProgress : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			float elapsed = max(0.0f, Time - AnimationTime);
			float progress = smoothstep(0.0f, 0.62f, elapsed);
			float2 position = v.vPosition.xy;
			position.y += (1.0f - progress) * 90.0f;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(position, v.vPosition.z, 1.0f));
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
			return tex2D(MapTexture, v.vTexCoord);
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
