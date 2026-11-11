Includes = {
	"buttonstate.fxh"
	"sprite_animation.fxh"
	"tno_functions.fxh"
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
	
	MainCode VertexShader2
	[[
		VS_OUTPUT main(const VS_INPUT v )
		{
		    VS_OUTPUT Out;
		    Out.vPosition  = mul( WorldViewProjectionMatrix, float4( v.vPosition.xyz, 1 ) );
		
		    Out.vTexCoord = v.vTexCoord;
			
		#ifdef ANIMATED
			//Out.vAnimatedTexCoord = GetAnimatedTexcoord(v.vTexCoord);	
		#endif

		#ifdef MASKING
			A bit hacky, but we want the masking texture coordinates to be in the range [0,1]. We turn all 0's to 0 and all nonzero to 1.
			Out.vMaskingTexCoord = saturate(v.vTexCoord * 1000); 
		#endif
		
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
		    float vTime = (Time - AnimationTime);
			float value = determineValue(Offset, NextOffset);

			float2 vDiff = float2(0.25f - v.vTexCoord.x, v.vTexCoord.y - 0.5f);
			float vAngle = atan2TNO(vDiff) + 3.14159265f;

			float packedWithoutControl = floor(value / 101.f);
			float control = value - (packedWithoutControl * 101.f);
			float palette = floor(packedWithoutControl / 101.f);
			float start = packedWithoutControl - (palette * 101.f);
			float end = start + control;

			// The faction order in MEX_DW_ALL_GROUPS is fixed.
			float3 pieColour = float3(75.f, 56.f, 39.f) / 255.f;
			if (palette < 0.5f) {
				pieColour = float3(89.f, 199.f, 194.f) / 255.f;
			} else if (palette < 1.5f) {
				pieColour = float3(210.f, 73.f, 73.f) / 255.f;
			} else if (palette < 2.5f) {
				pieColour = float3(170.f, 42.f, 42.f) / 255.f;
			} else if (palette > 12.5f && palette < 13.5f) {
				pieColour = float3(37.f, 28.f, 19.f) / 255.f;
			}

			float fTime = 1.f - (cos(vTime * 6.5f) + 1.f) / 2.f;
			if (vTime > 0.5f) {
				fTime = 1.f;
			}
			fTime = saturate(fTime);

			// Each icon owns its final cumulative slice, but every icon uses the
			// same animated sweep boundary. The stacked icons therefore reveal as
			// one complete pie instead of growing every slice independently.
			float fillStart = (start / 100.f) * 3.14159265f * 2.f;
			float fillEnd = (end / 100.f) * 3.14159265f * 2.f;
			float sweepEnd = fTime * 3.14159265f * 2.f;

			bool isInSlice = false;
			if (fillStart < fillEnd) {
				isInSlice = (vAngle >= fillStart) && (vAngle <= fillEnd);
			} else {
				isInSlice = (vAngle >= fillStart) || (vAngle <= fillEnd);
			}
			bool isFilled = isInSlice && (vAngle <= sweepEnd);

			float4 sourceColour;
			if (isFilled) {
				sourceColour = tex2D(MapTexture, v.vTexCoord.xy);
			} else {
				sourceColour = tex2D(MapTexture, float2(v.vTexCoord.x + 0.5f, v.vTexCoord.y));
			}
			float shade = sourceColour.g * (255.f / 199.f);
			return float4(pieColour * shade, sourceColour.a);
		}
	]]

	MainCode PixelShaderDown
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float4 OutColor = tex2D( MapTexture, v.vTexCoord );
					
		#ifdef ANIMATED
			OutColor = Animate(OutColor, v.vTexCoord, v.MapTexture, MapTexture, MapTexture, MapTexture, MapTexture);
		#endif

		#ifdef MASKING
			float4 MaskColor = tex2D( MaskingTexture, v.vTexCoord );
			OutColor.a *= MaskColor.a;
		#endif
			
			OutColor *= Color;

			return OutColor;
		}
	]]

	MainCode PixelShaderDisable
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
			float vTime = (Time - AnimationTime);
			float value = determineValue(Offset, NextOffset);

			float2 vDiff = float2(0.25f - v.vTexCoord.x, v.vTexCoord.y - 0.5f);
			float vAngle = atan2TNO(vDiff) + 3.14159265f;

			float packedWithoutControl = floor(value / 101.f);
			float control = value - (packedWithoutControl * 101.f);
			float palette = floor(packedWithoutControl / 101.f);
			float start = packedWithoutControl - (palette * 101.f);
			float end = start + control;

			float3 pieColour = float3(75.f, 56.f, 39.f) / 255.f;
			if (palette < 0.5f) {
				pieColour = float3(89.f, 199.f, 194.f) / 255.f;
			} else if (palette < 1.5f) {
				pieColour = float3(210.f, 73.f, 73.f) / 255.f;
			} else if (palette < 2.5f) {
				pieColour = float3(170.f, 42.f, 42.f) / 255.f;
			} else if (palette > 12.5f && palette < 13.5f) {
				pieColour = float3(37.f, 28.f, 19.f) / 255.f;
			}

			float fTime = 1.f - (cos(vTime * 6.5f) + 1.f) / 2.f;
			if (vTime > 0.5f) {
				fTime = 1.f;
			}
			fTime = saturate(fTime);

			float fillStart = (start / 100.f) * 3.14159265f * 2.f;
			float fillEnd = (end / 100.f) * 3.14159265f * 2.f;
			float sweepEnd = fTime * 3.14159265f * 2.f;

			bool isInSlice = false;
			if (fillStart < fillEnd) {
				isInSlice = (vAngle >= fillStart) && (vAngle <= fillEnd);
			} else {
				isInSlice = (vAngle >= fillStart) || (vAngle <= fillEnd);
			}
			bool isFilled = isInSlice && (vAngle <= sweepEnd);

			float4 sourceColour;
			if (isFilled) {
				sourceColour = tex2D(MapTexture, v.vTexCoord.xy);
			} else {
				sourceColour = tex2D(MapTexture, float2(v.vTexCoord.x + 0.5f, v.vTexCoord.y));
			}
			float shade = sourceColour.g * (255.f / 199.f);
			return float4(pieColour * shade, sourceColour.a);
		}	
	]]

	MainCode PixelShaderOver
	[[
		float4 main( VS_OUTPUT v ) : PDX_COLOR
		{
		    float vTime = (Time - AnimationTime);
		    float value = Offset.x + 1.f;
			float endVal = floor(value / 1000.f);
			float startVal = value - (endVal * 1000.f);
			float gap = (endVal - startVal)/100.f;
			float yPos = 1.f -  (startVal/100.f);
			yPos += gap * sin(vTime);
			float timeCheck = saturate(vTime);
			if (startVal == 5) {
				return float4(1,0,1,1);
			}
			else {
				return float4(1,1,1,1);
			}
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
	VertexShader = "VertexShader2"
	PixelShader = "PixelShaderUp"
}

Effect Down
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUp"
}

Effect Disable
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderDisable"
}

Effect Over
{
	VertexShader = "VertexShader"
	PixelShader = "PixelShaderUp"
}
