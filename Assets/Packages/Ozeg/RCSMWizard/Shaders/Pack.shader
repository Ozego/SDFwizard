Shader "Hidden/RCSMWizard/Pack"
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
        Pass    //0 Generate
        {
            CGPROGRAM
            sampler2D _Cone,_Normal;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = 0;
                col.rg = tex(_Normal, i.uv).rg;
                col.b  = tex(_Cone, i.uv).r;
                col.a  = tex(_MainTex, i.uv).r;
                return col;
            }
            ENDCG
        }
    }
}
