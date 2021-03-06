﻿Shader "SpaceEngine/Terrain/Planet" 
{
	Properties
	{
		_Normals_Tile("Normals", 2D) = "white" {}
	}
	SubShader 
	{
		Tags { "Queue" = "Geometry" "RenderType"="" }
		
		Pass 
		{
			Cull Back

			CGPROGRAM
			#include "UnityCG.cginc"
			#pragma target 4.0
			#pragma vertex vert
			#pragma fragment frag
			
			//#define CUBE_PROJECTION
			
			//#include "Assets/Proland/Shaders/Core/Utility.cginc"
			//#include "Assets/Proland/Shaders/Atmo/Atmosphere.cginc"
			//#include "Assets/Proland/Shaders/Ocean/OceanBrdf.cginc"
			
			uniform float2 _Deform_Blending;
			uniform float4x4 _Deform_LocalToWorld;
			uniform float4x4 _Deform_LocalToScreen;
			uniform float4 _Deform_Offset;
			uniform float4 _Deform_Camera;
			uniform float4x4 _Deform_ScreenQuadCorners;
			uniform float4x4 _Deform_ScreenQuadVerticals;
			uniform float _Deform_Radius;
			uniform float4 _Deform_ScreenQuadCornerNorms;
			uniform float4x4 _Deform_TangentFrameToWorld; 
			
			uniform sampler2D _Elevation_Tile;
			uniform float3 _Elevation_TileSize;
			uniform float3 _Elevation_TileCoords;
			
			uniform sampler2D _Normals_Tile;
			uniform float3 _Normals_TileSize;
			uniform float3 _Normals_TileCoords;
			
			uniform sampler2D _Ortho_Tile;
			uniform float3 _Ortho_TileSize;
			uniform float3 _Ortho_TileCoords;
			
			uniform float3 _Globals_WorldCameraPos;
			
			uniform float _Ocean_Sigma;
			uniform float3 _Ocean_Color;
			uniform float _Ocean_DrawBRDF;
			uniform float _Ocean_Level;
			
			
			struct v2f 
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 p : TEXCOORD1;
			};
			
			float4 texTileLod(sampler2D tile, float2 uv, float3 tileCoords, float3 tileSize) 
			{
				uv = tileCoords.xy + uv * tileSize.xy;

				return tex2Dlod(tile, float4(uv, 0, 0));
			}

			float4 texTile(sampler2D tile, float2 uv, float3 tileCoords, float3 tileSize) 
			{
				uv = tileCoords.xy + uv * tileSize.xy;

				return tex2D(tile, uv);
			}

			v2f vert(appdata_base v)
			{		
				float2 zfc = texTileLod(_Elevation_Tile, v.texcoord.xy, _Elevation_TileCoords, _Elevation_TileSize).xy;
				
				if(zfc.x <= _Ocean_Level && _Ocean_DrawBRDF == 1.0)
				{
					zfc = float2(0, 0);
				}
					
				float2 vert = abs(_Deform_Camera.xy - v.vertex.xy);

				float _blend = clamp((max(max(vert.x, vert.y), _Deform_Camera.z) - _Deform_Blending.x) / _Deform_Blending.y, 0.0, 1.0);
				
				float4 L = _Deform_ScreenQuadCornerNorms;
				float3 P = float3(v.vertex.xy * _Deform_Offset.z + _Deform_Offset.xy, _Deform_Radius);
				
				float4 uvUV = float4(v.vertex.xy, float2(1.0,1.0) - v.vertex.xy);
				float4 alpha = uvUV.zxzx * uvUV.wwyy;
				float4 alphaPrime = alpha * L / dot(alpha, L);
				
				float h = zfc.x * (1.0 - _blend) + zfc.y * _blend;
				float k = min(length(P) / dot(alpha, L) * 1.0000003, 1.0);
				float hPrime = (h + _Deform_Radius * (1.0 - k)) / k;
				
				v2f OUT;
	
				#ifdef CUBE_PROJECTION
					OUT.pos = mul(_Deform_LocalToScreen, float4(P + float3(0.0, 0.0, h), 1.0));
				#else
					OUT.pos = mul(_Deform_ScreenQuadCorners + hPrime * _Deform_ScreenQuadVerticals,  alphaPrime);
				#endif
				
				OUT.uv = v.texcoord.xy;
				
				float3x3 LTW = _Deform_LocalToWorld;
				
				OUT.p = (_Deform_Radius + max(h, _Ocean_Level)) * normalize(mul(LTW, P));
				
				return OUT;
			}
			
			float4 frag(v2f IN) : COLOR
			{		
				float3 WCP = _Globals_WorldCameraPos;
				float3 WSD = float3(0.0, -1.0, 0.0);
				float ht = texTile(_Elevation_Tile, IN.uv, _Elevation_TileCoords, _Elevation_TileSize).x;
				
				float3 V = normalize(IN.p);
				float3 P = V * max(length(IN.p), _Deform_Radius + 10.0);
				float3 v = normalize(P - WCP);
				
				float3 fn;
				fn.xyz = texTile(_Normals_Tile, IN.uv, _Normals_TileCoords, _Normals_TileSize).xyz;
				fn.z = sqrt(max(0.0, 1.0 - dot(fn.xy, fn.xy)));
				
				//if(ht <= _Ocean_Level && _Ocean_DrawBRDF == 1.0)
				//	fn = float3(0,0,1);
	
				float3x3 TTW = _Deform_TangentFrameToWorld;
				fn = mul(TTW, fn);
				
				float cTheta = dot(fn, WSD);
				float vSun = dot(V, WSD);
				
				float4 reflectance = texTile(_Ortho_Tile, IN.uv, _Ortho_TileCoords, _Ortho_TileSize);
				reflectance.rgb = tan(1.37 * reflectance.rgb) / tan(1.37); //RGB to reflectance
				
				//float3 sunL;
				//float3 skyE;
				//SunRadianceAndSkyIrradiance(P, fn, WSD, sunL, skyE);
				
				// diffuse ground color
				//float3 groundColor = 1.5 * reflectance.rgb * (sunL * max(cTheta, 0.0) + skyE) / 3.14159265;
				float3 groundColor = 1.5 * reflectance.rgb * (10 * max(cTheta, 0.0)) / 3.14159265;
				
				//if(ht <= _Ocean_Level && _Ocean_DrawBRDF == 1.0)
				//	groundColor = OceanRadiance(WSD, -v, V, _Ocean_Sigma, sunL, skyE, _Ocean_Color);

				//float3 extinction;
				//float3 inscatter = InScattering(WCP, P, WSD, extinction, 0.0);

				//float3 finalColor = hdr(groundColor * extinction + inscatter);

				//return float4(finalColor, 1.0);

				return float4(fn, 1.0);
			}
			
			ENDCG
		}
	}
}