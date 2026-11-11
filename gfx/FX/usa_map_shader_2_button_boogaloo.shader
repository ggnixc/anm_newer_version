Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
	"usa_map_colour_defines.fxh"
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
			float input = round(NextOffset.x*53.0f);
			float type = floor(input/1000000.f);
			float stateNumber = floor(input/10000.f) - (type * 100.f);
			
			float stateOffset = ((stateNumber - 1.f)/53.f);
			
			Out.vTexCoord.x += stateOffset;
		
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
			float vTime = Time - AnimationTime;
			
			float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float input = round(NextOffset.x*53.0f);
			float type = floor(input/1000000.f);
			float stateNumber = floor(input/10000.f) - (type * 100.f);
			
			float information = round(abs(input - (stateNumber * 10000.f))) - (type * 1000000.f);
			
			float partB = floor(information/1000.f);
			float partC = floor(information/100.f) - (partB * 10.f);
			float partD = floor(information/10.f) - (partC * 10.f) - (partB * 100.f);
			float partE = floor(information) - (partC * 100.f) - (partD * 10.f) - (partB * 1000.f);
			
			float4 outColour = float4(0,0,0,0);
			
			//Static
			if(type == 0)
			{
				float4 firstColour = getPartyAndColour(partB, partC);
				float4 secondColour = getPartyAndColour(partD, partE);
					
				if(partB == 9)
				{
					firstColour = float4(0,0,0,1);
				}
				if(partD == 9)
				{
					secondColour = float4(0,0,0,1);
				}
				
					
				float4 difference = secondColour - firstColour;
				if(vTime < 1 && (partB > 0 || partC > 0)){
					difference *= vTime;
				}
				outColour = firstColour + difference;
			}
			//Animated
			else{
				//Polls Open
				if(information == 999){
					outColour.rgb = float3(0,0.4,0);
				}
				//Polls Closed
				else if(information == 998){
					outColour.rgb = float3(vTime * 0.4,0.4,0);
					if(vTime > 1)
					{
						outColour.rgb = float3(0.4,0.4,0);
					}
				}
				//Polls partially closed
				else if(information == 997){
					outColour.rgb = float3(vTime * 0.4,0.4,0);
					if(vTime > 1)
					{
						outColour.rgb = float3(0.4,0.4,0);
					}
				}
				else{
					//State Call
					if(partB == 9 && partC == 9)
					{
						outColour = getPartyAndColour(partE, 0);
						//Flash
						if(partD == 0)
						{
							float changePoint = 3.f/60.f;
							if ((vTime > changePoint && vTime <= (changePoint * 2.f)) || (vTime > (changePoint * 3.f) && vTime <= (changePoint * 4.f)) || (vTime > (changePoint * 5.f) && vTime <= (changePoint * 6.f))) {
								outColour = float4(1,1,1,1);
							}
						}
					}
					else{
						float4 previousColour = getPartyAndColour(partB, partC);
						float4 currentColour = getPartyAndColour(partD, partE);
						
						if(partB == 9 && partC == 8)
						{
							previousColour = float4(0.4,0.4,0,1);
						}
						else if(partB == 9 && partC == 7)
						{
							previousColour = float4(0.4,0.4,0,1);
						}
						
						float4 difference = currentColour - previousColour;
						if(vTime < 1){
							difference *= vTime;
						}
						outColour = previousColour + difference;
					}
				}
			}
			
			OutColor.rgb = outColour.rgb;
			if(type == 1 && partD != 9 && partC != 9 && OutColor.a > 0)
			{
				if(vTime > 1 || partB != 9){
					OutColor.a = 0.7f;
				}
				else{
					OutColor.a = 1 - (0.3f * vTime);
				}
			}
			
			float remainder = floor(v.vPosition.y%3);
			
			if(OutColor.a == 0)
			{
				return OutColor;
			}
			
			float4 overlay = float4(0,0,0,0);
			
			if(remainder == 0)
			{
				overlay = float4(0.0196,0.3255,0.3882,0.4);
			}
			else if(remainder == 1)
			{
				overlay = float4(0.0706,0.3569,0.3255,0.4);
			}
			else{
				overlay = float4(0.0118,0.4039,0.3842,0.4);
			}
			float4 finalColour = float4(0,0,0,1);
			finalColour.a = overlay.a + OutColor.a * (1 - overlay.a);
			finalColour.r = (overlay.r * overlay.a) + (OutColor.r * OutColor.a * (1 - overlay.a));
			finalColour.g = (overlay.g * overlay.a) + (OutColor.g * OutColor.a * (1 - overlay.a));
			finalColour.b = (overlay.b * overlay.a) + (OutColor.b * OutColor.a * (1 - overlay.a));
			
			
			
			return finalColour;
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
			float vTime = Time - AnimationTime;
			
			float4 OutColor = tex2D( MapTexture, v.vTexCoord );
			
			float input = round(NextOffset.x*53.0f);
			float type = floor(input/1000000.f);
			float stateNumber = floor(input/10000.f) - (type * 100.f);
			
			float information = round(abs(input - (stateNumber * 10000.f))) - (type * 1000000.f);
			
			float partB = floor(information/1000.f);
			float partC = floor(information/100.f) - (partB * 10.f);
			float partD = floor(information/10.f) - (partC * 10.f) - (partB * 100.f);
			float partE = floor(information) - (partC * 100.f) - (partD * 10.f) - (partB * 1000.f);
			
			float4 outColour = float4(0,0,0,0);
			
			//Static
			if(type == 0)
			{
				float4 firstColour = getPartyAndColour(partB, partC);
				float4 secondColour = getPartyAndColour(partD, partE);
					
				if(partB == 9)
				{
					firstColour = float4(0,0,0,1);
				}
				if(partD == 9)
				{
					secondColour = float4(0,0,0,1);
				}
				
					
				float4 difference = secondColour - firstColour;
				if(vTime < 1 && (partB > 0 || partC > 0)){
					difference *= vTime;
				}
				outColour = firstColour + difference;
			}
			//Animated
			else{
				//Polls Open
				if(information == 999){
					outColour.rgb = float3(0,0.4,0);
				}
				//Polls Closed
				else if(information == 998){
					outColour.rgb = float3(vTime * 0.4,0.4,0);
					if(vTime > 1)
					{
						outColour.rgb = float3(0.4,0.4,0);
					}
				}
				//Polls partially closed
				else if(information == 997){
					outColour.rgb = float3(vTime * 0.4,0.4,0);
					if(vTime > 1)
					{
						outColour.rgb = float3(0.4,0.4,0);
					}
				}
				else{
					//State Call
					if(partB == 9 && partC == 9)
					{
						outColour = getPartyAndColour(partE, 0);
						//Flash
						if(partD == 0)
						{
							float changePoint = 3.f/60.f;
							if ((vTime > changePoint && vTime <= (changePoint * 2.f)) || (vTime > (changePoint * 3.f) && vTime <= (changePoint * 4.f)) || (vTime > (changePoint * 5.f) && vTime <= (changePoint * 6.f))) {
								outColour = float4(1,1,1,1);
							}
						}
					}
					else{
						float4 previousColour = getPartyAndColour(partB, partC);
						float4 currentColour = getPartyAndColour(partD, partE);
						
						if(partB == 9 && partC == 8)
						{
							previousColour = float4(0.4,0.4,0,1);
						}
						else if(partB == 9 && partC == 7)
						{
							previousColour = float4(0.4,0.4,0,1);
						}
						
						float4 difference = currentColour - previousColour;
						if(vTime < 1){
							difference *= vTime;
						}
						outColour = previousColour + difference;
					}
				}
			}
			
			OutColor.rgb = outColour.rgb;
			if(type == 1 && partD != 9 && partC != 9 && OutColor.a > 0)
			{
				if(vTime > 1 || partB != 9){
					OutColor.a = 0.7f;
				}
				else{
					OutColor.a = 1 - (0.3f * vTime);
				}
			}
			
			float remainder = floor(v.vPosition.y%3);
			
			if(OutColor.a == 0)
			{
				return OutColor;
			}
			
			float4 overlay = float4(0,0,0,0);
			
			if(remainder == 0)
			{
				overlay = float4(0.0196,0.3255,0.3882,0.4);
			}
			else if(remainder == 1)
			{
				overlay = float4(0.0706,0.3569,0.3255,0.4);
			}
			else{
				overlay = float4(0.0118,0.4039,0.3842,0.4);
			}
			
			float4 finalColour = float4(0,0,0,1);
			finalColour.a = overlay.a + OutColor.a * (1 - overlay.a);
			finalColour.r = (overlay.r * overlay.a) + (OutColor.r * OutColor.a * (1 - overlay.a));
			finalColour.g = (overlay.g * overlay.a) + (OutColor.g * OutColor.a * (1 - overlay.a));
			finalColour.b = (overlay.b * overlay.a) + (OutColor.b * OutColor.a * (1 - overlay.a));
			
			
			return finalColour;
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

