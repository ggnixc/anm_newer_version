Includes = {
}

PixelShader =
{
	Samplers =
	{
		TextureOne =
		{
			Index = 0
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		TextureTwo =
		{
			Index = 1
			MagFilter = "Point"
			MinFilter = "Point"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
	}
}


VertexStruct VS_INPUT
{
    float4 vPosition  : POSITION;
    float2 vTexCoord  : TEXCOORD0;
};

VertexStruct VS_OUTPUT
{
    float4  vPosition : PDX_POSITION;
    float2  vLineCoord : TEXCOORD0;
    float   vStyle : TEXCOORD1;
};


ConstantBuffer( 0, 0 )
{
	float4x4 WorldViewProjectionMatrix; 
	float4 vFirstColor;
	float4 vSecondColor;
	float CurrentState;
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v ) {
			VS_OUTPUT Out;

			// Packed frame layout:
			// style * 32768 + diagonal * 16384 + x_length * 64 + y_length.
			// Length fields are in ten-pixel units. The GUI anchors this one-pixel
			// resource at the connection's upper-left bound; this shader replaces
			// that point with a narrow quad running between the actual endpoints.
			float packed = floor(CurrentState * 1048576.f + 0.5f);
			float style = floor(packed / 32768.f);
			float geometry = mod(packed, 32768.f);
			float diagonal = floor(geometry / 16384.f);
			geometry = mod(geometry, 16384.f);
			float xDiff = floor(geometry / 64.f) * 10.f;
			float yDiff = mod(geometry, 64.f) * 10.f;

			// GUI Y increases down-screen, while local shader Y displacement uses
			// the opposite sign (the same convention as the traversal shader).
			float2 lineStart = float2(0.f, 0.f);
			float2 lineEnd = float2(xDiff, -yDiff);
			if (diagonal > 0.5f) {
				lineStart = float2(xDiff, 0.f);
				lineEnd = float2(0.f, -yDiff);
			}

			float2 lineVector = lineEnd - lineStart;
			float lineLength = max(length(lineVector), 1.f);
			float2 lineDirection = lineVector / lineLength;
			float2 perpendicular = float2(-lineDirection.y, lineDirection.x);
			// Five pixels per side contains the widest bold style and its shadow.
			float across = (v.vTexCoord.y * 2.f - 1.f) * 5.f;
			float along = v.vTexCoord.x;
			float2 localPosition = lerp(lineStart, lineEnd, along) + perpendicular * across;

			Out.vPosition = mul(WorldViewProjectionMatrix, float4(localPosition, v.vPosition.z, 1.f));
			Out.vLineCoord = float2(along * lineLength, across);
			Out.vStyle = style;
		
			return Out;
		}
		
	]]
}

PixelShader =
{
	MainCode PixelColor
	[[
		
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			if( v.vLineCoord.x <= CurrentState )
				return vFirstColor;
			else
				return vSecondColor;
		}
	]]

	MainCode PixelTexture
	[[
		
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float style = floor(v.vStyle + 0.5f);

			float3 lineColor = float3(0.349f, 0.780f, 0.760f);
			float lineAlpha = 0.6f;
			float lineWidth = 2.5f;
			float arrowBias = 0.5f;

			if (style == 1.f || style == 17.f || style == 18.f) {
				lineColor = float3(0.086f, 0.729f, 0.129f);
				lineAlpha = 0.8f;
			}
			else if (style == 2.f) {
				lineColor = float3(0.698f, 0.788f, 0.760f);
				lineAlpha = 1.f;
				lineWidth = 3.5f;
			}
			else if (style == 3.f) {
				lineColor = float3(0.698f, 0.788f, 0.760f);
			}
			else if (style >= 4.f && style <= 9.f) {
				lineColor = float3(0.878f, 0.509f, 0.509f);
				if (style <= 6.f) {
					lineAlpha = 1.f;
					lineWidth = 3.5f;
				}
				if (style == 4.f || style == 7.f) arrowBias = 1.f;
				if (style == 5.f || style == 8.f) arrowBias = 0.f;
			}
			else if (style >= 10.f && style <= 15.f) {
				lineColor = float3(0.588f, 0.451f, 0.318f);
				if (style == 14.f || style == 15.f) {
					lineColor = float3(0.698f, 0.553f, 0.420f);
				}
				// Preserve the old arrow_bold_2 resource's red tint.
				if (style == 11.f) lineColor = float3(0.878f, 0.509f, 0.509f);
				if (style <= 12.f) {
					lineAlpha = 1.f;
					lineWidth = 3.5f;
				}
				if (style == 10.f || style == 13.f) arrowBias = 1.f;
				if (style == 11.f || style == 14.f) arrowBias = 0.f;
			}
			else if (style == 16.f) {
				lineAlpha = 1.f;
				lineWidth = 3.5f;
			}
			float gap = 10.f;
			float dist = abs(v.vLineCoord.y);

			float4 toRet = float4(lineColor, 1.f);
			float pointDist = v.vLineCoord.x + (arrowBias - 0.5f) * 2.5f * dist;
			float modVal = mod(pointDist, gap);

			float gapSize = gap / 2.f;

			float theMin = max(modVal, gapSize - modVal);
			float sat = saturate(theMin / gapSize);
			sat = pow(sat, 10);
			toRet = float4(toRet.r * sat, toRet.g * sat, toRet.b * sat, 1);
	

            float intensity = saturate((lineWidth - dist) / 1.4f);
            float shadowIntensity = saturate((lineWidth + 1.5f - dist) / 1.4f);

            toRet.a *= intensity;

            float4 black = float4(0, 0, 0, 1);
			black.a *= shadowIntensity;
			
			float3 mixed = toRet.rgb * toRet.a + black.rgb * (1 - toRet.a) * black.a;
			return float4(mixed.r, mixed.g, mixed.b, lineAlpha * (toRet.a + (1 - toRet.a) * black.a));
		}
	]]
}


BlendState BlendState
{
	BlendEnable = yes
	SourceBlend = "SRC_ALPHA"
	DestBlend = "INV_SRC_ALPHA"
}


Effect Color
{
	VertexShader = "VertexShader"
	PixelShader = "PixelColor"
}

Effect Texture
{
	VertexShader = "VertexShader"
	PixelShader = "PixelTexture"
}

