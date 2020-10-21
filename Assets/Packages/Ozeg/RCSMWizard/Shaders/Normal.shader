Shader "Hidden/RCSMWizard/Normal"
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
            fixed4 frag (v2f i) : SV_Target
            {
                float n = tex(_MainTex,i.uv+float2( 0., 1.)).r;
                float s = tex(_MainTex,i.uv+float2( 0.,-1.)).r;
                float e = tex(_MainTex,i.uv+float2( 1., 0.)).r;
                float w = tex(_MainTex,i.uv+float2(-1., 0.)).r;
                float4 normal = fixed4(w-e,s-n,0,1.);
                normal.xy *= _PixelParams.z;
                normal.b = 1.-sqrt(normal.x*normal.x+normal.y*normal.y);
                normal.xyz+=.5;
                return normal;
            }
            ENDCG
        }

        Pass    //1 Unpack
        {
            CGPROGRAM
            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(UnpackNormal(tex(_MainTex,i.uv))*.5+.5,1);
            }
            ENDCG
        }
    }
}
