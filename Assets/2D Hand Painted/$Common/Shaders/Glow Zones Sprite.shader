// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hand Painted 2D/Sprite Glow Zones"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_MainTex("Diffuse", 2D) = "white" {}
		_GlowScale("Glow Scale", Range( 0.1 , 2)) = 0.5
		_GlowSpeed("Glow Speed", Range( 0.1 , 2)) = 0.5
		_GlowBlend("Glow Blend", Range( 0 , 1)) = 0.35
		_ForegroundColor("Foreground Color", Color) = (0.4156863,0.3921569,0.4352941,1)
		_BackgroundColor("Background Color", Color) = (0.4980392,0.7137255,0.8,1)
		_BackgroundRange("Background Range", Vector) = (1,60,0,0)
		_ForegroundRange("Foreground Range", Vector) = (-1,-8,0,0)
		_MaskTex("Mask", 2D) = "white" {}
		_NormalMap("Normal Map", 2D) = "bump" {}
		[ASEEnd][Toggle(_FOG_ON)] _Fog("Fog", Float) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "PreviewType"="Plane" }

		Cull Off
		HLSLINCLUDE
		#pragma target 2.0
		ENDHLSL

		
		Pass
		{
			Name "Sprite Lit"
			Tags { "LightMode"="Universal2D" }
			
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define ASE_SRP_VERSION 70503

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ ETC1_EXTERNAL_ALPHA
			#pragma multi_compile _ USE_SHAPE_LIGHT_TYPE_0
			#pragma multi_compile _ USE_SHAPE_LIGHT_TYPE_1
			#pragma multi_compile _ USE_SHAPE_LIGHT_TYPE_2
			#pragma multi_compile _ USE_SHAPE_LIGHT_TYPE_3

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define SHADERPASS_SPRITELIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/LightingUtility.hlsl"
			
			#if USE_SHAPE_LIGHT_TYPE_0
			SHAPE_LIGHT(0)
			#endif

			#if USE_SHAPE_LIGHT_TYPE_1
			SHAPE_LIGHT(1)
			#endif

			#if USE_SHAPE_LIGHT_TYPE_2
			SHAPE_LIGHT(2)
			#endif

			#if USE_SHAPE_LIGHT_TYPE_3
			SHAPE_LIGHT(3)
			#endif

			#include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/CombinedShapeLightShared.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _FOG_ON


			sampler2D _MainTex;
			sampler2D _MaskTex;
			sampler2D _NormalMap;
			CBUFFER_START( UnityPerMaterial )
			float4 _MainTex_ST;
			float4 _ForegroundColor;
			float4 _BackgroundColor;
			float4 _MaskTex_ST;
			float4 _NormalMap_ST;
			float2 _ForegroundRange;
			float2 _BackgroundRange;
			float _GlowSpeed;
			float _GlowScale;
			float _GlowBlend;
			CBUFFER_END


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 texCoord0 : TEXCOORD0;
				float4 color : TEXCOORD1;
				float4 screenPosition : TEXCOORD2;
				float4 ase_color : COLOR;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if ETC1_EXTERNAL_ALPHA
				TEXTURE2D(_AlphaTex); SAMPLER(sampler_AlphaTex);
				float _EnableAlphaTexture;
			#endif

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				o.ase_texcoord3.xyz = ase_worldPos;
				
				o.ase_color = v.color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.normal = v.normal;
				v.tangent.xyz = v.tangent.xyz;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

				o.texCoord0 = v.uv0;
				o.color = v.color;
				o.clipPos = vertexInput.positionCS;
				o.screenPosition = ComputeScreenPos( o.clipPos, _ProjectionParams.x );
				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float2 uv_MainTex = IN.texCoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 temp_output_25_0 = ( IN.ase_color * tex2D( _MainTex, uv_MainTex ) );
				float3 ase_worldPos = IN.ase_texcoord3.xyz;
				float2 appendResult5_g13 = (float2(ase_worldPos.x , ase_worldPos.y));
				float mulTime4_g13 = _TimeParameters.x * _GlowSpeed;
				float simplePerlin2D9_g13 = snoise( ( appendResult5_g13 + mulTime4_g13 )*_GlowScale );
				float3 temp_cast_0 = (simplePerlin2D9_g13).xxx;
				float3 blendOpSrc10_g13 = temp_cast_0;
				float3 blendOpDest10_g13 = temp_output_25_0.rgb;
				float3 lerpBlendMode10_g13 = lerp(blendOpDest10_g13,(( blendOpDest10_g13 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest10_g13 ) * ( 1.0 - blendOpSrc10_g13 ) ) : ( 2.0 * blendOpDest10_g13 * blendOpSrc10_g13 ) ),_GlowBlend);
				float3 break179 = ( saturate( lerpBlendMode10_g13 ));
				float4 appendResult102 = (float4(break179.x , break179.y , break179.z , temp_output_25_0.a));
				float4 temp_output_26_0_g14 = appendResult102;
				float4 blendOpSrc17_g14 = _ForegroundColor;
				float4 blendOpDest17_g14 = temp_output_26_0_g14;
				float clampResult10_g14 = clamp( ase_worldPos.z , _ForegroundRange.y , _ForegroundRange.x );
				float4 lerpBlendMode17_g14 = lerp(blendOpDest17_g14,( blendOpSrc17_g14 * blendOpDest17_g14 ),(1.0 + (clampResult10_g14 - _ForegroundRange.y) * (0.0 - 1.0) / (_ForegroundRange.x - _ForegroundRange.y)));
				float temp_output_3_0_g14 = step( _ForegroundRange.x , ase_worldPos.z );
				float clampResult6_g14 = clamp( ase_worldPos.z , _BackgroundRange.x , _BackgroundRange.y );
				float4 lerpResult4_g14 = lerp( temp_output_26_0_g14 , _BackgroundColor , ( 1.0 - pow( ( 1.0 - (0.0 + (clampResult6_g14 - _BackgroundRange.x) * (1.0 - 0.0) / (_BackgroundRange.y - _BackgroundRange.x)) ) , 2.0 ) ));
				float4 break23_g14 = ( ( ( saturate( lerpBlendMode17_g14 )) * ( 1.0 - temp_output_3_0_g14 ) ) + ( temp_output_3_0_g14 * lerpResult4_g14 ) );
				float4 appendResult24_g14 = (float4(break23_g14.r , break23_g14.g , break23_g14.b , temp_output_26_0_g14.a));
				#ifdef _FOG_ON
				float4 staticSwitch31 = appendResult24_g14;
				#else
				float4 staticSwitch31 = ( temp_output_25_0 * appendResult102 );
				#endif
				
				float2 uv_MaskTex = IN.texCoord0.xy * _MaskTex_ST.xy + _MaskTex_ST.zw;
				
				float2 uv_NormalMap = IN.texCoord0.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				
				float4 Color = staticSwitch31;
				float Mask = tex2D( _MaskTex, uv_MaskTex ).r;
				float3 Normal = tex2D( _NormalMap, uv_NormalMap ).rgb;

				#if ETC1_EXTERNAL_ALPHA
					float4 alpha = SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, IN.texCoord0.xy);
					Color.a = lerp ( Color.a, alpha.r, _EnableAlphaTexture);
				#endif
				
				Color *= IN.color;

				return CombinedShapeLightShared( Color, Mask, IN.screenPosition.xy / IN.screenPosition.w );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "Sprite Normal"
			Tags { "LightMode"="NormalsRendering" }
			
			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define ASE_SRP_VERSION 70503

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define SHADERPASS_SPRITENORMAL

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/NormalsRenderingShared.hlsl"
			
			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _FOG_ON


			sampler2D _MainTex;
			sampler2D _NormalMap;
			CBUFFER_START( UnityPerMaterial )
			float4 _MainTex_ST;
			float4 _ForegroundColor;
			float4 _BackgroundColor;
			float4 _MaskTex_ST;
			float4 _NormalMap_ST;
			float2 _ForegroundRange;
			float2 _BackgroundRange;
			float _GlowSpeed;
			float _GlowScale;
			float _GlowBlend;
			CBUFFER_END


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 texCoord0 : TEXCOORD0;
				float4 color : TEXCOORD1;
				float3 normalWS : TEXCOORD2;
				float4 tangentWS : TEXCOORD3;
				float3 bitangentWS : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput vert ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				o.ase_texcoord5.xyz = ase_worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord5.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.normal = v.normal;
				v.tangent.xyz = v.tangent.xyz;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);

				o.texCoord0 = v.uv0;
				o.color = v.color;
				o.clipPos = vertexInput.positionCS;

				float3 normalWS = TransformObjectToWorldNormal( v.normal );
				o.normalWS = NormalizeNormalPerVertex( normalWS );
				float4 tangentWS = float4( TransformObjectToWorldDir( v.tangent.xyz ), v.tangent.w );
				o.tangentWS = normalize( tangentWS );
				o.bitangentWS = cross( normalWS, tangentWS.xyz ) * tangentWS.w;
				return o;
			}

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float2 uv_MainTex = IN.texCoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 temp_output_25_0 = ( IN.color * tex2D( _MainTex, uv_MainTex ) );
				float3 ase_worldPos = IN.ase_texcoord5.xyz;
				float2 appendResult5_g13 = (float2(ase_worldPos.x , ase_worldPos.y));
				float mulTime4_g13 = _TimeParameters.x * _GlowSpeed;
				float simplePerlin2D9_g13 = snoise( ( appendResult5_g13 + mulTime4_g13 )*_GlowScale );
				float3 temp_cast_0 = (simplePerlin2D9_g13).xxx;
				float3 blendOpSrc10_g13 = temp_cast_0;
				float3 blendOpDest10_g13 = temp_output_25_0.rgb;
				float3 lerpBlendMode10_g13 = lerp(blendOpDest10_g13,(( blendOpDest10_g13 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest10_g13 ) * ( 1.0 - blendOpSrc10_g13 ) ) : ( 2.0 * blendOpDest10_g13 * blendOpSrc10_g13 ) ),_GlowBlend);
				float3 break179 = ( saturate( lerpBlendMode10_g13 ));
				float4 appendResult102 = (float4(break179.x , break179.y , break179.z , temp_output_25_0.a));
				float4 temp_output_26_0_g14 = appendResult102;
				float4 blendOpSrc17_g14 = _ForegroundColor;
				float4 blendOpDest17_g14 = temp_output_26_0_g14;
				float clampResult10_g14 = clamp( ase_worldPos.z , _ForegroundRange.y , _ForegroundRange.x );
				float4 lerpBlendMode17_g14 = lerp(blendOpDest17_g14,( blendOpSrc17_g14 * blendOpDest17_g14 ),(1.0 + (clampResult10_g14 - _ForegroundRange.y) * (0.0 - 1.0) / (_ForegroundRange.x - _ForegroundRange.y)));
				float temp_output_3_0_g14 = step( _ForegroundRange.x , ase_worldPos.z );
				float clampResult6_g14 = clamp( ase_worldPos.z , _BackgroundRange.x , _BackgroundRange.y );
				float4 lerpResult4_g14 = lerp( temp_output_26_0_g14 , _BackgroundColor , ( 1.0 - pow( ( 1.0 - (0.0 + (clampResult6_g14 - _BackgroundRange.x) * (1.0 - 0.0) / (_BackgroundRange.y - _BackgroundRange.x)) ) , 2.0 ) ));
				float4 break23_g14 = ( ( ( saturate( lerpBlendMode17_g14 )) * ( 1.0 - temp_output_3_0_g14 ) ) + ( temp_output_3_0_g14 * lerpResult4_g14 ) );
				float4 appendResult24_g14 = (float4(break23_g14.r , break23_g14.g , break23_g14.b , temp_output_26_0_g14.a));
				#ifdef _FOG_ON
				float4 staticSwitch31 = appendResult24_g14;
				#else
				float4 staticSwitch31 = ( temp_output_25_0 * appendResult102 );
				#endif
				
				float2 uv_NormalMap = IN.texCoord0.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				
				float4 Color = staticSwitch31;
				float3 Normal = tex2D( _NormalMap, uv_NormalMap ).rgb;
				
				Color *= IN.color;

				return NormalsRenderingShared( Color, Normal, IN.tangentWS.xyz, IN.bitangentWS, IN.normalWS);
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "Sprite Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#define ASE_SRP_VERSION 70503

			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ ETC1_EXTERNAL_ALPHA

			#define _SURFACE_TYPE_TRANSPARENT 1
			#define SHADERPASS_SPRITEFORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#define ASE_NEEDS_FRAG_COLOR
			#pragma shader_feature_local _FOG_ON


			sampler2D _MainTex;
			CBUFFER_START( UnityPerMaterial )
			float4 _MainTex_ST;
			float4 _ForegroundColor;
			float4 _BackgroundColor;
			float4 _MaskTex_ST;
			float4 _NormalMap_ST;
			float2 _ForegroundRange;
			float2 _BackgroundRange;
			float _GlowSpeed;
			float _GlowScale;
			float _GlowBlend;
			CBUFFER_END


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 texCoord0 : TEXCOORD0;
				float4 color : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if ETC1_EXTERNAL_ALPHA
				TEXTURE2D( _AlphaTex ); SAMPLER( sampler_AlphaTex );
				float _EnableAlphaTexture;
			#endif

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			

			VertexOutput vert( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float3 ase_worldPos = mul(GetObjectToWorldMatrix(), v.vertex).xyz;
				o.ase_texcoord2.xyz = ase_worldPos;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord2.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.normal = v.normal;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( v.vertex.xyz );

				o.texCoord0 = v.uv0;
				o.color = v.color;
				o.clipPos = vertexInput.positionCS;

				return o;
			}

			half4 frag( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				float2 uv_MainTex = IN.texCoord0.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 temp_output_25_0 = ( IN.color * tex2D( _MainTex, uv_MainTex ) );
				float3 ase_worldPos = IN.ase_texcoord2.xyz;
				float2 appendResult5_g13 = (float2(ase_worldPos.x , ase_worldPos.y));
				float mulTime4_g13 = _TimeParameters.x * _GlowSpeed;
				float simplePerlin2D9_g13 = snoise( ( appendResult5_g13 + mulTime4_g13 )*_GlowScale );
				float3 temp_cast_0 = (simplePerlin2D9_g13).xxx;
				float3 blendOpSrc10_g13 = temp_cast_0;
				float3 blendOpDest10_g13 = temp_output_25_0.rgb;
				float3 lerpBlendMode10_g13 = lerp(blendOpDest10_g13,(( blendOpDest10_g13 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest10_g13 ) * ( 1.0 - blendOpSrc10_g13 ) ) : ( 2.0 * blendOpDest10_g13 * blendOpSrc10_g13 ) ),_GlowBlend);
				float3 break179 = ( saturate( lerpBlendMode10_g13 ));
				float4 appendResult102 = (float4(break179.x , break179.y , break179.z , temp_output_25_0.a));
				float4 temp_output_26_0_g14 = appendResult102;
				float4 blendOpSrc17_g14 = _ForegroundColor;
				float4 blendOpDest17_g14 = temp_output_26_0_g14;
				float clampResult10_g14 = clamp( ase_worldPos.z , _ForegroundRange.y , _ForegroundRange.x );
				float4 lerpBlendMode17_g14 = lerp(blendOpDest17_g14,( blendOpSrc17_g14 * blendOpDest17_g14 ),(1.0 + (clampResult10_g14 - _ForegroundRange.y) * (0.0 - 1.0) / (_ForegroundRange.x - _ForegroundRange.y)));
				float temp_output_3_0_g14 = step( _ForegroundRange.x , ase_worldPos.z );
				float clampResult6_g14 = clamp( ase_worldPos.z , _BackgroundRange.x , _BackgroundRange.y );
				float4 lerpResult4_g14 = lerp( temp_output_26_0_g14 , _BackgroundColor , ( 1.0 - pow( ( 1.0 - (0.0 + (clampResult6_g14 - _BackgroundRange.x) * (1.0 - 0.0) / (_BackgroundRange.y - _BackgroundRange.x)) ) , 2.0 ) ));
				float4 break23_g14 = ( ( ( saturate( lerpBlendMode17_g14 )) * ( 1.0 - temp_output_3_0_g14 ) ) + ( temp_output_3_0_g14 * lerpResult4_g14 ) );
				float4 appendResult24_g14 = (float4(break23_g14.r , break23_g14.g , break23_g14.b , temp_output_26_0_g14.a));
				#ifdef _FOG_ON
				float4 staticSwitch31 = appendResult24_g14;
				#else
				float4 staticSwitch31 = ( temp_output_25_0 * appendResult102 );
				#endif
				
				float4 Color = staticSwitch31;

				#if ETC1_EXTERNAL_ALPHA
					float4 alpha = SAMPLE_TEXTURE2D( _AlphaTex, sampler_AlphaTex, IN.texCoord0.xy );
					Color.a = lerp( Color.a, alpha.r, _EnableAlphaTexture );
				#endif

				Color *= IN.color;

				return Color;
			}

			ENDHLSL
		}
		
	}
	CustomEditor "NotSlot.HandPainted2D.Editor.SpriteShaderInspector"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18900
0;30;871;586;-65.75262;-166.5232;2.236134;True;False
Node;AmplifyShaderEditor.TexturePropertyNode;4;-265.8542,699.8333;Inherit;True;Property;_MainTex;Diffuse;0;0;Create;False;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;5;-21.91676,701.5972;Inherit;True;Property;_TextureSample0;Texture Sample 0;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;12;33.89336,490.3411;Inherit;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;339.9156,589.4553;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.FunctionNode;191;524.3605,672.3796;Inherit;False;GlowZones;1;;13;fd2471ad38c944b778b5fb7882d6940a;0;1;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.BreakToComponentsNode;179;775.3879,671.0487;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.BreakToComponentsNode;99;520.4692,796.6199;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.DynamicAppendNode;102;960.487,671.1463;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.FunctionNode;192;1270.47,662.7758;Inherit;False;Fog;5;;14;0af4f8e64e08f404a8159464b51699d5;0;1;26;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;90;1095.523,591.7413;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;19;1153.969,979.7792;Inherit;True;Property;_NormalMap;Normal Map;11;0;Create;False;0;0;0;False;0;False;None;None;False;bump;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;18;1151.042,758.8079;Inherit;True;Property;_MaskTex;Mask;10;0;Create;False;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.StaticSwitch;31;1519.23,587.8777;Inherit;False;Property;_Fog;Fog;12;0;Create;True;0;0;0;False;0;False;0;1;1;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;9;1399.775,767.9797;Inherit;True;Property;_TextureSample1;Texture Sample 1;1;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;10;1402.716,981.408;Inherit;True;Property;_TextureSample2;Texture Sample 2;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;17;1063.237,17.93402;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;12;New Amplify Shader;199187dac283dbe4a8cb1ea611d70c58;True;Sprite Forward;0;2;Sprite Forward;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;0;False;True;2;5;False;-1;10;False;-1;3;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;16;1063.237,17.93402;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;12;New Amplify Shader;199187dac283dbe4a8cb1ea611d70c58;True;Sprite Normal;0;1;Sprite Normal;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;0;False;True;2;5;False;-1;10;False;-1;3;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=NormalsRendering;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;15;1808.78,752.7532;Float;False;True;-1;2;NotSlot.HandPainted2D.Editor.SpriteShaderInspector;0;12;Hand Painted 2D/Sprite Glow Zones;199187dac283dbe4a8cb1ea611d70c58;True;Sprite Lit;0;0;Sprite Lit;6;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;PreviewType=Plane;True;0;0;False;True;2;5;False;-1;10;False;-1;3;1;False;-1;10;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;2;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=Universal2D;False;0;Hidden/InternalErrorShader;0;0;Standard;1;Vertex Position;1;0;3;True;True;True;False;;False;0
WireConnection;5;0;4;0
WireConnection;5;7;4;1
WireConnection;25;0;12;0
WireConnection;25;1;5;0
WireConnection;191;1;25;0
WireConnection;179;0;191;0
WireConnection;99;0;25;0
WireConnection;102;0;179;0
WireConnection;102;1;179;1
WireConnection;102;2;179;2
WireConnection;102;3;99;3
WireConnection;192;26;102;0
WireConnection;90;0;25;0
WireConnection;90;1;102;0
WireConnection;31;1;90;0
WireConnection;31;0;192;0
WireConnection;9;0;18;0
WireConnection;9;7;18;1
WireConnection;10;0;19;0
WireConnection;10;7;19;1
WireConnection;15;1;31;0
WireConnection;15;2;9;0
WireConnection;15;3;10;0
ASEEND*/
//CHKSM=4106B40154B2E49C1D7F23BA81C73B068197881C