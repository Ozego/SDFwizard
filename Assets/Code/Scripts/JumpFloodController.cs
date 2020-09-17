using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Mathematics;

using Random = UnityEngine.Random;

public class JumpFloodController : MonoBehaviour
{
    [SerializeField] Texture2D sourceTexture = null;
    RenderTexture[] blitTextures = new RenderTexture[2];
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
        VerifyTextures();

        int target = 0;
        int jump=2;

        blitMaterial.SetVector(
            "_PixelParams",
            new float4(
                sourceTexture.width,
                sourceTexture.height,
                math.length(new float2(sourceTexture.width, sourceTexture.height)),
                jump
            )
        );
        Graphics.Blit(sourceTexture, blitTextures[target], blitMaterial, 0);
        int size = math.min(sourceTexture.width, sourceTexture.height);

        while(size>1)
        {
            target^=1;
            jump<<=1;
            size>>=1;

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

        drawMaterial.SetVector(
            "_PixelParams",
            new float4(
                sourceTexture.width,
                sourceTexture.height,
                (float)sourceTexture.width / (float)sourceTexture.height,
                (float)sourceTexture.height / (float)sourceTexture.width
            )
        );
        drawMaterial.SetTexture("_CoordTex", blitTextures[target]);
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

    private void VerifyTextures()
    {
        for (int i = 0; i < blitTextures.Length; i++)
        {
            if ( blitTextures[i] == null || blitTextures[i].width != sourceTexture.width || blitTextures[i].height != sourceTexture.height )
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
                blitTextures[i].wrapMode = TextureWrapMode.Repeat;
            }

        }
    }
}
