Shader "Hidden/RCSMWizard/PerPixel"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        
        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float2 uv : TEXCOORD0;
        };

        struct v2f
        {
            float2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        float4 _PixelParams;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv*_PixelParams.xy;
            return o;
        }

        sampler2D _MainTex;

        fixed4 tex(sampler2D tex, float2 UV) 
        {
            float4 U = float4(UV/_PixelParams.xy,0,0);
            return tex2Dlod(tex, U);
        }

        ENDCG
        Pass
        {
            CGPROGRAM //0   initialize
            fixed4 frag () : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
        Pass
        {
            CGPROGRAM //1   step cone
            sampler2D _BufferTex;
            float _Steps;
            fixed4 frag (v2f i) : SV_Target
            {
                float3 src = float3(i.uv,0.);
                float3 dst = float3(i.uv+_PixelParams.zw,1.);
                dst.z = 1.-tex(_MainTex, dst.xy).r;
                float3 ray = dst-src;
                ray /= ray.z;
                ray *= 1.-dst.z;
                ray /= _Steps;
                float3 rayPos = dst + ray;
                for(float s=1.; s<_Steps; s++)
                {
                    float currentDepth = 1.-tex(_MainTex,rayPos.xy).r;
                    rayPos += ray * (currentDepth <= rayPos.z);
                }
                float srcDepth = 1.-tex(_MainTex,src.xy).r;
                float coneRatio = (rayPos.z>=srcDepth)?1.:length((rayPos.xy-i.uv)/_PixelParams.xy)/(srcDepth-rayPos.z);
                float bestRatio = min(coneRatio,tex(_BufferTex,i.uv).r);
                return fixed4(bestRatio,bestRatio,bestRatio,1);
            }
            ENDCG
        }
    }
}
