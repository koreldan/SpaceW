﻿// Procedural planet generator.
// 
// Copyright (C) 2015-2017 Denis Ovchinnikov [zameran] 
// All rights reserved.
// 
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holders nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
// 
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION)HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
// THE POSSIBILITY OF SUCH DAMAGE.
// 
// Creation Date: Undefined
// Creation Time: Undefined
// Creator: zameran

Shader "SpaceEngine/Ring"
{
	Properties
	{
		_NoiseTexture("Noise Texture", 2D) = "white" {}
		_DiffuseTexture("Diffuse Texture", 2D) = "white" {}
		_DiffuseColor("Diffuse Color", Color) = (1, 1, 1, 1)
		_Mie("Mie", Vector) = (0,0,0)
		_LightingBias("Lighting Bias", Float) = 0
		_LightingSharpness("Lighting Sharpness", Float) = 0
	}
	SubShader
	{
		CGINCLUDE
			
		#include "SpaceStuff.cginc"

		sampler2D _NoiseTexture;
		sampler2D _DiffuseTexture;
		float4    _DiffuseColor;
		float4    _Mie;
		float     _LightingBias;
		float     _LightingSharpness;
				
		struct a2v
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};
				
		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 color : COLOR0;

			// World vertex/pixel to camera
			float3 relativeDirection : TEXCOORD1;

			// World vertex/pixel to light N
			#if LIGHT_1 || LIGHT_2 || LIGHT_3 || LIGHT_4
				float3 sunRelDirection_1 : TEXCOORD2;

				#if LIGHT_2
					float3 sunRelDirection_2 : TEXCOORD3;
				#endif

				#if LIGHT_3
					float3 sunRelDirection_3 : TEXCOORD4;
				#endif

				#if LIGHT_4
					float3 sunRelDirection_4 : TEXCOORD5;
				#endif
			#endif

			// World vertex/pixel
			float4 worldPosition : TEXCOORD6;
		};
				
		struct f2g
		{
			float4 color : COLOR;
		};
			
		void main_Vertex(a2v i, out v2f o)
		{
			float4 worldPosition = mul(unity_ObjectToWorld, i.vertex);
			
			o.vertex = mul(UNITY_MATRIX_MVP, i.vertex);
			o.uv = float2(clamp(i.uv.x, 0.0064, 0.9936), i.uv.y); //NOTE : Oh shit...
			o.color = 1.0f;

			#if LIGHT_1 || LIGHT_2 || LIGHT_3 || LIGHT_4
				o.color *= UNITY_LIGHTMODEL_AMBIENT * 2.0f;
			#endif

			o.relativeDirection = _WorldSpaceCameraPos - worldPosition.xyz;
			o.relativeDirection = normalize(o.relativeDirection);

			#if LIGHT_1 || LIGHT_2 || LIGHT_3 || LIGHT_4
					o.sunRelDirection_1 = _Light1Position.xyz - worldPosition.xyz;
					o.sunRelDirection_1 = normalize(o.sunRelDirection_1);
				#if LIGHT_2
					o.sunRelDirection_2 = _Light2Position.xyz - worldPosition.xyz;
					o.sunRelDirection_2 = normalize(o.sunRelDirection_2);
				#endif
				#if LIGHT_3
					o.sunRelDirection_3 = _Light3Position.xyz - worldPosition.xyz;
					o.sunRelDirection_3 = normalize(o.sunRelDirection_3);
				#endif
				#if LIGHT_4
					o.sunRelDirection_4 = _Light4Position.xyz - worldPosition.xyz;
					o.sunRelDirection_4 = normalize(o.sunRelDirection_4);
				#endif
			#endif

			o.worldPosition = worldPosition;
		}
				
		void main_Fragment(v2f i, out f2g o)
		{
			float4 mainTex = tex2D(_DiffuseTexture, i.uv);
			float4 mainColor = mainTex * _DiffuseColor;
					
			o.color = i.color * mainColor;

			float cameraDistance = length(i.relativeDirection);

			float2 position = i.worldPosition.xz * 0.1;
			float2 deltaPosition = float2(position.x, position.y + _Time.y);
			float radial = i.uv * 512;
			float noiseValue = 1;
			float fadeIn = 1.0 - cameraDistance * 0.00002;
			float fadeOut = smoothstep(0.0, 1.0, cameraDistance * 0.02 - 0.25);
					
			if(fadeIn > 0.0)
			{
				noiseValue = tex2D(_NoiseTexture, deltaPosition).r *
							 tex2D(_NoiseTexture, deltaPosition * 0.3).g *
							 tex2D(_NoiseTexture, float2(radial, 0.5)).b *
							 tex2D(_NoiseTexture, float2(radial * 0.3, 0.5)).a * 16.0;

				noiseValue = saturate(noiseValue);
				noiseValue = lerp(1.0, noiseValue, clamp(fadeIn, 0.0, 1.0));
			}

			mainColor *= noiseValue;
				
			#if LIGHT_1 || LIGHT_2 || LIGHT_3 || LIGHT_4
				float3 shapened = i.relativeDirection * _LightingSharpness;

				float4 lighting = 0;

				lighting.xyz += saturate(dot(i.sunRelDirection_1, shapened) + _LightingBias) * _Light1Color;

				#if LIGHT_2
					lighting.xyz += (saturate(dot(i.sunRelDirection_2, shapened) + _LightingBias) * _Light2Color).xyz;
				#endif

				#if LIGHT_3
					lighting.xyz += (saturate(dot(i.sunRelDirection_3, shapened) + _LightingBias) * _Light3Color).xyz;
				#endif

				#if LIGHT_4
					lighting.xyz += (saturate(dot(i.sunRelDirection_4, shapened) + _LightingBias) * _Light4Color).xyz;
				#endif

				#if SCATTERING
					float4 scattering = MiePhase(dot(i.relativeDirection, i.sunRelDirection_1), _Mie) * _Light1Color;

					#if LIGHT_2
						scattering += MiePhase(dot(i.relativeDirection, i.sunRelDirection_2), _Mie) * _Light2Color;
					#endif

					#if LIGHT_3
						scattering += MiePhase(dot(i.relativeDirection, i.sunRelDirection_3), _Mie) * _Light3Color;
					#endif

					#if LIGHT_4
						scattering += MiePhase(dot(i.relativeDirection, i.sunRelDirection_4), _Mie) * _Light4Color;
					#endif

					scattering *= mainTex.w * (1.0f - mainTex.w); // Only scatter at the edges
				
					lighting += scattering;
				#endif

				#if SHADOW_1 || SHADOW_2 || SHADOW_3 || SHADOW_4
					lighting *= ShadowColor(i.worldPosition);
				#endif

				o.color += lighting * mainColor;
			#endif

			#if !LIGHT_1 && !LIGHT_2 && !LIGHT_3 && !LIGHT_4
				o.color = mainColor;
				o.color *= fadeOut;

				// Shadows with no lights?
				//#if SHADOW_1 || SHADOW_2 || SHADOW_3 || SHADOW_4
				//	o.color.xyz *= ShadowColor(i.worldPosition).xyz;
				//#endif
			#endif
		}
		ENDCG

		Pass
		{
			Name "Ring"
			Tags
			{
				"Queue"           = "Transparent"
				"RenderType"      = "Transparent"
				"IgnoreProjector" = "True"
			}

			Blend One OneMinusSrcColor
			Cull Off
			Lighting Off
			ZWrite On
			ZTest LEqual 
			Fog 
			{ 
				Mode Off 
			}
			
			CGPROGRAM

			#pragma target 5.0
			#pragma only_renderers d3d11 glcore
			#pragma vertex main_Vertex
			#pragma fragment main_Fragment
			#pragma multi_compile DUMMY LIGHT_1 LIGHT_2 LIGHT_3 LIGHT_3
			#pragma multi_compile DUMMY SHADOW_1 SHADOW_2 SHADOW_3 SHADOW_4
			#pragma multi_compile DUMMY SCATTERING
				
			ENDCG
		}

		//TODO : Shadow pass...
		Pass 
		{
			Name "ShadowCaster"
			Tags 
			{ 
				"LightMode" = "ShadowCaster" 
			}

			ZWrite On 
			ZTest LEqual

			CGPROGRAM
			#pragma target 3.0

			#pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
			#pragma multi_compile_shadowcaster

			#pragma vertex vertShadowCaster
			#pragma fragment fragShadowCaster

			#include "UnityStandardShadow.cginc"

			ENDCG
		}
	}
}