using UnityEditor;
using UnityEngine;
using System;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using Random = UnityEngine.Random;
using Object = UnityEngine.Object;

namespace Ozeg.Tools
{
    public class RCSMWizard : EditorWindow
    {
        enum RCSMAlgorithm
        {
            PerPixel,
            JumpFlood
        }
        enum NormalMapOptions
        {
            Import,
            Generate,
            None
        }
        [MenuItem("Tools/Relaxed Wizard")]
        public static void ShowExample()
        {
            RCSMWizard window = GetWindow<RCSMWizard>();
            window.minSize = new Vector2(256,256);
            window.name = "Relaxed Wizard";
            window.titleContent = new GUIContent("Relaxed Wizard");
        }
        public void OnEnable()
        {
            VisualElement root = rootVisualElement;
            VisualElement vt = Resources.Load<VisualTreeAsset>("Editor/RCSMWizardMarkup").Instantiate();
            vt.styleSheets.Add(Resources.Load<StyleSheet>("Editor/RCSMWizardStyle"));
            root.Add(vt);
            EnumField       normalSelect        = vt.Q<EnumField>       ("normalSelect");
            ObjectField     heightMapField      = vt.Q<ObjectField>     ("heightMapField");
            ObjectField     normalMapField      = vt.Q<ObjectField>     ("normalMapField");
            SliderInt       stepSlider          = vt.Q<SliderInt>       ("stepSlider");
            IntegerField    stepField           = vt.Q<IntegerField>    ("stepField");
            Button          runButton           = vt.Q<Button>          ("runButton");
            EnumField       tilingSelect        = vt.Q<EnumField>       ("TilingSelect");
            EnumField       algorithmSelect     = vt.Q<EnumField>       ("AlgorithmSelect");

            tilingSelect.Init(TextureWrapMode.Repeat);
            normalSelect.Init(NormalMapOptions.Import);
            algorithmSelect.Init(RCSMAlgorithm.JumpFlood);

            heightMapField.objectType = typeof(Texture);
            normalMapField.objectType = typeof(Texture);

            normalSelect.RegisterCallback<ChangeEvent<Enum>>((e)=>{
                switch(e.newValue)
                {
                    case NormalMapOptions.Generate: 
                        normalMapField.parent.visible = false;
                        break;
                    case NormalMapOptions.Import: 
                        normalMapField.parent.visible = true;
                        break;
                    case NormalMapOptions.None:
                        normalMapField.parent.visible = false;
                        break;
                }
            });
            algorithmSelect.RegisterCallback<ChangeEvent<Enum>>((e)=>{
                switch(e.newValue)
                {
                    case RCSMAlgorithm.PerPixel:
                        if(!EditorUtility.DisplayDialog("Per Pixel Selected","Processing the map per pixel may take a long time. \nUsing Jump Flood is reccomended. \nPer Pixel should only be used where high accuracy is required.","Ok","Cancel")) algorithmSelect.value = RCSMAlgorithm.JumpFlood;
                        break;
                }
            });

            
            stepSlider.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                stepField.value= e.newValue;
            });

            stepField.RegisterCallback<ChangeEvent<int>>((e)=>
            {
                stepSlider.value= e.newValue;
            });

            heightMapField.RegisterCallback<ChangeEvent<Object>>((e)=>
            {
                var value = e.newValue as Texture;
                if(value!=null) tilingSelect.value = value.wrapMode;
            });
            
            runButton.clickable.clicked += delegate{
                if(validateParams())
                {
                    var heightMap = heightMapField.value as Texture;
                    heightMap.wrapMode = (TextureWrapMode)tilingSelect.value;
                    Texture normalMap = null;
                    switch (normalSelect.value)
                    {
                        case NormalMapOptions.Import    :   normalMap = RCSMConverter.ImportNormal(normalMapField.value as Texture);    break;
                        case NormalMapOptions.Generate  :   normalMap = RCSMConverter.RenderNormal(heightMap as Texture2D);             break;
                        default                         :   normalMap = RCSMConverter.ImportNormal(null);                               break;
                    }
                    Texture coneMap = null;
                    switch(algorithmSelect.value)
                    {
                        case RCSMAlgorithm.PerPixel     :   coneMap = RCSMConverter.RenderRCSMPerPixel(heightMap as Texture2D, stepField.value);    break;
                        case RCSMAlgorithm.JumpFlood    :   coneMap = RCSMConverter.RenderRCSMFloodJump(heightMap as Texture2D, stepField.value);   break;
                        default                         :   coneMap = RCSMConverter.RenderRCSMFloodJump(heightMap as Texture2D, stepField.value);   break;
                    }
                    Texture RCSMap = RCSMConverter.PackRCSM(heightMap,coneMap,normalMap);

                    string path = AssetDatabase.GetAssetPath(heightMap);
                    string newPath = path.Substring(0,path.LastIndexOf("."))+"_RCSM.png";
                    string systemPath = Application.dataPath.Substring(0,Application.dataPath.Length-6)+newPath;
                    System.IO.File.WriteAllBytes(systemPath,WizardUtils.RenderTextureToTexture2D(RCSMap as RenderTexture).EncodeToPNG());

                    
                    AssetDatabase.Refresh();
                    var importer = (TextureImporter)AssetImporter.GetAtPath(newPath);
                    var importerSettings = new TextureImporterSettings();
                    ((TextureImporter)AssetImporter.GetAtPath(path)).ReadTextureSettings(importerSettings);
                    importer.SetTextureSettings(importerSettings);
                    importer.sRGBTexture = false;
                    importer.textureCompression = TextureImporterCompression.Uncompressed;
                    importer.mipmapEnabled = false;

                    importer.SaveAndReimport();
                    AssetDatabase.ImportAsset(newPath);
                    AssetDatabase.Refresh();
                }
            };

            bool validateParams()
            {
                if(heightMapField.value==null)
                {
                    EditorUtility.DisplayDialog("Error!","Height Map not found!","Ok");
                    return false;
                }
                return true;
            }
        }

    }
}