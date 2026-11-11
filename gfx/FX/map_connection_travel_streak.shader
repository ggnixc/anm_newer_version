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
	float vElapsed : TEXCOORD1;
};


VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;

			// Two-frame sprite convention used by the existing animated progress
			// shaders: NextOffset contains the scripted frame divided by two.
			float packed = floor(NextOffset.x * 2.f + 0.5f);
			float routeOrder = floor(packed / 65536.f);
			float geometry = packed - routeOrder * 65536.f;
			float encodedX = floor(geometry / 128.f);
			float encodedY = geometry - encodedX * 128.f;
			float2 travel = float2(encodedX - 256.f, encodedY - 64.f) * 10.f;
			travel.y *= -1.f;

			float edgeDuration = 0.55f;
			float elapsed = Time - AnimationTime - routeOrder * edgeDuration;
			float progress = saturate(elapsed / edgeDuration);
			progress = progress * progress * (3.f - 2.f * progress);

			// faction_icons are 56px square. noOfFrames=2 preserves the packed
			// frame input but creates a 28x56 quad, so double its x scale. The
			// final moving symbol is approximately 31px square without new art.
			float2 centre = float2(14.f, 28.f);
			float2 symbolScale = float2(1.10f, 0.55f);
			float2 localPosition = (v.vPosition.xy - centre) * symbolScale + centre;
			float2 displacedPosition = localPosition + travel * progress;

			Out.vPosition = mul(WorldViewProjectionMatrix, float4(displacedPosition, v.vPosition.z, 1.f));
			// Convert either engine-selected half-frame back to the complete icon.
			Out.vTexCoord = float2(saturate(v.vTexCoord.x * 2.f), v.vTexCoord.y);
			Out.vElapsed = elapsed;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderUp
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			if (v.vElapsed < 0.f || v.vElapsed > 0.67f)
				return float4(0.f, 0.f, 0.f, 0.f);

			float fade = saturate((0.67f - v.vElapsed) / 0.12f);
			float4 color = tex2D(MapTexture, v.vTexCoord) * Color;
			color.a *= fade;
			return color;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			if (v.vElapsed < 0.f || v.vElapsed > 0.67f)
				return float4(0.f, 0.f, 0.f, 0.f);

			float fade = saturate((0.67f - v.vElapsed) / 0.12f);
			float4 color = tex2D(MapTexture, v.vTexCoord) * Color;
			color.a *= fade;
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
	PixelShader = "PixelShaderUp"
}

Effect Down
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderUp"
}

Effect Disable
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderUp"
}
