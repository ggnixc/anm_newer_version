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
			float packed = max(floor(Offset.x + 0.5f), 0.0f);
			float nextIndex = mod(packed, 1000.0f);
			float previousIndex = floor(packed / 1000.0f);
			float elapsed = clamp(Time - AnimationTime, 0.0f, 0.5f);
			float remaining = (1.0f - sin((4.0f * elapsed - 1.0f) * 1.57079633f)) * 0.5f;

			VS_OUTPUT Out;
			float correction = (previousIndex - nextIndex) * -7.0f * remaining;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.x + correction, v.vPosition.yz, 1.0f));
			Out.vTexCoord = v.vTexCoord;
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
