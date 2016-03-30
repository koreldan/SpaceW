//-----------------------------------------------------------------------------
struct QuadGenerationConstants
{
	float planetRadius;
	float spacing;
	float spacingreal;
	float spacingsub;
	float terrainMaxHeight;
	float lodLevel;
	float orientation;

	float3 cubeFaceEastDirection;
	float3 cubeFaceNorthDirection;
	float3 patchCubeCenter;
};

struct OutputStruct
{
	float noise;

	float3 patchCenter;
	
	float4 vcolor;
	float4 pos;
	float4 cpos;
};
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
float3 FindBiTangent(float3 normal, float epsilon, float3 dir)
{
	float refVectorSign = sign(1.0 - abs(normal.x) - epsilon);

	float3 refVector = refVectorSign * dir;
	float3 biTangent = refVectorSign * cross(normal, refVector);

	return biTangent;
}

float3 FindTangent(float3 normal, float epsilon, float3 dir)
{
	float refVectorSign = sign(1.0 - abs(normal.x) - epsilon);

	float3 refVector = refVectorSign * dir;
	float3 biTangent = refVectorSign * cross(normal, refVector);

	return cross(-normal, biTangent);
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
float3 CubeCoord(QuadGenerationConstants constants, float VerticesPerSide, uint3 id, int mod, float spacing)
{
	//32 : 1;     x = 32; y = 32;   z0 = y / x + 0 + 0;
	//64 : 3;     x = 32; y = 64;   z1 = y / x + z0 + 0;
	//128 : 7;    x = 32; y = 128;  z2 = y / x + z1 + 0;
	//256 : 17;   x = 32; y = 256;  z3 = y / x + z2 + 2; = 17
	//512 : 41;   x = 32; y = 512;  z4 = y / x + z3 + 8; = 41
	//1024 : 105; x = 32; y = 1024; z5 = y / x + z4 + 32; = 105

	//TODO modifier calculation.

	float eastValue = (id.x - ((VerticesPerSide - mod) / 2.0)) * spacing;
	float northValue = (id.y - ((VerticesPerSide - mod) / 2.0)) * spacing;

	float3 cubeCoordEast = constants.cubeFaceEastDirection * eastValue;
	float3 cubeCoordNorth = constants.cubeFaceNorthDirection * northValue;

	float3 cubeCoord = cubeCoordEast + cubeCoordNorth + constants.patchCubeCenter;

	return cubeCoord;
}
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// Project the surface gradient (dhdx, dhdy) onto the surface (n, dpdx, dpdy)
float3 CalculateSurfaceGradient(float3 n, float3 dpdx, float3 dpdy, float dhdx, float dhdy) 
{
	float3 r1 = cross(dpdy, n);
	float3 r2 = cross(n, dpdx);
  
	return (r1 * dhdx + r2 * dhdy) / dot(dpdx, r1);
}
 
// Move the normal away from the surface normal in the opposite surface gradient direction
float3 PerturbNormal(float3 normal, float3 dpdx, float3 dpdy, float dhdx, float dhdy) 
{
	return normalize(normal - CalculateSurfaceGradient(normal, dpdx, dpdy, dhdx, dhdy));
}

// Calculate the surface normal using screen-space partial derivatives of the height field
float3 CalculateSurfaceNormal_HeightMap(float3 position, float3 normal, float height)
{
	float3 dpdx = ddx_fine(position);
	float3 dpdy = ddy_fine(position);
		   
	float dhdx = ddx_fine(height);
	float dhdy = ddy_fine(height);
  
	return PerturbNormal(normal, dpdx, dpdy, dhdx, dhdy);
}
//-----------------------------------------------------------------------------