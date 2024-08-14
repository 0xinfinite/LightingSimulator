using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GameManager : MonoBehaviour
{
    public GameObject sphere;
    public Camera cam;
    public LightingSettings lightingSettings;
    
    private bool fastAmbientMode;

    // Start is called before the first frame update
    void Start()
    {
#if UNITY_EDITOR
        prevPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
#endif
        //RenderSettings.
        //lightingSettings = 
    }

    private Vector2 GetAverageDeltaPosition()
    {
        Vector2 dtp = Vector2.zero;

        for (int i = 0; i < Input.touchCount; i++) {
            dtp += Input.touches[i].deltaPosition;
        }
        return dtp;
    }

    Vector2 prevPos;
    // Update is called once per frame
    void LateUpdate()
    {
#if UNITY_EDITOR
        int touchCount = Input.GetMouseButton(0) ? 1 : Input.GetMouseButton(1) ? 2:0;//touchCount;
        Vector2 deltaPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y )- prevPos;//GetAverageDeltaPosition();
        prevPos = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
#else
        int touchCount = Input.touchCount;
        Vector2 deltaPos = GetAverageDeltaPosition();
#endif
        switch (touchCount)
        {
            case 1:
                float x = deltaPos.x;
                float y = deltaPos.y ;
                sphere.transform.localEulerAngles += new Vector3(y, x, 0);
                break;
            case 2:
#if UNITY_EDITOR
                float value = Input.mouseScrollDelta.y;
#else
                float value = (-1*Input.touches[0].deltaPosition.x) + Input.touches[1].deltaPosition.y ;
#endif
                cam.transform.localPosition += new Vector3(0, 0, value);
                break;
        }
        
    }

    public void ChangeLightDirection(float value)
    {

    }

    public void ChangeLightAngle(float value)
    {

    }

    public void ChangeAmbientLightColor()
    {
        if (fastAmbientMode)
        {
            //lightingSettings.
        }
    }

}
