Shader "Hidden/SDFWizard/JumpFlood"
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

        half4 tex(sampler2D tex, half2 UV) 
        {
            #ifdef __REPEAT
                UV = (UV+_PixelParams.xy)%_PixelParams.xy;
            #endif
            return tex2Dlod(tex, float4((floor(UV)+.5)/_PixelParams.xy,0.,0.));
        }
        half4 texMain(half2 UV) 
        {
            return tex(_MainTex, UV);
        }

        ENDCG
        //0 mask2flood
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
        //1 floodstep
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
        //2 return texture
        Pass
        {
            CGPROGRAM
            #pragma multi_compile __MODE_DIST __MODE_UV __MODE_UV_CONTOUR __MODE_RGB_CONTOUR __MODE_RGB_DIST __MODE_RGB
            float _Distance;
            sampler2D _EndoTex, _ExoTex;
            fixed4 frag (v2f i) : SV_Target
            {
                half4 endo = tex(_EndoTex,i.uv);
                half4 exo = tex(_ExoTex,i.uv);
                exo.rg /= _PixelParams.xy;
                exo.rg += 1;
                exo.rg %= 1;
                half4 o = exo;
                o.b -= endo.b;
                float maxDim =max(_PixelParams.x,_PixelParams.y);
                o.b /= _Distance;
                o.b =.5-o.b;
                half4 mTex = tex2D(_MainTex,exo.rg);
            #if defined(__MODE_DIST)
                o.rgb=o.b;
                o.a=1;
            #elif defined(__MODE_UV)
                o.a=1;
            #elif defined(__MODE_UV_CONTOUR)
                endo.rg /= _PixelParams.xy;
                endo.rg += 1;
                endo.rg %= 1;
                if(o.b>.5)o.rg=endo.rg;
            #elif defined(__MODE_RGB_CONTOUR)
                endo.rg /= _PixelParams.xy;
                endo.rg += 1;
                endo.rg %= 1;
                if(o.b>.5)o.rg=endo.rg;
                mTex = tex2D(_MainTex,o.rg);
                o.a=o.b;
                o.rgb=mTex.rgb;
            #elif defined(__MODE_RGB_DIST)
                o.a=o.b;
                o.rgb=mTex.rgb;
            #elif defined(__MODE_RGB)
                o.rgb=mTex.rgb;
                o.a=texMain(i.uv).a;
            #endif
                return (fixed4)o;
            }
            ENDCG
        }
        //3 prep texture
        Pass
        {
            CGPROGRAM
            float _Treshold;
            #pragma multi_compile __RED __GREEN __BLUE __ALPHA __MIX 
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 o = tex2D(_MainTex, (floor(i.uv)+.5)/_PixelParams.xy);
                fixed m = 0;
            #if defined(__RED)
                m = step(_Treshold, o.r);
            #elif defined(__GREEN)
                m = step(_Treshold, o.g);
            #elif defined(__BLUE)
                m = step(_Treshold, o.b);
            #elif defined(__ALPHA)
                m = step(_Treshold, o.a);
            #elif defined(__MIX)
                m = step(_Treshold*3, o.r+o.g+o.b);
            #endif
                o.a = m;
                return o;
            }
            ENDCG
        }
        //4 invert mask
        Pass
        {
            CGPROGRAM
            float _Distance;
            fixed4 frag (v2f i) : SV_Target
            {
                half4 o = texMain(i.uv);
                for(float x = -1; x<=1; x++)
                {
                    for(float y = -1; y<=1; y++)
                    {
                        if(x==y) continue;
                        o = min(o,texMain(i.uv+half2(x,y)));
                    }
                }
                o.a = 1- o.a;
                return (fixed4)o;
            }
            ENDCG
        }
    }
}
