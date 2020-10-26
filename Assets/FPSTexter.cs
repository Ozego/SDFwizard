using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FPSTexter : MonoBehaviour
{
    UnityEngine.UI.Text text;
    void Update()
    {
        if(text==null)text=GetComponent<UnityEngine.UI.Text>();
        if(Time.frameCount%8==0) text.text = $"{Mathf.FloorToInt(1f/Time.deltaTime)} FPS";
    }
}
