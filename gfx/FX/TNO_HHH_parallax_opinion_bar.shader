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
	float animatedOpinion : TEXCOORD1;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			float packed = max(floor(NextOffset.x * 2.0f + 0.5f), 0.0f);

			float nextOpinion = min(mod(packed, 128.0f), 100.0f);
			float oldAndMovement = floor(packed / 128.0f);
			float previousOpinion = min(mod(oldAndMovement, 128.0f), 100.0f);
			float stopPair = floor(oldAndMovement / 128.0f);
			float nextIndex = mod(stopPair, 5.0f) * 15.0f;
			float previousIndex = floor(stopPair / 5.0f) * 15.0f;
			float elapsed = clamp(Time - AnimationTime, 0.0f, 0.5f);
			float remaining = (1.0f - sin((4.0f * elapsed - 1.0f) * 1.57079633f)) * 0.5f;
			float animatedOpinion = nextOpinion + (previousOpinion - nextOpinion) * remaining;

			VS_OUTPUT Out;
			float correction = (previousIndex - nextIndex) * -7.0f * remaining;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.x + correction, v.vPosition.yz, 1.0f));
			Out.vTexCoord = v.vTexCoord;
			Out.animatedOpinion = animatedOpinion;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			float4 fullColor = tex2D(MapTexture, v.vTexCoord);
			float4 emptyColor = tex2D(MapTexture, float2(v.vTexCoord.x + 0.5f, v.vTexCoord.y));
			return v.vTexCoord.x < v.animatedOpinion * 0.005f ? fullColor : emptyColor;
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
