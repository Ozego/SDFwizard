Shader "Hidden/RCSMWizard/JumpFlood"
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
        //0 clear
        Pass
        {
            CGPROGRAM 
            fixed4 frag () : SV_Target
            {
                return fixed4(1,1,1,1);
            }
            ENDCG
        }
        //1 step
        Pass
        {
            CGPROGRAM
            float _Steps;
            float coneCast(float2 start, float2 end)
            {
                float3 src = float3(start,0.);
                float3 dst = float3(end,1.);
                dst.z = 1.-tex(_MainTex, dst.xy).a;
                float3 ray = dst-src;
                ray /= ray.z;
                ray *= 1.-dst.z;
                ray /= _Steps;
                float3 rayPos = dst + ray;
                for(float s=1.; s<_Steps; s++)
                {
                    float currentDepth = 1.-tex(_MainTex,rayPos.xy).a;
                    rayPos += ray * (currentDepth <= rayPos.z);
                }
                float srcDepth = 1.-tex(_MainTex,src.xy).a;
                // rayPos.z = min(rayPos.z,.9);
                float coneRatio = (rayPos.z>=srcDepth)?1.:length((rayPos.xy-start)/_PixelParams.xy)/(srcDepth-rayPos.z);
                return coneRatio;
            }
            half4 frag (v2f i) : SV_Target
            {
                half4 o = tex(_MainTex,i.uv);
                for (half x = -1; x <= 1; x++)
                {
                    for (half y = -1; y <= 1; y++)
                    {
                        half2 offset = half2(x,y)*_PixelParams.xy/_PixelParams.w;
                        half4 s = tex(_MainTex,i.uv+offset);
                        half cone = coneCast(i.uv,s.rg);
                        if(cone<o.b)
                        {
                            o.rg = s.rg;
                            o.b = cone;
                        }
                    }
                }
                // o = tex(_MainTex,i.uv);
                return o;
            }
            ENDCG
        }
        //2 in
        Pass 
        {
            CGPROGRAM
            half4 frag(v2f i) : SV_Target
            {
                half4 o = 0.;
                o.rg = i.uv;
                o.b = 1;
                o.a = tex(_MainTex,i.uv).r;
                return o;
            }
            ENDCG
        }
        //3 out
        Pass 
        {
            CGPROGRAM
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 o = tex(_MainTex,i.uv);
                return fixed4(o.bbb,1);
            }
            ENDCG
        }
    }
}
