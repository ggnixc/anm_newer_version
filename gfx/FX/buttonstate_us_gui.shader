Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
}

PixelShader =
{
	Samplers =
	{
		MapTexture =
		{
			Index = 0
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
			MipMapLodBias = -0.8
		}
		MaskTexture =
		{
			Index = 1
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture =
		{
			Index = 2
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		MaskTexture2 =
		{
			Index = 3
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Clamp"
			AddressV = "Clamp"
		}
		AnimatedTexture2 =
		{
			Index = 4
			MagFilter = "Linear"
			MinFilter = "Linear"
			MipFilter = "None"
			AddressU = "Wrap"
			AddressV = "Wrap"
		}
		#This masking texture is the ACTUAL masking texture. The others are for animation
		MaskingTexture =
		{
			Index = 5
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
	float4  vPosition : PDX_POSITION;
	float2  vTexCoord : TEXCOORD0;
@ifdef ANIMATED
	float4  vAnimatedTexCoord : TEXCOORD1;
@endif
@ifdef MASKING
	float2  vMaskingTexCoord : TEXCOORD2;
@endif
};


VertexShader =
{
	MainCode VertexShader
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
		    VS_OUTPUT Out;
		    Out.vPosition  = mul( WorldViewProjectionMatrix, float4( v.vPosition.xyz, 1 ) );
		
		    Out.vTexCoord = v.vTexCoord;
			
		    return Out;
		}
	]]
}

PixelShader =
{
	MainCode PixelShaderUp
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float noOfFrames = round(1.f/(NextOffset.x - Offset.x));
			float value = round(NextOffset.x * noOfFrames);
			
			float colour = floor(value/100.f);
			float icon = floor(value) - (colour*100.f);
			
			float iconPosition = ((icon-1)*2)/noOfFrames;
			
			float4 OutColour = tex2D( MapTexture, float2(v.vTexCoord.x + iconPosition, v.vTexCoord.y) );
			
			if(colour > 0)
			{
				float4 replaceColour = float4(0,0,0,0);
				if(colour == 1)
				{
					replaceColour = float4(0.8784, 0.5098, 0.5098, 1);
				}
				else if(colour == 2)
				{
					replaceColour = float4(0.1843, 0.5412, 0.5294, 1);
				}
				else{
					replaceColour = float4(0.7647, 0.6902, 0.5686, 1);
				}
				
				float4 black = float4(0,0,0,1);
				float4 white = float4(1,1,1,1);
				
				if(OutColour.r == 0 && OutColour.g == 0 && OutColour.b == 0 && OutColour.a == 1)
				{
					OutColour = replaceColour;
				}
				else if(OutColour.r == 1 && OutColour.g == 1 && OutColour.b == 1 && OutColour.a == 1)
				{
					return float4(0,0,0,0);
				}
			}
			
			return OutColour;
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float noOfFrames = round(1.f/(NextOffset.x - Offset.x));
			float value = round(NextOffset.x * noOfFrames);
			
			float colour = floor(value/100.f);
			float icon = floor(value) - (colour*100.f);
			
			float iconPosition = (((icon-1)*2)+1)/noOfFrames;
			
			float4 OutColour = tex2D( MapTexture, float2(v.vTexCoord.x + iconPosition, v.vTexCoord.y) );
			
			if(colour > 0)
			{
				float4 replaceColour = float4(0,0,0,0);
				if(colour == 1)
				{
					replaceColour = float4(0.8784, 0.5098, 0.5098, 1);
				}
				else if(colour == 2)
				{
					replaceColour = float4(0.1843, 0.5412, 0.5294, 1);
				}
				else{
					replaceColour = float4(0.7647, 0.6902, 0.5686, 1);
				}
				
				if(OutColour.r == 0 && OutColour.g == 0 && OutColour.b == 0 && OutColour.a == 1)
				{
					OutColour = replaceColour;
				}
				else if(OutColour.r == 1 && OutColour.g == 1 && OutColour.b == 1 && OutColour.a == 1)
				{
					return float4(0,0,0,0);
				}
			}
			
			return OutColour;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float noOfFrames = round(1.f/(NextOffset.x - Offset.x));
			float value = round(NextOffset.x * noOfFrames);
			
			float colour = floor(value/100.f);
			float icon = floor(value) - (colour*100.f);
			
			float iconPosition = (((icon-1)*2)+1)/noOfFrames;
			
			float4 OutColour = tex2D( MapTexture, float2(v.vTexCoord.x + iconPosition, v.vTexCoord.y) );
			
			if(colour > 0)
			{
				float4 replaceColour = float4(0,0,0,0);
				if(colour == 1)
				{
					replaceColour = float4(0.8784, 0.5098, 0.5098, 1);
				}
				else if(colour == 2)
				{
					replaceColour = float4(0.1843, 0.5412, 0.5294, 1);
				}
				else{
					replaceColour = float4(0.7647, 0.6902, 0.5686, 1);
				}
				
				if(OutColour.r == 0 && OutColour.g == 0 && OutColour.b == 0 && OutColour.a == 1)
				{
					OutColour = replaceColour;
				}
				else if(OutColour.r == 1 && OutColour.g == 1 && OutColour.b == 1 && OutColour.a == 1)
				{
					return float4(0,0,0,0);
				}
			}
			
			return OutColour;
		}	
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float noOfFrames = round(1.f/(NextOffset.x - Offset.x));
			float value = round(NextOffset.x * noOfFrames);
			
			float colour = floor(value/100.f);
			float icon = floor(value) - (colour*100.f);
			
			float iconPosition = (((icon-1)*2)+1)/noOfFrames;
			
			float4 OutColour = tex2D( MapTexture, float2(v.vTexCoord.x + iconPosition, v.vTexCoord.y) );
			
			if(colour > 0)
			{
				float4 replaceColour = float4(0,0,0,0);
				if(colour == 1)
				{
					replaceColour = float4(0.8784, 0.5098, 0.5098, 1);
				}
				else if(colour == 2)
				{
					replaceColour = float4(0.1843, 0.5412, 0.5294, 1);
				}
				else{
					replaceColour = float4(0.7647, 0.6902, 0.5686, 1);
				}
				
				float4 black = float4(0,0,0,1);
				float4 white = float4(1,1,1,1);
				
				if(OutColour.r == 0 && OutColour.g == 0 && OutColour.b == 0 && OutColour.a == 1)
				{
					OutColour = replaceColour;
				}
				else if(OutColour.r == 1 && OutColour.g == 1 && OutColour.b == 1 && OutColour.a == 1)
				{
					return float4(0,0,0,0);
				}
			}
			
			return OutColour;
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
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUp"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDown"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderOver"
}

