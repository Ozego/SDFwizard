Shader "Ozeg/Lit/RCSMLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RCSMTex ("Texture", 2D) = "white" {}
        _ConeSteps ("_ConeSteps",Int) = 16
        _BinarySteps ("_BinarySteps",Int) = 8
        _LightSteps ("_LightSteps",Int) = 8
        _Depth ("Depth", Float) = 1.
        _NormalDepth ("Normal Depth", Float) = 1.
        _Bias ("Bias", Float) = 0.
        _Shadow ("Shadow", Float) = 1.
        _AO ("Ambient Occlusion", Float) = 1.
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                UNITY_FOG_COORDS(0)
                float2 uv : TEXCOORD1;
                float3 ray : TEXCOORD2;
                float3 lightRay : TEXCOORD3;
            };


            float4 _RCSMTex_ST;
            float _Depth;
            v2f vert (appdata v)
            {
                _RCSMTex_ST.w+=_Time.y*.015;
                v2f o;
                float3x3 objectToTangent = float3x3( v.tangent.xyz, cross(v.normal,v.tangent.xyz)*v.tangent.w, v.normal );
                o.ray = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
                o.ray = o.ray/o.ray.z;
                o.ray.xy *= _RCSMTex_ST.xy*_Depth;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = (v.uv-.5)*_RCSMTex_ST.xy+_RCSMTex_ST.zw+.5;
                o.lightRay = mul(objectToTangent, ObjSpaceLightDir(v.vertex));
                o.lightRay.z = max(0,o.lightRay.z);
                o.lightRay.xy *= _RCSMTex_ST.xy*_Depth;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 _MainTex_ST;
            float _NormalDepth,_Bias,_Shadow,_AO;
            sampler2D _MainTex, _RCSMTex;
            uint _ConeSteps, _BinarySteps, _LightSteps;

            fixed4 frag (v2f i) : SV_Target
            {
                float3 ray = i.ray;
                ray.xy *= -.25;
                float rayRatio = length(ray.xy);
                float3 conestepPos = float3(i.uv,0.);
                for(uint ci=0; ci<_ConeSteps; ci++)
                {
                    float4 tex = tex2D(_RCSMTex, conestepPos.xy);
                    float coneRatio = tex.z;
                    float height = saturate(1.-tex.w-conestepPos.z);
                    float d = tex.z*height/(rayRatio+coneRatio+_Bias);
                    conestepPos += ray*d;
                }

                float3 searchRange = .5*ray*conestepPos.z;
                float3 searchPos = float3(i.uv,0.)+searchRange;
                for(uint bi=0; bi<_BinarySteps; bi++)
                {
                    float4 tex = tex2D(_RCSMTex, searchPos.xy);
                    searchRange*=.5;
                    searchPos+=((searchPos.z<1.-tex.w)*2.-1.)*searchRange;
                }
                float4 surf = tex2D(_RCSMTex, searchPos.xy);
                surf.xy = surf.xy*2.-1.;
                surf.xy*=_NormalDepth;

                float3 normal = float3(surf.xy,1.-sqrt(surf.x*surf.x+surf.y*surf.y));
                float3 normalFactor = float3(_RCSMTex_ST.xy,1);
                normal = normalize(normal*normalFactor);
                float3 lightRay = i.lightRay/i.lightRay.z;
                lightRay.xy*=-1;
                float lightRayRatio = length(lightRay.xy);
                float3 lightPos = searchPos-lightRay*searchPos.z;

                for(uint ci=0; ci<_LightSteps; ci++)
                {
                    float4 tex = tex2D(_RCSMTex, lightPos.xy);
                    float coneRatio = tex.z;
                    float height = saturate(1.-tex.w-lightPos.z);
                    float d = tex.z*height/(lightRayRatio+coneRatio+_Bias);
                    lightPos += lightRay*d;
                }
                float3 lightSearchRange = .5*lightRay*lightPos.z;
                float3 lightSearchPos = searchPos-lightRay*searchPos.z+lightSearchRange;
                for(uint bi=0; bi<_BinarySteps; bi++)
                {
                    float4 tex = tex2D(_RCSMTex, lightSearchPos.xy);
                    lightSearchRange*=.5;
                    lightSearchPos+=((lightSearchPos.z<1.-tex.w)*2.-1.)*lightSearchRange;
                }
                fixed4 col = 0.;
                col.rgb = saturate(1.5-searchPos.z*_AO)*tex2D(_MainTex, searchPos.xy*_MainTex_ST.xy+_MainTex_ST.zw).rgb;
                col.rgb *= dot(normal,normalize(i.lightRay));
                col.rgb -= distance(searchPos,lightSearchPos)*_Shadow;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
