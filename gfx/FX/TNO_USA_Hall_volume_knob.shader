Includes = {
	"buttonstate.fxh"
}

PixelShader = {
	Samplers = {
		MapTexture = {
			Index = 0
			MagFilter = "Nearest"
			MinFilter = "Nearest"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
	}
}

VertexStruct VS_OUTPUT {
	float4 vPosition : PDX_POSITION;
	float2 vLocalUV : TEXCOORD0;
};

VertexShader = {
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vLocalUV = v.vTexCoord;
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			// Packed frame: direction * 100 + old level * 10 + new level + 1.
			float packed = max(floor(Offset.x + 0.5f), 0.0f);
			float direction = floor(packed / 100.0f);
			float remainder = packed - direction * 100.0f;
			float oldValue = floor(remainder / 10.0f);
			float newValue = remainder - oldValue * 10.0f;
			float elapsed = Time - AnimationTime;
			float progress = smoothstep(0.0f, 0.20f, elapsed);

			float step = 0.78539816339f;
			float angle = oldValue * step;
			if (direction > 0.5f && direction < 1.5f) angle += step * progress;
			if (direction > 1.5f) angle -= step * progress;
			if (elapsed >= 0.20f) angle = newValue * step;

			float sine = sin(-angle);
			float cosine = cos(-angle);
			float2 centered = v.vLocalUV - 0.5f;
			float2 sourceUV = float2(
				centered.x * cosine - centered.y * sine,
				centered.x * sine + centered.y * cosine
			) + 0.5f;
			if (sourceUV.x < 0.0f || sourceUV.x > 1.0f || sourceUV.y < 0.0f || sourceUV.y > 1.0f)
				return float4(0.0f, 0.0f, 0.0f, 0.0f);

			float4 outputColor = tex2D(MapTexture, sourceUV);
			float backingAlpha = 1.0f - smoothstep(0.42f, 0.49f, length(centered));
			float4 backing = float4(0.0f, 0.0f, 0.0f, backingAlpha);
			outputColor = outputColor + backing * (1.0f - outputColor.a);
			return outputColor * Color;
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
