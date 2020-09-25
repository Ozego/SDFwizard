Shader "Hidden/Display/JumpFlood"
{
    Properties
    {
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        ZWrite Off Lighting Off Fog { Mode Off }
        Blend SrcAlpha OneMinusSrcAlpha 
        Cull Off
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ __NearestNeighbour

            #include "UnityCG.cginc"

            struct appdata
            {
                uint vertexID : SV_VertexID;
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
                uint x = 52>>v.vertexID&1;
                uint y = 22>>v.vertexID&1;
                o.uv = float2(x,y);
                o.vertex = float4(-1+x*2.,1-y*2.,1e-6,1);
                o.vertex.x *= min(1,_ScreenParams.y/_ScreenParams.x*_PixelParams.z);
                o.vertex.y *= min(1,_ScreenParams.x/_ScreenParams.y*_PixelParams.w);

                return o;
            }

            sampler2D _MainTex, _CoordTex;

            fixed4 frag (v2f i) : SV_Target
            {
                i.uv += sin(_Time.yy*float2(1,1.618034))*.1;
                fixed4 col = 0;

                half4 coord = tex2D(_CoordTex, i.uv-1/_PixelParams.xy);
                coord.rg = tex2D(_CoordTex, i.uv-(i.uv*_PixelParams.xy%1+.5)/_PixelParams.xy).rg;
                fixed4 tex = tex2D(_MainTex, i.uv-(i.uv*_PixelParams.xy%1+.5)/_PixelParams.xy);
                col = tex2D(_MainTex, coord.rg/_PixelParams.xy);
                col.rgb*=col.a;
                col.rgb *= smoothstep(.9,1,sin(coord.b*1.15-_Time.y))*.25+smoothstep(-.1,.1,sin((coord.b*1.15-_Time.y)*.5-.8))*.05+.1;
                col.rgb *= 1-tex.a;
                col.rgb = saturate(col.rgb);
                col.a=1;
                col.rgb += tex.rgb*tex.a;

                return col;
            }
            ENDCG
        }
    }
}
