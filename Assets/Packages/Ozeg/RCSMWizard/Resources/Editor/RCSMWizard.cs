using UnityEditor;
using UnityEngine;
using System;
using UnityEngine.UIElements;
using UnityEditor.UIElements;


public class RCSMWizard : EditorWindow
{
    [MenuItem("Tools/RCSMWizard")]
    public static void ShowExample()
    {
        RCSMWizard window = GetWindow<RCSMWizard>();
        window.name = "SDFWizard";
        window.titleContent = new GUIContent("RCSMWizard");
    }

    public void OnEnable()
    {
        VisualElement root = rootVisualElement;
        VisualElement vt = Resources.Load<VisualTreeAsset>("Editor/RCSMWizardMarkup").Instantiate();
        vt.styleSheets.Add(Resources.Load<StyleSheet>("Editor/RCSMWizardStyle"));
        root.Add(vt);
        ProgressBar progress = vt.Q<ProgressBar>("progress");
        ObjectField heightMapField = vt.Q<ObjectField>("heightMapField");
        ObjectField normalMapField = vt.Q<ObjectField>("normalMapField");
        heightMapField.objectType = typeof(Texture);
        normalMapField.objectType = typeof(Texture);
        
        progress.value = 50f;
    }
}