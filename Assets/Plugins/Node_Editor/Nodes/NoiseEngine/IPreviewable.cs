﻿using UnityEngine;

namespace NodeEditorFramework.NoiseEngine
{
    public interface IPreviewable
    {
        Texture2D Preview { get; set; }

        Texture2D CalculatePreview(int size = 128);
    }
}