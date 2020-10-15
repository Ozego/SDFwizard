using UnityEditor;
using UnityEngine;
using System;
using UnityEngine.UIElements;
using UnityEditor.UIElements;
using Random = UnityEngine.Random;

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
        [MenuItem("Tools/RCSMWizard")]
        public static void ShowExample()
        {
            RCSMWizard window = GetWindow<RCSMWizard>();
            window.minSize = new Vector2(256,256);
            window.name = "SDFWizard";
            window.titleContent = new GUIContent("RCSMWizard");
        }
        public void OnEnable()
        {
            VisualElement root = rootVisualElement;
            VisualElement vt = Resources.Load<VisualTreeAsset>("Editor/RCSMWizardMarkup").Instantiate();
            vt.styleSheets.Add(Resources.Load<StyleSheet>("Editor/RCSMWizardStyle"));
            root.Add(vt);
            EnumField       algorithmSelect     = vt.Q<EnumField>       ("algorithmSelect");
            EnumField       normalSelect        = vt.Q<EnumField>       ("normalSelect");
            ObjectField     heightMapField      = vt.Q<ObjectField>     ("heightMapField");
            ObjectField     normalMapField      = vt.Q<ObjectField>     ("normalMapField");
            Button          runButton           = vt.Q<Button>          ("runButton");
            algorithmSelect.Init(RCSMAlgorithm.PerPixel);
            normalSelect.Init(NormalMapOptions.None);
            heightMapField.objectType = typeof(Texture);
            normalMapField.objectType = typeof(Texture);

            algorithmSelect.RegisterCallback<ChangeEvent<Enum>>((e)=>{
                switch (e.newValue)
                {
                    case RCSMAlgorithm.PerPixel: 
                        break;
                    case RCSMAlgorithm.JumpFlood:
                        EditorUtility.DisplayDialog("Selected algorithm does not exist!", "The selected algorithm is not yet available. \nPlease wait for an update", "Ok");
                        algorithmSelect.value = RCSMAlgorithm.PerPixel;
                        break;
                }
            });
            normalSelect.RegisterCallback<ChangeEvent<Enum>>((e)=>{
                switch (e.newValue)
                {
                    case NormalMapOptions.Generate: 
                        EditorUtility.DisplayDialog("Selected algorithm does not exist!", "The selected algorithm is not yet available. \nPlease wait for an update", "Ok");
                        normalSelect.value = NormalMapOptions.None;
                        normalSelect.parent.visible = false;
                        break;
                    case NormalMapOptions.Import: 
                        normalSelect.parent.visible = true;
                        break;
                    case NormalMapOptions.None:
                        normalSelect.parent.visible = false;
                        break;
                }
            });

            normalSelect.parent.visible = false;
            algorithmSelect.parent.visible = false;
            normalMapField.parent.visible = false;

            normalSelect.parent.RemoveFromHierarchy();
            algorithmSelect.parent.RemoveFromHierarchy();
            normalMapField.parent.RemoveFromHierarchy();

        }
    }
}