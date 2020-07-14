Shader "Custom/CelRenderFull"
{
	Properties
	{
		_MainTex ("MainTex", 2D) = "white" {}
        _IlmTex ("IlmTex R-高光范围 G-AO B-高光强度", 2D) = "white" {}
		_NormalTex("Normal",2D) = "bump"{}

		[Space(20)]
		_MainColor("Main Color", Color) = (1,1,1)
		_ShadowColor ("Shadow Color", Color) = (0.7, 0.7, 0.7)
		_ShadowSmooth("Shadow Smooth", Range(0, 0.03)) = 0.002
		_ShadowRange ("Shadow Range", Range(0, 1)) = 0.6

		[Space(20)]
		[HDR]_SpecularColor("Specular Color", Color) = (1,1,1)
		_SpecularRange ("Specular Range",  Range(0, 1)) = 0.9
        _SpecularMulti ("Specular Multi", Range(0, 1)) = 0.4
		_SpecularGloss("Sprecular Gloss", Range(0.001, 8)) = 4
		//_Smoothness("Smoothness",Range(0.05,1)) = 0.5

	}

	SubShader
	{
		Pass
		{
			Tags { "LightMode"="ForwardBase" "RenderType" = "Transparent" "Queue" = "Transparent" }
            Zwrite Off
			Blend SrcAlpha OneMinusSrcAlpha

			CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex; 
			float4 _MainTex_ST;
            sampler2D _IlmTex; 
			float4 _IlmTex_ST;
			sampler2D _NormalTex;
			float4 _NormalTex_ST;

			half3 _MainColor;
			half3 _ShadowColor;
			half _ShadowSmooth;
			half _ShadowRange;
			
			half4 _SpecularColor;
			half _SpecularRange;
        	half _SpecularMulti;
			half _SpecularGloss;
			//float _Smoothness;

			struct a2v
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv[2] : TEXCOORD1;
				float3 normal : TEXCOORD3;	
				float3 worldPos : TEXCOORD4; 
			};
			
			v2f vert (a2v v)
			{
				v2f o = (v2f)0;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv[0] = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv[1] = TRANSFORM_TEX(v.uv, _NormalTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				half4 col = 0;
				half4 mainTex = tex2D (_MainTex, i.uv[0]);
				half4 ilmTex = tex2D (_IlmTex, i.uv[0]);
				float3 nor = UnpackNormal(tex2D(_NormalTex, i.uv[1]));
				nor = normalize(i.normal + nor.xxy);
				half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				half3 worldNormal = normalize(i.normal);
				half3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				half3 diffuse = 0;
				half halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
				//halfLambert = step(halfLambert, ilmTex.g);
				half threshold = (halfLambert + ilmTex.g) * 0.5;
				half ramp = saturate(_ShadowRange  - threshold); 
				ramp =  smoothstep(0, _ShadowSmooth, ramp);
				diffuse = lerp(_MainColor, _ShadowColor, ramp);
				diffuse *= mainTex.rgb;

				half4 specular = 0;
				half3 halfDir = normalize(worldLightDir + viewDir);
				half NdotH = max(0, dot(nor, halfDir));
				half SpecularSize = pow(NdotH, _SpecularGloss);
				half specularMask = ilmTex.b;
				if (SpecularSize >= 1 - specularMask * _SpecularRange)
				{
					specular = _SpecularMulti * (ilmTex.r) * _SpecularColor;
				}
				//specular = pow(specular, _Smoothness * _Smoothness * 200);

				col.rgb = (diffuse + specular) * _LightColor0.rgb; 
                //col.a = lerp(mainTex.a, specular, specular.a);
                col.a = mainTex.a + specular;
				return col;
			}
			ENDCG
		}

	}
	FallBack Off
}