using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace Ozeg.Tools
{
    public class WizardUtils
    {
        public enum ColorChannel
        {
            Red,
            Green,
            Blue,
            Alpha,
            mixRGB
        }

        public static RenderTexture NewRenderTexture(Texture source)
        {
            return NewRenderTexture(source, 0);
        }
        
        public static RenderTexture NewRenderTexture(Texture source, int upsampling)
        {
            var rt = new RenderTexture
            (
                source.width<<upsampling,
                source.height<<upsampling,
                16,
                RenderTextureFormat.ARGBHalf
            );
            rt.antiAliasing = 2;
            rt.anisoLevel = 0;
            rt.filterMode = FilterMode.Bilinear;
            rt.useMipMap = false;
            rt.wrapMode = source.wrapMode;
            return rt;
        }

        public static Texture2D RenderTextureToTexture2D(RenderTexture rt)
        {
            var tex = new Texture2D(rt.width, rt.height, TextureFormat.RGBA32, false);
            RenderTexture.active = rt;
            tex.ReadPixels(new Rect(0, 0, rt.width, rt.height), 0, 0);
            tex.Apply();
            RenderTexture.active.Release();
            RenderTexture.active = null;
            return tex;
        }
    }
}
