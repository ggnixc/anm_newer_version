Includes = {
	"buttonstate.fxh"
}

PixelShader =
{
	Samplers =
	{
		RegionTexture =
		{
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
};

VertexShader =
{
	MainCode VertexShaderMain
	[[
		VS_OUTPUT main(const VS_INPUT v)
		{
			VS_OUTPUT Out;
			// GUI-native scale enlarges the 1442x947 lookup to 5768x3788.
			// Keeping geometry unmodified preserves HOI4's top-left anchor.
			Out.vPosition = mul(WorldViewProjectionMatrix, float4(v.vPosition.xyz, 1.0f));
			Out.vTexCoord = v.vTexCoord;
			return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderMain
	[[
		float DecodeRegion(float4 sampleColor)
		{
			if (sampleColor.a < 0.1f)
				return 0.0f;

			float3 c = sampleColor.rgb;

			// Exact source palette:
			// 1 Baja          #9F82FF    6 North West #DEFFC1
			// 2 CDMX          #1151FF    7 South East #BE4FFF
			// 3 Central North #FF0CE2    8 South West #FFB200
			// 4 Gulf          #9EFFB1    9 West       #28FF93
			// 5 North East    #84A1FF   10 Yucatan    #FF517A
			// 11 Guatemala    #00FFFF
			// Broad channel tests tolerate the handful of edge pixels left by
			// the source export without requiring ten distance comparisons.
			if (c.b < 0.2f)
				return 8.0f;
			if (c.r < 0.2f && c.g > 0.8f && c.b > 0.8f)
				return 11.0f;
			if (c.g > 0.85f)
			{
				if (c.r > 0.75f && c.b > 0.65f)
					return 6.0f;
				if (c.r > 0.45f)
					return 4.0f;
				return 9.0f;
			}
			if (c.r > 0.9f)
				return (c.b > 0.7f) ? 3.0f : 10.0f;
			if (c.r < 0.2f)
				return 2.0f;
			if (c.g > 0.58f)
				return 5.0f;
			if (c.r > 0.68f)
				return 7.0f;
			return 1.0f;
		}

		float RegionIsFogged(float mask, float region)
		{
			if (region < 0.5f)
				return 0.0f;
			float divisor = pow(2.0f, region - 1.0f);
			return floor(fmod(mask / divisor, 2.0f));
		}

		float2 FogStatesAt(float2 uv, float oldMask, float newMask)
		{
			float region = DecodeRegion(tex2D(RegionTexture, uv));
			return float2(
				RegionIsFogged(oldMask, region),
				RegionIsFogged(newMask, region)
			);
		}

		float2 FilterFog(float2 uv, float oldMask, float newMask)
		{
			float2 texel = float2(1.0f / 1442.0f, 1.0f / 947.0f);
			float2 fog = FogStatesAt(uv, oldMask, newMask) * 4.0f;

			// The lookup texture is displayed at 4x scale. Several sparse rings
			// create a wide transition without requiring a full 9x9 convolution.
			fog += FogStatesAt(uv + texel * float2( 4.0f,  0.0f), oldMask, newMask) * 2.0f;
			fog += FogStatesAt(uv + texel * float2(-4.0f,  0.0f), oldMask, newMask) * 2.0f;
			fog += FogStatesAt(uv + texel * float2( 0.0f,  4.0f), oldMask, newMask) * 2.0f;
			fog += FogStatesAt(uv + texel * float2( 0.0f, -4.0f), oldMask, newMask) * 2.0f;

			fog += FogStatesAt(uv + texel * float2( 10.0f,  10.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-10.0f,  10.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 10.0f, -10.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-10.0f, -10.0f), oldMask, newMask);

			fog += FogStatesAt(uv + texel * float2( 18.0f,  0.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-18.0f,  0.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 0.0f,  18.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 0.0f, -18.0f), oldMask, newMask);

			// The outer ring reaches 112 displayed map pixels from the nominal
			// border, producing a broad fog bank instead of a visible cutoff.
			fog += FogStatesAt(uv + texel * float2( 28.0f,  0.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-28.0f,  0.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 0.0f,  28.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 0.0f, -28.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 20.0f,  20.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-20.0f,  20.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2( 20.0f, -20.0f), oldMask, newMask);
			fog += FogStatesAt(uv + texel * float2(-20.0f, -20.0f), oldMask, newMask);
			return fog / 28.0f;
		}

		float HashNoise(float2 p)
		{
			return frac(sin(dot(p, float2(127.1f, 311.7f))) * 43758.5453f);
		}

		float ValueNoise(float2 p)
		{
			float2 cell = floor(p);
			float2 f = frac(p);
			f = f * f * (3.0f - 2.0f * f);

			float a = HashNoise(cell);
			float b = HashNoise(cell + float2(1.0f, 0.0f));
			float c = HashNoise(cell + float2(0.0f, 1.0f));
			float d = HashNoise(cell + float2(1.0f, 1.0f));
			return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
		}

		float FractalNoise(float2 p)
		{
			float value = ValueNoise(p) * 0.57f;
			value += ValueNoise(p * 2.03f + 17.7f) * 0.29f;
			value += ValueNoise(p * 4.11f + 41.3f) * 0.14f;
			return value;
		}

		float SmokeNoise(float2 uv)
		{
			// Correct for the wide map so cloud cells remain approximately
			// square, then slowly advect two layers in different directions.
			float2 p = uv * float2(15.23f, 10.0f);
			float t = Time * 0.28f;
			float warp = ValueNoise(p * 0.42f + float2(t * 0.31f, -t * 0.19f));
			float layerA = FractalNoise(p + float2(t, -t * 0.34f) + warp * 2.1f);
			float layerB = FractalNoise(p * 1.73f + float2(-t * 0.47f, t * 0.61f));
			float combined = saturate(layerA * 0.70f + layerB * 0.30f);
			// FBM naturally clusters around 0.5; expand that narrow range so
			// its movement remains visible after alpha blending over the map.
			return smoothstep(0.27f, 0.73f, combined);
		}

		float4 main(VS_OUTPUT v) : PDX_COLOR
		{
			// Two eleven-bit masks fit exactly in one float-backed frame value.
			// packed = oldMask * 2048 + newMask + 1
			// With the default single frame, scripted frame N is exposed as
			// Offset.x = N - 1 (the same contract used by the SACW slider).
			float packed = max(floor(Offset.x + 0.5f), 0.0f);
			float newMask = fmod(packed, 2048.0f);
			float oldMask = floor(packed / 2048.0f);

			float2 filtered = FilterFog(v.vTexCoord, oldMask, newMask);
			float transition = saturate((Time - AnimationTime) / 0.65f);
			transition = transition * transition * (3.0f - 2.0f * transition);
			float fog = lerp(filtered.x, filtered.y, transition);

			float smoke = SmokeNoise(v.vTexCoord);
			float boundary = saturate(4.0f * fog * (1.0f - fog));
			// Noise only disturbs the partially covered boundary. Fully fogged
			// interiors remain opaque enough to perform their gameplay role.
			fog = saturate(fog + (smoke - 0.5f) * boundary * 0.72f);

			float density = 0.62f + smoke * 0.38f;
			float3 smokeColor = lerp(
				float3(0.070f, 0.080f, 0.080f),
				float3(0.285f, 0.310f, 0.300f),
				smoke
			);
			return float4(smokeColor, fog * density * 0.92f) * Color;
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
