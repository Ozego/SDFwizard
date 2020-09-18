using UnityEngine;
using UnityEngine.Rendering;
using Unity.Mathematics;

public class JumpFloodController : MonoBehaviour
{

    [SerializeField] Texture2D sourceTexture = null;
    [SerializeField] TextureWrapMode wrapMode = TextureWrapMode.Repeat;
    RenderTexture[] blitTextures = new RenderTexture[2];
    RenderTexture coordTex;
    float scale = .01f;
    Material drawMaterial = null;
    Material blitMaterial = null;
    void Awake()
    {
        drawMaterial = new Material(Shader.Find("Hidden/Display/JumpFlood"));
        blitMaterial = new Material(Shader.Find("Hidden/JumpFlood"));
    }

    void Update()
    {
        coordTex = GenerateCoords(sourceTexture);

        drawMaterial.SetVector(
            "_PixelParams",
            new float4(
                coordTex.width,
                coordTex.height,
                (float)coordTex.width / (float)coordTex.height,
                (float)coordTex.height / (float)coordTex.width
            )
        );

        drawMaterial.SetTexture("_CoordTex", coordTex);
        drawMaterial.SetTexture("_MainTex", sourceTexture);

        Graphics.DrawProcedural
        (
            drawMaterial,
            new Bounds(transform.position, new float3(1e32f)),
            MeshTopology.Triangles, 6, 1,
            Camera.main, null, ShadowCastingMode.Off, false,
            gameObject.layer
        );
    }

    RenderTexture GenerateCoords(Texture2D sourceTexture)
    {
        VerifyTextures(sourceTexture);

        int target = 0;
        int jump = 2;

        blitMaterial.SetVector(
            "_PixelParams",
            new float4(
                sourceTexture.width,
                sourceTexture.height,
                math.length(new float2(sourceTexture.width, sourceTexture.height)),
                jump
            )
        );
        sourceTexture.wrapMode = wrapMode;
        if (wrapMode == TextureWrapMode.Repeat) blitMaterial.EnableKeyword( "__REPEAT");
        else                                    blitMaterial.DisableKeyword("__REPEAT");
        
        Graphics.Blit(sourceTexture, blitTextures[target], blitMaterial, 0);
        int size = math.min(sourceTexture.width, sourceTexture.height);
        while (size > 1)
        {
            target^=1; jump<<=1; size>>=1;

            blitMaterial.SetVector(
                "_PixelParams",
                new float4(
                    sourceTexture.width,
                    sourceTexture.height,
                    math.length(new float2(sourceTexture.width, sourceTexture.height)),
                    jump
                )
            );
            Graphics.Blit(blitTextures[target ^ 1], blitTextures[target], blitMaterial, 1);
        }
        return blitTextures[target];
    }

    private void VerifyTextures(Texture2D sourceTexture)
    {
        for (int i = 0; i < blitTextures.Length; i++)
        {
            if ( blitTextures[i] == null || blitTextures[i].width != sourceTexture.width || blitTextures[i].height != sourceTexture.height || blitTextures[i].wrapMode != wrapMode )
            {
                blitTextures[i] = new RenderTexture
                (
                    sourceTexture.width,
                    sourceTexture.height,
                    16,
                    RenderTextureFormat.ARGBHalf
                );
                blitTextures[i].antiAliasing = 2;
                blitTextures[i].anisoLevel = 0;
                blitTextures[i].filterMode = FilterMode.Bilinear;
                blitTextures[i].useMipMap = false;
                blitTextures[i].wrapMode = wrapMode;
            }

        }
    }
}
