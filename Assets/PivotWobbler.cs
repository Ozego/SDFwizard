using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PivotWobbler : MonoBehaviour
{
    [SerializeField] Vector4 speed;
    Vector3 dir;
    float[] t = new float[1]{0f};
    void Start()
    {
        Vector3 cameraDir = (Camera.main.transform.position - transform.position).normalized;
        dir = transform.worldToLocalMatrix.MultiplyVector(Vector3.Cross(Vector3.up, cameraDir));
    }


    void Update()
    {
        t[0] += speed.y*Time.deltaTime;
        transform.Rotate(dir,speed.z*Mathf.Sin(t[0])*Time.deltaTime,Space.Self);
        transform.Rotate(Vector3.up,speed.x*Time.deltaTime,Space.World);
    }
}