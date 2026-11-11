# This is a copy of gng_map_fill.shader except the width of the border effect can be adjusted
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
    float2  vTexCoord0 : TEXCOORD0;
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
		
		VS_OUTPUT main(const VS_INPUT v )
		{
			VS_OUTPUT Out;
		   	Out.vPosition  = mul( WorldViewProjectionMatrix, v.vPosition );
			Out.vTexCoord0  = v.vTexCoord;
			Out.vTexCoord0.y = -Out.vTexCoord0.y;
		
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
			if( v.vTexCoord0.x <= CurrentState )
				return vFirstColor;
			else
				return vSecondColor;
		}
		
	]]

	MainCode PixelTexture
	[[
		
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float4 texColor = tex2D(TextureOne, v.vTexCoord0.xy);

			if (texColor.a == 0) {
				return float4(0, 0, 0, 0);
			}
			
			// The number of possible maps is set with the red chanel of the first color
			float numColors = vFirstColor.r * 1000.f;
			float inputFrame = CurrentState * 10000.f;
			float color = floor(inputFrame / 1000.f) - 1;
			float fullness = saturate( mod(inputFrame, 1000.f) / 100.f);

			// The opacity of the color of the color added over the state assets is
			// set with the aplha chanel of the first color.
			// alpha = 0 --> No RGB scanlines,
			// alpha = 1 --> RGB scanlines only, no color is overlayed.
			float alpha = vFirstColor.a;

			// The width and height of the states must be set with the red and green
			// channels of the second color. If this is not done, the effect
			// that darkens the borders won't work.
			float mapW = vSecondColor.r * 1000.f;
			float mapH = vSecondColor.g * 1000.f;
			
			// The desired edge width is set with the green chanel of the first color
			float edgeWidth = vFirstColor.g * 1000.f;
			bool onEdge =  tex2D(TextureOne, v.vTexCoord0.xy + float2( edgeWidth/mapW,  edgeWidth/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-edgeWidth/mapW, -edgeWidth/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2( edgeWidth/mapW, -edgeWidth/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-edgeWidth/mapW,  edgeWidth/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2( edgeWidth/mapW,  0/mapH)).a         == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-edgeWidth/mapW,  0/mapH)).a         == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(0/mapW,          -edgeWidth/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(0/mapW,           edgeWidth/mapH)).a == 0;
			
			float4 fillColor = tex2D(TextureTwo, float2(color / numColors + v.vTexCoord0.x * mapW / (400 * numColors), v.vTexCoord0.y * mapH / 400));

			// Some king of hard coded exception to handle the 8th color differently?
			/* if (color == 8 && !onEdge) {
				bool onEdgeInner = tex2D(TextureOne, v.vTexCoord0.xy + float2(4/mapW, 4/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-4/mapW, -4/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(4/mapW, -4/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-4/mapW, 4/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(4/mapW, 0/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(-4/mapW, 0/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(0/mapW, -4/mapH)).a == 0
						|| tex2D(TextureOne, v.vTexCoord0.xy + float2(0/mapW, 4/mapH)).a == 0;

				float diag = mod(mapW * v.vTexCoord0.x + mapH * v.vTexCoord0.y + 10000.0f, 8);

				if (diag < 8 && !onEdgeInner) {
					fillColor.rgb *= 1.35f;
				}
			} */

			if (onEdge) {
				fillColor.rgb *= 1.5f;
			} else {
				fillColor.rgb *= (0.5f + fullness * 0.5f);
			}

			float3 displayColor = texColor.rgb * alpha + fillColor.rgb * (1 - alpha);
			return float4(displayColor.r, displayColor.g, displayColor.b, 1.0); 
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

