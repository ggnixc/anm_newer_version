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
			Out.vLocalUV = float2(v.vTexCoord.x * 4.0f, v.vTexCoord.y);
			return Out;
		}
	]]
}

PixelShader = {
	MainCode PixelShaderMain
	[[
		float HallHash(float2 value)
		{
			float3 mixed = frac(value.xyx * 0.1031f);
			mixed += dot(mixed, mixed.yzx + 33.33f);
			return frac((mixed.x + mixed.y) * mixed.z);
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			// Packed frame: direction * 100 + old channel * 10 + new channel + 1.
			float packed = max(floor(Offset.x * 4.0f + 0.5f), 0.0f);
			float direction = floor(packed / 100.0f);
			float remainder = packed - direction * 100.0f;
			float oldChannel = floor(remainder / 10.0f);
			float newChannel = remainder - oldChannel * 10.0f;
			float2 uv = v.vLocalUV;
			float elapsed = max(0.0f, Time - AnimationTime);
			float fadeToStatic = smoothstep(0.04f, 0.32f, elapsed);
			float fadeToChannel = smoothstep(0.58f, 0.98f, elapsed);
			float timeCell = floor(Time * 30.0f);
			float2 pixel = floor(uv * float2(318.0f, 227.0f));
			float2 seed = float2(timeCell * 37.0f, timeCell * 17.0f);
			float grainA = HallHash(pixel + seed);
			float grainB = HallHash(pixel.yx + seed.yx + 91.0f);
			float grain = frac(grainA + grainB * 0.61803399f);
			float rowFlash = step(0.94f, HallHash(float2(pixel.y, timeCell * 29.0f)));
			float staticValue = saturate(grain * 0.90f + rowFlash * 0.18f);
			// #E08282
			float staticLevel = 0.22f + staticValue * 0.78f;
			float3 staticRGB = staticLevel * float3(0.87843137f, 0.50980392f, 0.50980392f);

			float4 oldImage = tex2D(MapTexture, float2((oldChannel + uv.x) / 4.0f, uv.y));
			float4 newImage = tex2D(MapTexture, float2((newChannel + uv.x) / 4.0f, uv.y));
			float3 outputRGB = lerp(oldImage.rgb, staticRGB, fadeToStatic);
			outputRGB = lerp(outputRGB, newImage.rgb, fadeToChannel);
			float scanline = 0.87f + 0.13f * sin(uv.y * 227.0f * 3.14159265f);
			float vignette = saturate(1.08f - dot(uv - 0.5f, uv - 0.5f) * 0.85f);

			float crtPulse = 0.96f + 0.04f * sin(Time * 2.15f);
			outputRGB *= scanline * vignette * crtPulse;
			float screenAlpha = max(oldImage.a, newImage.a);
			return float4(outputRGB, screenAlpha) * Color;
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
