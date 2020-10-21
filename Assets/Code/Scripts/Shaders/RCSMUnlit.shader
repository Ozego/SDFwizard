Shader "Ozeg/Unlit/RCSMUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _RCSMTex ("Texture", 2D) = "white" {}
        _ConeSteps ("_ConeSteps",Int) = 16
        _BinarySteps ("_BinarySteps",Int) = 8
        _Depth ("Depth", Float) = .25
        _Bias ("Bias", Float) = 0
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
            };


            float4 _RCSMTex_ST;
            v2f vert (appdata v)
            {
                v2f o;
                float3x3 objectToTangent = float3x3( v.tangent.xyz, cross(v.normal,v.tangent.xyz)*v.tangent.w, v.normal );
                o.ray = mul(objectToTangent, ObjSpaceViewDir(v.vertex));
                o.ray = o.ray/o.ray.z;
                o.ray.xy *= _RCSMTex_ST.xy;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv*_RCSMTex_ST.xy+_RCSMTex_ST.zw;

                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float4 _MainTex_ST;
            float _Bias, _Depth;
            sampler2D _MainTex, _RCSMTex;
            uint _ConeSteps, _BinarySteps;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0.;
                float3 ray = i.ray;
                ray.xy *= -_Depth;
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
                
                col.rgb = saturate(1.5-searchPos.z)*tex2D(_MainTex, searchPos.xy*_MainTex_ST.xy+_MainTex_ST.zw).rgb;

                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
