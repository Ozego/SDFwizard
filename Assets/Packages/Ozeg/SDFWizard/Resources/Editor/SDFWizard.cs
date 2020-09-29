using UnityEditor;
using UnityEngine;
using System;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
namespace Ozeg.Tools
{
    public class SDFWizard : EditorWindow
    {
        [MenuItem("Tools/SDFWizard")]
        public static void ShowExample()
        {
            SDFWizard window = GetWindow<SDFWizard>();
            window.minSize = new Vector2(288,340);
            window.name = "SDFWizard";
            window.titleContent = new GUIContent("SDFWizard");
        }

        public void OnEnable()
        {
            VisualElement root = rootVisualElement;
            VisualElement vt = Resources.Load<VisualTreeAsset>("Editor/SDFWizard").Instantiate();
            vt.styleSheets.Add(Resources.Load<StyleSheet>("Editor/SDFWizard"));
            root.Add(vt);
            Image           dropBox         = root.Q<Image>         ("DropBox");
            SliderInt       sizeSlider      = root.Q<SliderInt>     ("SizeSlider");
            IntegerField    sizeField       = root.Q<IntegerField>  ("SizeField");
            Slider          tresholdSlider  = root.Q<Slider>        ("TresholdSlider");
            FloatField      tresholdField   = root.Q<FloatField>    ("TresholdField");
            SliderInt       sampleSlider    = root.Q<SliderInt>     ("SampleSlider");
            IntegerField    sampleField     = root.Q<IntegerField>  ("SampleField");
            EnumField       channelSelect   = root.Q<EnumField>     ("ChannelSelect");
            Box             channelDisplay  = root.Q<Box>           ("ChannelDisplay");
            EnumField       modeSelect      = root.Q<EnumField>     ("RenderingSelect");
            EnumField       tilingSelect    = root.Q<EnumField>     ("TilingSelect");
            channelSelect.Init(SDFUtil.ColorChannel.Alpha);
            modeSelect.Init(SDFUtil.RenderingMode.DistanceOnly);
            tilingSelect.Init(TextureWrapMode.Repeat);
            bool validated = false;

            dropBox.RegisterCallback<DragEnterEvent>((e)=>
            {
                foreach (var item in DragAndDrop.objectReferences)
                {
                    if(item.GetType() == typeof(Texture2D)) validated = true;
                }
                dropBox.tintColor = validated ? new Color(.6f, .94f, .2f) : new Color(.94f, .3f, .2f);
            });

            dropBox.RegisterCallback<DragUpdatedEvent>((e)=>
            {
                if(validated) DragAndDrop.visualMode = DragAndDropVisualMode.Copy;
            });

            dropBox.RegisterCallback<DragPerformEvent>((e)=>
            {
                if(validated) for (int i = 0; i < DragAndDrop.objectReferences.Length; i++)
                {
                    var item = (UnityEngine.Object)DragAndDrop.objectReferences[i];
                    string path = DragAndDrop.paths[i];
                    if(item.GetType() == typeof(Texture2D))
                    {
                        string newPath = path.Substring(0,path.LastIndexOf("."))+"_SDF.png";
                        string outPath = Application.dataPath.Substring(0,Application.dataPath.Length-6)+newPath;
                        var texture = item as Texture2D;
                        texture.wrapMode = (TextureWrapMode)tilingSelect.value;
                        var converter = new SDFConverter();
                        var outData = converter.RenderSDF(texture, sizeField.value, tresholdField.value, sampleField.value, channelSelect.value, modeSelect.value);
                        System.IO.File.WriteAllBytes(outPath,outData.EncodeToPNG());
                        AssetDatabase.Refresh();
                        var importer = (TextureImporter)AssetImporter.GetAtPath(newPath);
                        var importerSettings = new TextureImporterSettings();
                        ((TextureImporter)AssetImporter.GetAtPath(path)).ReadTextureSettings(importerSettings);
                        importer.SetTextureSettings(importerSettings);
                        importer.sRGBTexture &= modeSelect.value.Equals(SDFUtil.RenderingMode.RGBDistance);
                        importer.textureCompression = TextureImporterCompression.Uncompressed;
                        importer.SaveAndReimport();
                        AssetDatabase.ImportAsset(newPath);
                    }
                }
            });

            dropBox.RegisterCallback<DragExitedEvent>((e)=>
            {
                validated=false;
                dropBox.tintColor=Color.white;
            });

            dropBox.RegisterCallback<DragLeaveEvent>((e)=>
            {
                validated=false;
                dropBox.tintColor=Color.white;
            });

            sizeSlider.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                sizeField.value=2<<e.newValue;
            });

            sizeField.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                int c = 0;
                int v = e.newValue;
                while(v>2) { c++; v>>=1; }
                sizeSlider.value=c;
                sizeField.value=2<<c;
            });
            
            tresholdSlider.RegisterCallback<ChangeEvent<float>>((e)=>
            {
                tresholdField.value=1f - e.newValue;
            });

            tresholdField.RegisterCallback<ChangeEvent<float>>((e)=>
            {
                tresholdSlider.value=1f - e.newValue;
            });
            sampleSlider.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                sampleField.value=e.newValue;
            });

            sampleField.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                sampleSlider.value=e.newValue;
            });

            channelSelect.RegisterCallback<ChangeEvent<Enum>>((e)=>
            {
                switch (e.newValue)
                {
                    case SDFUtil.ColorChannel.Red: 
                        channelDisplay.style.backgroundColor = new Color(.94f, .3f, .2f); 
                        break;
                    case SDFUtil.ColorChannel.Green: 
                        channelDisplay.style.backgroundColor = new Color(.6f, .94f, .2f); 
                        break;
                    case SDFUtil.ColorChannel.Blue: 
                        channelDisplay.style.backgroundColor = new Color(.2f, .6f, .94f); 
                        break;
                    case SDFUtil.ColorChannel.Alpha: 
                        channelDisplay.style.backgroundColor = Color.grey; 
                        break;
                    default: 
                        channelDisplay.style.backgroundColor = Color.white;
                        break;
                }
            });
        }

        public void OnDisable()
        {
        }
        
    }

}