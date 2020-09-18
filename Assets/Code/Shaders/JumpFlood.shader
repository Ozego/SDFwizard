Shader "Hidden/JumpFlood"
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
        #pragma multi_compile __ __REPEAT 

        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            half2 uv : TEXCOORD0;
        };

        struct v2f
        {
            half2 uv : TEXCOORD0;
            float4 vertex : SV_POSITION;
        };

        half4 _PixelParams;

        v2f vert (appdata v)
        {
            v2f o;
            o.vertex = UnityObjectToClipPos(v.vertex);
            o.uv = v.uv*_PixelParams.xy;
            return o;
        }
        
        sampler2D _MainTex;

        half4 texMain(half2 UV) 
        {
            return tex2D(_MainTex, (floor(UV)+.5)/_PixelParams.xy);
        }

        ENDCG

        Pass
        {
            CGPROGRAM
            half4 frag (v2f i) : SV_Target
            {
                half4 o = 0;
                half minDist = _PixelParams.z;
                for (half x=-1; x<=1; x++)
                {
                    for (half y=-1; y<=1; y++)
                    {
                        half2 offset = half2(x,y)*_PixelParams.xy/_PixelParams.w;
                        half4 s =  texMain(i.uv+offset);
                        half dist = length(offset);
                        if(s.a >.5 && dist<=minDist)
                        {
                            minDist = dist;
                            o.a = 1;
                            o.rg = i.uv+offset;
                        }
                    }
                }
                return o;
            }
            ENDCG
        }

        Pass
        {
            CGPROGRAM
            half4 frag (v2f i) : SV_Target
            {
                half4 o = tex2D(_MainTex,i.uv);
                o.rg=i.uv*_PixelParams.xy;
                half minDist = _PixelParams.z;
                for (half x = -1; x <= 1; x++)
                {
                    for (half y = -1; y <= 1; y++)
                    {
                        half2 offset = half2(x,y)*_PixelParams.xy/_PixelParams.w;
                        half4 s =  texMain(i.uv+offset);
                        half dist = _PixelParams.z;
                        #if defined(__REPEAT)
                        for (float distX=-1; distX<=1; distX++)
                        {
                            for (float distY=-1; distY<=1; distY++)
                            {
                                dist = (min(dist,distance(i.uv,s.rg+float2(distX,distY)*_PixelParams.xy)));
                            }
                        }
                        #else
                        dist = distance(i.uv,s.rg);
                        #endif
                        if(s.a >0 && dist<minDist)
                        {
                            minDist = dist;
                            o.a = 1;
                            o.rg = s.rg;
                            o.b = dist;
                        }
                    }
                }
                return o;
            }
            ENDCG
        }
    }
}
