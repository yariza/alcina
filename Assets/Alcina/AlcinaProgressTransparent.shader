﻿Shader "Custom/AlcinaProgressTransparent" {
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

	_Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

		_Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
		_GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
		[Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel("Smoothness texture channel", Float) = 0

		[Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
		_MetallicGlossMap("Metallic", 2D) = "white" {}

	[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

		_BumpScale("Scale", Float) = 1.0
		_BumpMap("Normal Map", 2D) = "bump" {}

	_Parallax("Height Scale", Range(0.005, 0.08)) = 0.02
		_ParallaxMap("Height Map", 2D) = "black" {}

	_OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
		_OcclusionMap("Occlusion", 2D) = "white" {}

	_EmissionColor("Color", Color) = (0,0,0)
		_EmissionMap("Emission", 2D) = "white" {}

	_DetailMask("Detail Mask", 2D) = "white" {}

	_DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
	_DetailNormalMapScale("Scale", Float) = 1.0
		_DetailNormalMap("Normal Map", 2D) = "bump" {}

	_ProgressTex("Progress Texture", 2D) = "white" {}
	_ProgressLow("Progress Low", Range(0.0, 1.0)) = 0.0
		_ProgressHigh("Progress High", Range(0.0, 1.0)) = 1.0
		_Progress("Current Progress", Float) = 0.0
		_ProgressCutoff("Progress Cutoff", Range(0.0, 1.0)) = 0.5
		_ProgressBase("Progress Base", Range(0.0, 1.0)) = 0.0
		_ProgressAmplitude("Progress Amplitude", Range(0.0, 1.0)) = 1.0
		_ProgressDecay("Progress Decay", Range(0.0, 10.0)) = 1.0

		_EmissionAlpha("Emission Alpha", Range(0, 1)) = 0.0
		[ToggleOff] _EmissionBypass("Emission Bypass", Float) = 0.0
		
		[Enum(UV0,0,UV1,1)] _UVSec("UV Set for secondary textures", Float) = 0


			// Blending state
			[HideInInspector] _Mode("__mode", Float) = 0.0
			[HideInInspector] _SrcBlend("__src", Float) = 1.0
			[HideInInspector] _DstBlend("__dst", Float) = 0.0
			[HideInInspector] _ZWrite("__zw", Float) = 1.0
	}

		SubShader{
			Tags { "RenderType" = "Transparent" }
			LOD 200
			ZTest On
			ZWrite On

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows alpha:fade

		// Use shader model 3.0 target, to get nicer looking lighting
#pragma target 3.0

			sampler2D _MainTex;
		sampler2D _BumpMap;
		sampler2D _MetallicGlossMap;
		sampler2D _EmissionMap;
		sampler2D _OcclusionMap;

		fixed _GlossMapScale;
		fixed4 _EmissionColor;
		half _OcclusionStrength;

		struct Input {
			float2 uv_MainTex;
			float2 uv_MetallicGlossMap;
			float2 uv_BumpMap;
			float2 uv_EmissionMap;
			float2 uv_ProgressTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;

		sampler2D _ProgressTex;
		float _ProgressLow;
		float _ProgressHigh;
		float _Progress;
		float _ProgressCutoff;
		float _ProgressBase;
		float _ProgressAmplitude;
		float _ProgressDecay;

		float _EmissionAlpha;
		float _EmissionBypass;

		void surf(Input IN, inout SurfaceOutputStandard o) {
			// Albedo comes from a texture tinted by color
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap));
			fixed4 e = tex2D(_EmissionMap, IN.uv_EmissionMap) * _EmissionColor;

			fixed progress = tex2D(_ProgressTex, IN.uv_ProgressTex).r;
			progress = (progress + _ProgressCutoff) * (_ProgressHigh - _ProgressLow) + _ProgressLow;
			fixed cur = fmod(fmod(progress - _Progress, _ProgressCutoff) + 1.0, 1.0);

			fixed eScale = _ProgressBase;
			eScale += _ProgressAmplitude * saturate(1.0 - (1.0 - cur) * _ProgressDecay);

			o.Emission = e.rgb * eScale;
			//o.Emission = tex2D(_ProgressTex, IN.uv_ProgressTex);
			half occ = tex2D(_OcclusionMap, IN.uv_MainTex).r * _OcclusionStrength;
			o.Occlusion = occ;
			// Metallic and smoothness come from slider variables
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness * tex2D(_MetallicGlossMap, IN.uv_MetallicGlossMap).a * _GlossMapScale;
			if (_EmissionBypass > 0.5) {
				o.Alpha = (1 - _EmissionAlpha) + max(o.Emission.r, max(o.Emission.g, o.Emission.b)) / 2;
			}
			else {
				o.Alpha = saturate(c.a * saturate(1 - _EmissionAlpha + saturate(max(o.Emission.r, max(o.Emission.g, o.Emission.b))))) / 2;
			}
		}
		ENDCG
	}
	FallBack "Diffuse"
}
