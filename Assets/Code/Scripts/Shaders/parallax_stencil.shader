Shader "Ozeg/parallax_stencil"
{
    Properties
    {
        [HDR]_Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RCSMTex ("RCSM (Normal.xy/Cone/Height)", 2D) = "white" {}
        _SurfaceTex ("Surface (Metallic/Smoothness/Occlusion)", 2D) = "white" {}
        // _EmissionTex ("Emission Texture", 2D) = "black" {}
        // [HDR]_EmissionColor ("Emission Color", Color) = (1,1,1,1)
        // _EmissionOffset ("Emission Offset", Float) = 0
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Occlusion ("Occlusion", Float) = 0.0
        _Offset ("Offset", Range(0,1)) = 0
        _Depth ("Depth", Float) = 1.
        _NormalDepth ("Normal Depth", Float) = 1.
        _ConeSteps ("Cone Iteration",Int) = 5
        _BinarySteps ("Binary Iteration",Int) = 5
        _Bias ("Bias", Float) = 0.
        [Toggle(ENABLE_SHADOWS)] _Shadows ("Receive Character Shadows", Float) = 0
        [Hidden]_ShadowTex("Shadow texture", 2D) = "white" {}
        [Hidden]_ShadowDepth ("Shadow Depth", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry+1" "ForceNoShadowCasting"="True" }        LOD 200

        CGPROGRAM
        #pragma surface surf Standard fullforwardshadows vertex:vert decal:blend
        #pragma target 3.5
        #pragma multi_compile __ ENABLE_SHADOWS
        #include "UnityCG.cginc"

        sampler2D _MainTex, _RCSMTex, _SurfaceTex;
        float4 _MainTex_ST, _RCSMTex_ST;
        float _Depth;

        struct Input
        {
            float2 texcoord;
            float3 ray;
            float3 lightRay;
            float3 worldPos;
            float3 worldRay;
        };

        void vert (inout appdata_full v, out Input o) 
        {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            float3x3 objectToTangent = float3x3( v.tangent.xyz, cross(v.normal,v.tangent.xyz)*v.tangent.w, v.normal );
            o.ray = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
            o.ray /= o.ray.z;
            o.ray.xy *= _RCSMTex_ST.xy*_Depth;
            o.texcoord = (v.texcoord-.5)*_RCSMTex_ST.xy+_RCSMTex_ST.zw+.5;
            o.lightRay = mul(objectToTangent, ObjSpaceLightDir(v.vertex));
            o.lightRay.z = max(0,o.lightRay.z);
            o.lightRay.xy *= _RCSMTex_ST.xy*_Depth;
            // o.worldPos = mul(unity_ObjectToWorld,v.vertex);
            o.worldRay = WorldSpaceViewDir(v.vertex).xyz;
        }
        fixed4 _Color, _EmissionColor;
        float _Glossiness, _Metallic, _Occlusion, _NormalDepth, _Bias, _Offset;
    #ifdef ENABLE_SHADOWS
        float _ShadowDepth;
    #endif
        uint _ConeSteps, _BinarySteps, _LightSteps;
    #ifdef ENABLE_SHADOWS
        sampler2D _ShadowTex;
        uniform float _isShadow;
        uniform float4 _sc[6];
        uniform float4 _sm[6];
    #endif
        UNITY_INSTANCING_BUFFER_START(Props)
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input i, inout SurfaceOutputStandard o)
        {
            _Bias = max(0,_Bias);
            float3 ray = i.ray;
            ray.xy *= -.25;
            float rayRatio = length(ray.xy);
            float3 conestepPos = float3(i.texcoord,0);
            for(uint ci=0; ci<_ConeSteps; ci++)
            {
                float4 tex = tex2D(_RCSMTex, conestepPos.xy);
                tex.w += _Offset;
                float coneRatio = tex.z;
                float height = saturate(1.-tex.w-conestepPos.z);
                float d = tex.z*height/(rayRatio+coneRatio+_Bias);
                conestepPos += ray*d;
            }

            float3 searchRange = .5*ray*conestepPos.z;
            float3 searchPos = float3(i.texcoord,0)+searchRange;
            for(uint bi=0; bi<_BinarySteps; bi++)
            {
                float4 tex = tex2D(_RCSMTex, searchPos.xy);
                tex.w += _Offset;
                searchRange*=.5;
                searchPos+=((searchPos.z<1.-tex.w)*2.-1.)*searchRange;
            }
            float4 rcsmTex = tex2D(_RCSMTex, searchPos.xy);
            rcsmTex.xy = rcsmTex.xy*2.-1.;
            rcsmTex.xy*=_NormalDepth;
            float3 normal = float3(rcsmTex.xy,1.-sqrt(rcsmTex.x*rcsmTex.x+rcsmTex.y*rcsmTex.y));            
            float3 normalFactor = float3(_RCSMTex_ST.xy,1);
            normal.xy*=(searchPos.xy>0.)*2.-1.;
            // normal.y*=(searchPos.y>0.)*2.-1.;
            normal = normalize(normal*normalFactor);

            fixed4 c = tex2D (_MainTex, searchPos.xy);
            fixed4 surf = tex2D (_SurfaceTex, searchPos.xy);
    #ifdef ENABLE_SHADOWS
            // float3 worldRay = i.worldRay;
            float3 worldPos = i.worldPos;
            worldPos += _ShadowDepth*i.worldRay/i.worldRay.y*(searchPos.z-.5);
            float s = 1.;
            for (int j = 0; j < 6; j++) s *= lerp(tex2D(_ShadowTex,mul(float2x2(_sm[j]),worldPos.xz-_sc[j].xz)+.5),1.,_sc[j].y);
            s = lerp(1., s, _isShadow);
    #endif
            // float emissionMask = tex2D(_EmissionTex, searchPos.xy*_EmissionTex_ST.xy+_EmissionTex_ST.zw).r;
            // o.Emission = emissionMask*_EmissionColor;
            o.Normal  = normal;
            o.Occlusion = 1.-_Occlusion*(1-surf.b);
            o.Albedo = c.rgb*lerp(_Color,1,surf.r*(1-_Color.a));
    #ifdef ENABLE_SHADOWS
            o.Albedo *=s*s;
    #endif
            // o.Albedo = surf;
            o.Metallic = _Metallic*surf.r;
            o.Smoothness = _Glossiness*surf.g;
            o.Alpha = smoothstep(0,.025+_Offset*.25,searchPos.z);
        }
        ENDCG
    }
    FallBack "Diffuse"
}
