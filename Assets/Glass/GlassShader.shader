Shader "Character/GlassShader"
{
	Properties
	{
		_Color("Color",color) = (1,1,1,1)
		_TColor("Top Color", Color) = (1,1,1,1)// top gradient, light white
		_BottomColor("Bottom Color", Color) = (0.23,0,0.95,1)// bottom gradient, blue
		_SpecColor("Specular Color",color) = (1,1,1,1)
		_Offset("Gradient Offset", Range(-4,4)) = 0 //  rim brightness
		_Fresnel("Fresnel",Range(0,1)) = 0.5
		_Smoothness("Smoothness",Range(0.05,1)) = 0.5
		_MainTex("Texture", 2D) = "white" {}
		_NormalTex("Normal",2D) = "bump"{}
		_Reflect("Reflect",cube) = ""{}
		//_Alphaintensity("Alphaintensity", Range(0,1))=0.5
		//_ZWriteCutout("Zwriterange", range(0,1)) = 0
	}
		SubShader
	{
		Tags { "RenderType" = "Transparent"
		"Queue" = "Transparent"}
		Pass
		{

			Zwrite On
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fog

			#include "UnityCG.cginc"

			//fixed _Alphaintensity;
			//fixed _ZWriteCutout;
			
			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				UNITY_FOG_COORDS(0)
				float2 uv[2] : TEXCOORD1;
				float3 normal : TEXCOORD3;
				float4 wPos : TEXCOORD4;
			};
			uniform fixed4 _Color;
			float _Offset;
			float4 _TColor;
			float4 _BottomColor;
			uniform fixed4 _SpecColor;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform sampler2D _NormalTex;
			uniform float4 _NormalTex_ST;
			uniform float _Fresnel;
			uniform samplerCUBE _Reflect;
			uniform float _Smoothness;
			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv[0] = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv[1] = TRANSFORM_TEX(v.uv, _NormalTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float4 tex = tex2D(_MainTex, i.uv[0]);
				float3 nor = UnpackNormal(tex2D(_NormalTex, i.uv[1]));
				nor = normalize(i.normal + nor.xxy);
				float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos);
				float3 lightDir = normalize(UnityWorldSpaceLightDir(i.wPos));
				float3 localPos = (i.wPos - mul(unity_ObjectToWorld, float4(0, 0, 0, 1)).xyz);
				float spec = max(0, dot(nor, normalize(viewDir + lightDir)));
				spec = pow(spec, _Smoothness * _Smoothness * 200);
				spec *= tex.a;
				float rim = 1 - pow(max(0,dot(nor,viewDir)), _Fresnel * 6);
				rim *= tex.a;
				fixed4 refl = texCUBE(_Reflect, -reflect(viewDir,nor));
				fixed4 col = tex*_Color;
				col.rgb += _SpecColor * spec;
				col.rgb += rim *refl.rgb;
				col.rgb = col.rgb * lerp(_BottomColor, _TColor, saturate(localPos.y + _Offset ));
				col.a = tex.a + spec;
				//col.a = max(rim, max(spec, col.a));
				//col.a = col.a + spec;
				UNITY_APPLY_FOG(i.fogCoord, col);
				//fixed alpha = col.a * _Alphaintensity;
				//clip(alpha - _ZWriteCutout);
				//smoothstep(0,1,(alpha - _ZWriteCutout));
				return col;
			}
			ENDCG
		}
	}
}
