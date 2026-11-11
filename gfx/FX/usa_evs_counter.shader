Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
	"usa_ev_count_number_defs.fxh"
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
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float totalWidth = 186.f;
			
			float value = floor(Offset.x) + 1.f;
			
			float startValue = floor(value/1000.f);
			float endValue = floor(value) - (startValue * 1000.f);
			
			if(value == 1)
			{
				endValue -= 1;
			}
			
			float vTime = (Time - AnimationTime);
			
			float displayValue = endValue;
			if(vTime < 1)
			{
				vTime *= 1.5f;
				float sTime = sin(vTime);
				float difference = endValue - startValue;
				difference *= sTime;
				displayValue = round(startValue + difference);
			}
			float numberWidth = calculateNumberWidth(displayValue);
			
			float widthDifference = 95 - numberWidth;
			widthDifference /= 2.f;
			
			float hundreds = floor(displayValue/100.f);
			float tens = floor(displayValue/10.f) - (hundreds * 10.f);
			float ones = floor(displayValue) - (tens * 10.f) - (hundreds * 100.f);
			
			float startPoint = widthDifference;
			
			if(hundreds > 0)
			{
				if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(hundreds))/totalWidth))
				{
					float positionDifference = getDigitPoint(hundreds) - startPoint;
					positionDifference /= totalWidth;
					return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
				}
				else{
					startPoint += getDigitWidth(hundreds);
					startPoint += 3;
				}
			}
			if(tens > 0 || hundreds > 0)
			{
				if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(tens))/totalWidth))
				{
					float positionDifference = getDigitPoint(tens) - startPoint;
					positionDifference /= totalWidth;
					return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
				}
				else{
					startPoint += getDigitWidth(tens);
					startPoint += 3;
				}
			}
			if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(ones))/totalWidth))
			{
				float positionDifference = getDigitPoint(ones) - startPoint;
				positionDifference /= totalWidth;
				return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
			}
			else{
				return float4(0,0,0,0);
			}
			
			
			return float4(0,0,0,0);
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
					
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif
			
			OutColor *= Color;

			float vTime = 0.9 - saturate( (Time - AnimationTime) * 16 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb -= ( 0.5 + OutColor.rgb ) * MixColor.rgb;

			return OutColor;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float totalWidth = 186.f;
			
			float value = floor(Offset.x) + 1.f;
			
			float startValue = floor(value/1000.f);
			float endValue = floor(value) - (startValue * 1000.f);
			
			if(value == 1)
			{
				endValue -= 1;
			}
			
			float vTime = (Time - AnimationTime);
			
			float displayValue = endValue;
			if(vTime < 1)
			{
				vTime *= 1.5f;
				float sTime = sin(vTime);
				float difference = endValue - startValue;
				difference *= sTime;
				displayValue = round(startValue + difference);
			}
			float numberWidth = calculateNumberWidth(displayValue);
			
			float widthDifference = 95 - numberWidth;
			widthDifference /= 2.f;
			
			float hundreds = floor(displayValue/100.f);
			float tens = floor(displayValue/10.f) - (hundreds * 10.f);
			float ones = floor(displayValue) - (tens * 10.f) - (hundreds * 100.f);
			
			float startPoint = widthDifference;
			
			if(hundreds > 0)
			{
				if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(hundreds))/totalWidth))
				{
					float positionDifference = getDigitPoint(hundreds) - startPoint;
					positionDifference /= totalWidth;
					return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
				}
				else{
					startPoint += getDigitWidth(hundreds);
					startPoint += 3;
				}
			}
			if(tens > 0 || hundreds > 0)
			{
				if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(tens))/totalWidth))
				{
					float positionDifference = getDigitPoint(tens) - startPoint;
					positionDifference /= totalWidth;
					return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
				}
				else{
					startPoint += getDigitWidth(tens);
					startPoint += 3;
				}
			}
			if(v.vTexCoord.x > (startPoint/totalWidth) && v.vTexCoord.x < ((startPoint + getDigitWidth(ones))/totalWidth))
			{
				float positionDifference = getDigitPoint(ones) - startPoint;
				positionDifference /= totalWidth;
				return tex2D( MapTexture, float2(v.vTexCoord.x + positionDifference, v.vTexCoord.y) );
			}
			else{
				return float4(0,0,0,0);
			}
			
			
			return float4(0,0,0,0);
		}	
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
				
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.vAnimatedTexCoord, MaskTexture, AnimatedTexture, MaskTexture2, AnimatedTexture2);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif

			OutColor *= Color;
			
			float vTime = 0.9 - saturate( (Time - AnimationTime) * 4 );
			vTime *= vTime;
			vTime = 0.9*0.9 - vTime;
		    float4 MixColor = float4( 0.15, 0.15, 0.15, 0 ) * vTime;
		    OutColor.rgb += ( 0.5 + OutColor.rgb ) * MixColor.rgb;
			
			return OutColor;
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

