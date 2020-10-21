using System.Collections.Generic;
using UnityEngine;

namespace Ozeg.Tools
{
    public class SDFConverter
    {
        RenderTexture[] blitTextures = new RenderTexture[2];
        Material material = null;
        public SDFConverter()
        {
            material = new Material(Shader.Find("Hidden/SDFWizard/JumpFlood"));
        }

        public Texture2D RenderSDF(Texture2D source, int distance, float treshold, int upsampling, System.Enum channel, System.Enum mode)
        {
            int maxDim = Mathf.Max(source.width,source.height);
            while(maxDim<<upsampling>2048) upsampling--;
            upsampling = Mathf.Max(0,upsampling);
            for (int i = 0; i < 2; i++) blitTextures[i] = WizardUtils.NewRenderTexture(source, upsampling);
            int target = 0;
            int jump = 2;
            material.SetVector(
                "_PixelParams",
                new Vector4(
                    blitTextures[target].width,
                    blitTextures[target].height,
                    Vector2.Distance( Vector2.zero, new Vector2(blitTextures[target].width, blitTextures[target].height)),
                    jump
                )
            );

            if (source.wrapMode == TextureWrapMode.Repeat)
                material.EnableKeyword( "__REPEAT");
            else
                material.DisableKeyword("__REPEAT");

            var channelDict = new Dictionary<System.Enum,string>()
            {
                { WizardUtils.ColorChannel.Red,     "__RED" },
                { WizardUtils.ColorChannel.Green,   "__GREEN" },
                { WizardUtils.ColorChannel.Blue,    "__BLUE" },
                { WizardUtils.ColorChannel.Alpha,    "__ALPHA" },
                { WizardUtils.ColorChannel.mixRGB,  "__MIX" }
            };
            string channelKey;
            if(channelDict.TryGetValue(channel, out channelKey)) material.EnableKeyword(channelKey);
            material.SetFloat("_Treshold", treshold);
            var exoTexture = new RenderTexture(blitTextures[target]);
            Graphics.Blit(source,exoTexture,material,3);
            Graphics.Blit(exoTexture, blitTextures[target], material, 0);
            int size = Mathf.Min(source.width, source.height);
            while (size > 1)
            {
                target^=1; jump<<=1; size>>=1;
                material.SetVector(
                    "_PixelParams",
                    new Vector4(
                        blitTextures[target].width,
                        blitTextures[target].height,
                        Vector2.Distance( Vector2.zero, new Vector2(blitTextures[target].width, blitTextures[target].height)),
                        jump
                    )
                );
                Graphics.Blit(blitTextures[target^1], blitTextures[target], material, 1);
            }
            target^=1;
            Graphics.Blit(exoTexture,blitTextures[target], material, 4);
            Graphics.Blit(blitTextures[target^1],exoTexture);
            size = Mathf.Min(source.width, source.height);
            jump = 2;
            target^=1;
            Graphics.Blit(blitTextures[target^1], blitTextures[target], material, 0);
            while (size > 1)
            {
                target^=1; jump<<=1; size>>=1;
                material.SetVector(
                    "_PixelParams",
                    new Vector4(
                        blitTextures[target].width,
                        blitTextures[target].height,
                        Vector2.Distance( Vector2.zero, new Vector2(blitTextures[target].width, blitTextures[target].height)),
                        jump
                    )
                );
                Graphics.Blit(blitTextures[target^1], blitTextures[target], material, 1);
            }

            target^=1;
            var outTexture = new RenderTexture(
                source.width, 
                source.height, 
                8, RenderTextureFormat.ARGB32
            );
    
            var modeDict = new Dictionary<System.Enum,string>()
            {
                { SDFConverter.RenderingMode.ContourUV,      "__MODE_UV_CONTOUR" },
                { SDFConverter.RenderingMode.ContourRGB,     "__MODE_RGB_CONTOUR" },
                { SDFConverter.RenderingMode.DistanceOnly,   "__MODE_DIST" },
                { SDFConverter.RenderingMode.NearestUV,      "__MODE_UV" },
                { SDFConverter.RenderingMode.RGBDistance,    "__MODE_RGB_DIST" },
                { SDFConverter.RenderingMode.RGBOnly,        "__MODE_RGB" },
            };
            string modeKey;
            if(modeDict.TryGetValue(mode, out modeKey)) material.EnableKeyword(modeKey);

            material.SetFloat("_Distance", distance<<upsampling);
            material.SetTexture("_ExoTex", exoTexture);
            material.SetTexture("_EndoTex", blitTextures[target^1]);
            Graphics.Blit(source,outTexture, material, 2);
            return WizardUtils.RenderTextureToTexture2D(outTexture);
        }
        public enum RenderingMode
        {
            DistanceOnly,
            RGBOnly,
            RGBDistance,
            NearestUV,
            ContourUV,
            ContourRGB
        }
    }
}