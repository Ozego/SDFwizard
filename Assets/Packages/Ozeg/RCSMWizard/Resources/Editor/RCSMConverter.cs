using System.Collections.Generic;
using UnityEngine;
namespace Ozeg.Tools
{
    public class RCSMConverter
    {
        public static RenderTexture PackRCSM(Texture src, Texture cone, Texture normal)
        {
            RenderTexture dst = WizardUtils.NewRenderTexture(src);
            var material = new Material(Shader.Find("Hidden/RCSMWizard/Pack"));
            material.SetVector("_PixelParams",new Vector4(src.width,src.height,0,0));
            material.SetTexture("_Cone",cone);
            material.SetTexture("_Normal",normal);
            Graphics.Blit(src,dst,material,0);
            return dst;
        }
        public static RenderTexture ImportNormal(Texture src)
        {
            if(src==null)src = Texture2D.normalTexture;
            RenderTexture dst = WizardUtils.NewRenderTexture(src);
            var material = new Material(Shader.Find("Hidden/RCSMWizard/Normal"));
            material.SetVector("_PixelParams",new Vector4(src.width,src.height,0,0));
            Graphics.Blit(src,dst,material,1);
            return dst;
        }
        public static RenderTexture RenderNormal(Texture2D src)
        {
            RenderTexture dst = WizardUtils.NewRenderTexture(src);
            var material = new Material(Shader.Find("Hidden/RCSMWizard/Normal"));
            int s = Mathf.Max(src.width,src.height);
            int f = 1;
            while(s>=256){s>>=1;f<<=1;}
            material.SetVector("_PixelParams",new Vector4(src.width,src.height,f,0));
            Graphics.Blit(src,dst,material,0);
            return dst;
        }

        public static RenderTexture RenderRCSMPerPixel(Texture2D src, int steps)
        {
            
            RenderTexture[] blitTextures = new RenderTexture[2];
            for (int i = 0; i < 2; i++) blitTextures[i] = WizardUtils.NewRenderTexture(src);
            var material = new Material(Shader.Find("Hidden/RCSMWizard/PerPixel"));
            material.SetFloat("_Steps",steps);

            Graphics.Blit(src,blitTextures[0],material,0);
            Graphics.Blit(src,blitTextures[1],material,0);

            int target = 1;
            for (int x = 0; x < src.width; x++)
            {
                for (int y = 0; y < src.height; y++)
                {
                    target ^= 1;
                    material.SetVector("_PixelParams",new Vector4(src.width,src.height,x-src.width/2,y-src.height/2));
                    material.SetTexture("_BufferTex",blitTextures[target^1]);
                    Graphics.Blit(src,blitTextures[target],material,1);
                }
            }
            return blitTextures[target];
        }
    }
}
  