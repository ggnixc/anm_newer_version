PixelShader = 
{
	Code
	[[
		static const float4 repColour = float4(0.769, 0.078, 0.078, 1.0);
		static const float4 repLikelyColour = float4(0.851, 0.165, 0.165, 1.0);
		static const float4 repLeanColour = float4(0.839, 0.255, 0.255, 1.0);
		static const float4 repTiltColour = float4(0.839, 0.369, 0.369, 1.0);
		
		static const float4 tossupColour = float4(0.749, 0.529, 0.671, 1.0);
		
		static const float4 demTiltColour = float4(0.298, 0.576, 0.859, 1.0);
		static const float4 demLeanColour = float4(0.196,  0.463,  0.729, 1.0);
		static const float4 demLikelyColour = float4(0.129,  0.384,  0.639, 1.0);
		static const float4 demColour = float4(0.078,  0.302,  0.529, 1.0);
		
		static const float4 indTiltColour = float4(0.5686, 0.4784, 0.4510, 1.0);
		static const float4 indLeanColour = float4(0.6039, 0.4549, 0.3922, 1.0);
		static const float4 indLikelyColour = float4(0.6353, 0.4353, 0.3294, 1.0);
		static const float4 indColour = float4(0.6667, 0.4118, 0.2667, 1.0);
		
		static const float4 redColour = float4(0.5882, 0, 0, 1.0);
		static const float4 greenColour = float4(0, 0.5882, 0, 1.0);
			
		float4 getFactionLeanColour(float colourNumber)
		{
			float4 outColour = float4(0,0,0,0);
			if (colourNumber == 0) {
				outColour = demColour;
			}
			else if (colourNumber == 1) {
				outColour = demLikelyColour;
			}
			else if (colourNumber == 2) {
				outColour = demLeanColour;
			}
			else if (colourNumber == 3) {
				outColour = demTiltColour;
			}
			else if (colourNumber == 4) {
				outColour = tossupColour;
			}
			else if (colourNumber == 5) {
				outColour = tossupColour;
			}
			else if (colourNumber == 6) {
				outColour = repTiltColour;
			}
			else if (colourNumber == 7) {
				outColour = repLeanColour;
			}
			else if (colourNumber == 8) {
				outColour = repLikelyColour;
			}
			else if (colourNumber == 9) {
				outColour = repColour;
			}
			else {
			
			}
			return outColour;
		}
		float4 getRepLeanColour(float colourNumber)
		{
			float4 outColour = float4(0,0,0,0);
			if (colourNumber == 0) {
				outColour = repColour;
			}
			else if (colourNumber == 1) {
				outColour = repLikelyColour;
			}
			else if (colourNumber == 2) {
				outColour = repLeanColour;
			}
			else if (colourNumber == 3) {
				outColour = repTiltColour;
			}
			else if (colourNumber == 4) {
				outColour = tossupColour;
			}
			else {
			
			}
			return outColour;
		}
		float4 getDemLeanColour(float colourNumber)
		{
			float4 outColour = float4(0,0,0,0);
			if (colourNumber == 0) {
				outColour = demColour;
			}
			else if (colourNumber == 1) {
				outColour = demLikelyColour;
			}
			else if (colourNumber == 2) {
				outColour = demLeanColour;
			}
			else if (colourNumber == 3) {
				outColour = demTiltColour;
			}
			else if (colourNumber == 4) {
				outColour = tossupColour;
			}
			else {
			
			}
			return outColour;
		}
		float4 getIndLeanColour(float colourNumber)
		{
			float4 outColour = float4(0,0,0,0);
			if (colourNumber == 0) {
				outColour = indColour;
			}
			else if (colourNumber == 1) {
				outColour = indLikelyColour;
			}
			else if (colourNumber == 2) {
				outColour = indLeanColour;
			}
			else if (colourNumber == 3) {
				outColour = indTiltColour;
			}
			else if (colourNumber == 4) {
				outColour = tossupColour;
			}
			else {
			
			}
			return outColour;
		}
		float4 getRedGreenBlend(float blendAmount)
		{
			float4 outColour = float4(0,0,0,0);
			outColour = lerp(redColour, greenColour, (blendAmount/100.f));
			if(blendAmount == 0){
				outColour = float4(0,0,0,1);
			}
			return outColour;
		}
		float4 getPartyAndColour(float party, float lean)
		{
			float4 outColour = float4(0,0,0,0);
			if(party == 1)
			{
				outColour = getRepLeanColour(lean);
			}
			else if(party == 2)
			{
				outColour = getDemLeanColour(lean);
			}
			else if(party == 3)
			{
				outColour = getIndLeanColour(lean);
			}
			return outColour;
		}
	
	]]
}