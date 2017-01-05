﻿using UnityEngine;

public class RingSegment : MonoBehaviour
{
    public Ring Ring;

    public void Render(Camera camera, int drawLayer = 8)
    {
        if (Ring == null) return;
        if (Ring.RingSegmentMesh == null) return;
        if (Ring.RingMaterial == null) return;

        var SegmentTRS = Matrix4x4.TRS(Ring.transform.position, transform.rotation, Vector3.one);

        Graphics.DrawMesh(Ring.RingSegmentMesh, SegmentTRS, Ring.RingMaterial, drawLayer, camera);
    }

    public void UpdateNode(Mesh mesh, Material material, Quaternion rotation)
    {
        if (Ring != null)
        {
            Helper.SetLocalRotation(transform, rotation);
        }
    }

    public static RingSegment Create(Ring ring)
    {
        var segmentGameObject = Helper.CreateGameObject("Segment", ring.transform);
        var segment = segmentGameObject.AddComponent<RingSegment>();

        segment.Ring = ring;

        return segment;
    }
}