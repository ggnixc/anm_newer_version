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
	float2 vLocalUV : TEXCOORD0;
	float animatedFill : TEXCOORD1;
	float style : TEXCOORD2;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			// Mixed-base frame payload: style base 4, previous fill base 128,
			// target fill base 128. The scripted frame is one-based, while
			// NextOffset exposes the zero-based payload divided by eight.
			float packed = max(floor(NextOffset.x * 8.0f + 0.5f), 0.0f);
			float targetFill = min(mod(packed, 128.0f), 100.0f);
			packed = floor(packed / 128.0f);
			float previousFill = min(mod(packed, 128.0f), 100.0f);
			float style = min(floor(packed / 128.0f), 3.0f);

			float elapsed = clamp((Time - AnimationTime) / 0.75f, 0.0f, 1.0f);
			float progress = elapsed * elapsed * (3.0f - 2.0f * elapsed);

			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vLocalUV = float2(v.vTexCoord.x * 8.0f, v.vTexCoord.y);
			Out.animatedFill = previousFill + (targetFill - previousFill) * progress;
			Out.style = style;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			// Every style occupies two physical atlas frames: full, then empty.
			// Half-texel clamping keeps Linear sampling inside the selected frame.
			float localX = clamp(v.vLocalUV.x, 0.00362319f, 0.99637681f);
			float styleFrame = floor(v.style + 0.5f) * 2.0f;
			float2 fullUV = float2((styleFrame + localX) / 8.0f, v.vLocalUV.y);
			float2 emptyUV = float2((styleFrame + 1.0f + localX) / 8.0f, v.vLocalUV.y);
			float fill = clamp(v.animatedFill * 0.01f, 0.0f, 1.0f);
			float isFilled = v.style < 1.5f
				? (localX < fill ? 1.0f : 0.0f)
				: (localX > 1.0f - fill ? 1.0f : 0.0f);
			float4 fullColor = tex2D(MapTexture, fullUV);
			float4 emptyColor = tex2D(MapTexture, emptyUV);
			return lerp(emptyColor, fullColor, isFilled) * Color;
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
