PixelShader = 
{
	Code
	[[
		static const float zeroWidth = 18.f;
		static const float oneWidth = 7.f;
		static const float twoWidth = 16.f;
		static const float threeWidth = 18.f;
		static const float fourWidth = 18.f;
		static const float fiveWidth = 17.f;
		static const float sixWidth = 16.f;
		static const float sevenWidth = 17.f;
		static const float eightWidth = 17.f;
		static const float nineWidth = 16.f;
		
		static const float zeroStart = 0.f;
		static const float oneStart = 21.f;
		static const float twoStart = 33.f;
		static const float threeStart = 52.f;
		static const float fourStart = 71.f;
		static const float fiveStart = 90.f;
		static const float sixStart = 111.f;
		static const float sevenStart = 130.f;
		static const float eightStart = 149.f;
		static const float nineStart = 170.f;
			
		float getDigitWidth(float digit)
		{
			float width = 0;
			if(digit == 0)
			{
				width = zeroWidth;
			}
			else if(digit == 1)
			{
				width = oneWidth;
			}
			else if(digit == 2)
			{
				width = twoWidth;
			}
			else if(digit == 3)
			{
				width = threeWidth;
			}
			else if(digit == 4)
			{
				width = fourWidth;
			}
			else if(digit == 5)
			{
				width = fiveWidth;
			}
			else if(digit == 6)
			{
				width = sixWidth;
			}
			else if(digit == 7)
			{
				width = sevenWidth;
			}
			else if(digit == 8)
			{
				width = eightWidth;
			}
			else if(digit == 9)
			{
				width = nineWidth;
			}
			return width;
		}
		float getDigitPoint(float digit)
		{
			float start = 0;
			if(digit == 0)
			{
				start = zeroStart;
			}
			else if(digit == 1)
			{
				start = oneStart;
			}
			else if(digit == 2)
			{
				start = twoStart;
			}
			else if(digit == 3)
			{
				start = threeStart;
			}
			else if(digit == 4)
			{
				start = fourStart;
			}
			else if(digit == 5)
			{
				start = fiveStart;
			}
			else if(digit == 6)
			{
				start = sixStart;
			}
			else if(digit == 7)
			{
				start = sevenStart;
			}
			else if(digit == 8)
			{
				start = eightStart;
			}
			else if(digit == 9)
			{
				start = nineStart;
			}
			return start;
		}
		float calculateNumberWidth(float number)
		{
			float width = 0;
			float hundreds = floor(number/100.f);
			float tens = floor(number/10.f) - (hundreds * 10.f);
			float ones = floor(number) - (tens * 10.f) - (hundreds * 100.f);
			if(hundreds > 0)
			{
				width += getDigitWidth(hundreds);
				width += 3;
			}
			if(tens > 0 || hundreds > 0)
			{
				width += getDigitWidth(tens);
				width += 3;
			}
			width += getDigitWidth(ones);
			return width;
		}
	]]
}