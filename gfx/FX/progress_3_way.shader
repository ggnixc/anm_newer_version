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
			float value = floor(CurrentState * 1000000.f);
			float firstPoint = floor(value/1000.f);
			float secondPoint = value - (firstPoint*1000.f);
			float4 firstTex = tex2D( TextureOne, float2(v.vTexCoord0.x, v.vTexCoord0.y));
			
			float4 firstColour = tex2D( TextureOne, float2(0.25f, v.vTexCoord0.y));
			float4 secondColour = tex2D( TextureOne, float2(0.5f, v.vTexCoord0.y));
			float4 thirdColour = tex2D( TextureOne, float2(0.75f, v.vTexCoord0.y));
			
			secondPoint += firstPoint;
			
			firstPoint /= 100.f;
			secondPoint /= 100.f;
			
			if (v.vTexCoord0.x < firstPoint || v.vTexCoord0.x == firstPoint) {
				return firstColour;
			} else if (v.vTexCoord0.x > secondPoint || v.vTexCoord0.x == secondPoint) {
				return secondColour;
			}
			else {
				return thirdColour;
			}
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

