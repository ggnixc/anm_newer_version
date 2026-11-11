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

VertexStruct VS_OUTPUT {
	float4 vPosition : PDX_POSITION;
	float2 vTexCoord : TEXCOORD0;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vTexCoord = v.vTexCoord + Offset;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float2 texel = float2(1.0f / 910.0f, 1.0f / 455.0f);
			float2 blurOffset = texel * 4.0f;
			float alpha = tex2D(MapTexture, v.vTexCoord).a * 0.20f;
			alpha += tex2D(MapTexture, v.vTexCoord + float2(blurOffset.x, 0.0f)).a * 0.12f;
			alpha += tex2D(MapTexture, v.vTexCoord - float2(blurOffset.x, 0.0f)).a * 0.12f;
			alpha += tex2D(MapTexture, v.vTexCoord + float2(0.0f, blurOffset.y)).a * 0.12f;
			alpha += tex2D(MapTexture, v.vTexCoord - float2(0.0f, blurOffset.y)).a * 0.12f;
			alpha += tex2D(MapTexture, v.vTexCoord + blurOffset).a * 0.08f;
			alpha += tex2D(MapTexture, v.vTexCoord - blurOffset).a * 0.08f;
			alpha += tex2D(MapTexture, v.vTexCoord + float2(blurOffset.x, -blurOffset.y)).a * 0.08f;
			alpha += tex2D(MapTexture, v.vTexCoord + float2(-blurOffset.x, blurOffset.y)).a * 0.08f;

			float scanWave = 0.5f + 0.5f * sin((v.vTexCoord.y * 455.0f - Time * 42.0f) * 1.57079633f);
			float scanLine = smoothstep(0.64f, 0.94f, scanWave);
			float pulse = 0.94f + 0.06f * sin(Time * 2.1f);
			float shadowAlpha = alpha * (0.50f + scanLine * 0.30f) * pulse;

			float3 tnoBlue = float3(0.34901961f, 0.78039216f, 0.76078431f);
			float3 shadowColour = tnoBlue * (0.24f + scanLine * 0.26f);

			return float4(shadowColour, shadowAlpha) * Color;
		}
	]]
}

BlendState BlendState {
	BlendEnable = yes
	SourceBlend = "src_alpha"
	DestBlend = "inv_src_alpha"
}

Effect Up {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Down {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Disable {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}

Effect Over {
	VertexShader = "VertexShaderMain"
	PixelShader = "PixelShaderMain"
}
