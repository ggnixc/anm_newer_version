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
			if( v.vTexCoord0.x <= CurrentState / 2.f )
				return vFirstColor;
			else
				return vSecondColor;
		}
		
	]]

	MainCode PixelTexture
	[[
		
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			// Normalized height of column (0 to 1)
			float height = CurrentState / 10.f;

			// Original texture coordinates
			float2 uv = v.vTexCoord0.xy;

			// Prevent divide-by-zero
			float safeHeight = max(height, 0.0001f);

			// Cutoff point (hide everything below this)
			float cutoff = 1.f - height;

			// Remap Y so visible part stays anchored at bottom
			float remappedY = (uv.y - cutoff) / safeHeight;

			// Build remapped coordinate
			float2 remappedUV = float2(uv.x, remappedY);

			// Mask: 0 below cutoff, 1 above cutoff, smooth edge
			float mask = saturate((uv.y - cutoff) / 0.002f);

			// Sample textures
			float4 col1 = tex2D(TextureOne, remappedUV);
			float4 col2 = tex2D(TextureTwo, remappedUV);

			// Blend same as your original shader
			return col1 * (1.f - mask) + col2 * mask;
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
