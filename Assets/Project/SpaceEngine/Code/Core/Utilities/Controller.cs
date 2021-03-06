﻿//using Proland;


using UnityEngine;

namespace SpaceEngine.Core.Utilities
{
    /// <summary>
    /// Controller used to collect user input and move the view (<see cref="TerrainView"/> or <see cref="PlanetView"/>)
    /// Provides smooth interpolation from the views current to new position.
    /// </summary>
    public class Controller : MonoBehaviour
    {
        /*
        [SerializeField]
        double MoveSpeed = 1e-3;

        [SerializeField]
        double TurnSpeed = 5e-3;

        [SerializeField]
        double ZoomSpeed = 1.0;

        [SerializeField]
        double RotateSpeed = 0.1;

        [SerializeField]
        double DragSpeed = 0.01;

        /// <summary>
        /// Use exponential damping to go to target positions?
        /// </summary>
        [SerializeField]
        bool Smooth = true;

        bool NearPressed;
        bool FarPressed;
        bool ForwardPressed;
        bool BackwardPressed;
        bool LeftPressed;
        bool RightPressed;

        bool Initialized;

        /// <summary>
        /// The target position manipulated by the user via the mouse and keyboard.
        /// </summary>
        TerrainView.Position TargetPosition;

        /// <summary>
        /// Start position for an animation between two positions.
        /// </summary>
        TerrainView.Position StartPosition;

        /// <summary>
        /// End position for an animation between two positions.
        /// </summary>
        TerrainView.Position EndPosition;

        Vector3d PreviousMousePos;

        private double AnimationValue = -1.0;

        public TerrainView View { get; private set; }

        private void Start()
        {
            View = GetComponent<TerrainView>();

            TargetPosition = new TerrainView.Position();
            StartPosition = new TerrainView.Position();
            EndPosition = new TerrainView.Position();
            PreviousMousePos = new Vector3d(Input.mousePosition);
        }

        public void UpdateController()
        {
            if (!Initialized)
            {
                GetPosition(TargetPosition);

                Initialized = true;
            }

            KeyDown();
            MouseWheel();
            MouseMotion();

            double dt = Time.deltaTime * 1000.0;

            // If animation requried interpolate from start to end position
            // NOTE : has not been tested and not currently used
            if (AnimationValue >= 0.0)
            {
                AnimationValue = View.Interpolate(StartPosition.x0, StartPosition.y0, StartPosition.theta, StartPosition.phi, StartPosition.distance, EndPosition.x0, EndPosition.y0, EndPosition.theta, EndPosition.phi, EndPosition.distance, AnimationValue);

                if (Math.Abs(AnimationValue - 1.0) < 0.00001)
                {
                    GetPosition(TargetPosition);

                    AnimationValue = -1.0;
                }
            }
            else
            {
                UpdateController(dt);
            }

            // Update the view so the new positions are relected in the matrices
            View.UpdateView();
        }

        private void UpdateController(double dt)
        {
            double dzFactor = Math.Pow(1.02, Math.Min(dt, 1.0));

            if (NearPressed)
            {
                TargetPosition.distance = TargetPosition.distance / (dzFactor * ZoomSpeed);
            }
            else if (FarPressed)
            {
                TargetPosition.distance = TargetPosition.distance * dzFactor * ZoomSpeed;
            }

            TerrainView.Position position = new TerrainView.Position();

            GetPosition(position);
            SetPosition(TargetPosition);

            if (ForwardPressed || BackwardPressed)
            {
                var speed = Math.Max(View.GetHeight(), 1.0);

                if (ForwardPressed)
                {
                    View.MoveForward(speed * dt * MoveSpeed);
                }
                else if (BackwardPressed)
                {
                    View.MoveForward(-speed * dt * MoveSpeed);
                }
            }

            if (LeftPressed)
            {
                View.Turn(dt * TurnSpeed);
            }
            else if (RightPressed)
            {
                View.Turn(-dt * TurnSpeed);
            }

            GetPosition(TargetPosition);

            if (Smooth)
            {
                var lerp = 1.0 - Math.Exp(-dt * 2.301e-3);
                var x0 = 0.0;
                var y0 = 0.0;

                View.InterpolatePos(position.x0, position.y0, TargetPosition.x0, TargetPosition.y0, lerp, ref x0, ref y0);

                position.x0 = x0;
                position.y0 = y0;
                position.theta = Mix(position.theta, TargetPosition.theta, lerp);
                position.phi = Mix(position.phi, TargetPosition.phi, lerp);
                position.distance = Mix(position.distance, TargetPosition.distance, lerp);

                SetPosition(position);
            }
            else
            {
                SetPosition(TargetPosition);
            }

        }

        private double Mix(double x, double y, double t)
        {
            return Math.Abs(x - y) < Math.Max(x, y) * 1e-5 ? y : x * (1.0 - t) + y * t;
        }

        private void GetPosition(TerrainView.Position p)
        {
            p.x0 = View.GetPos().x0;
            p.y0 = View.GetPos().y0;
            p.theta = View.GetPos().theta;
            p.phi = View.GetPos().phi;
            p.distance = View.GetPos().distance;
        }

        private void SetPosition(TerrainView.Position p)
        {
            View.GetPos().x0 = p.x0;
            View.GetPos().y0 = p.y0;
            View.GetPos().theta = p.theta;
            View.GetPos().phi = p.phi;
            View.GetPos().distance = p.distance;

            AnimationValue = -1.0;
        }

        public void GoToPosition(TerrainView.Position p)
        {
            GetPosition(StartPosition);

            EndPosition = p;
            AnimationValue = 0.0;
        }

        public void JumpToPosition(TerrainView.Position p)
        {
            SetPosition(p);

            TargetPosition = p;
        }

        private void MouseWheel()
        {
            NearPressed = false;
            FarPressed = false;

            if (Input.GetAxis("Mouse ScrollWheel") < 0.0f || Input.GetKey(KeyCode.PageUp))
            {
                FarPressed = true;
            }

            if (Input.GetAxis("Mouse ScrollWheel") > 0.0f || Input.GetKey(KeyCode.PageDown))
            {
                NearPressed = true;
            }
        }

        private void KeyDown()
        {
            ForwardPressed = Input.GetKey(KeyCode.UpArrow) || Input.GetKey(KeyCode.W);
            BackwardPressed = Input.GetKey(KeyCode.DownArrow) || Input.GetKey(KeyCode.S);
            LeftPressed = Input.GetKey(KeyCode.LeftArrow) || Input.GetKey(KeyCode.A);
            RightPressed = Input.GetKey(KeyCode.RightArrow) || Input.GetKey(KeyCode.D);
        }

        private void MouseMotion()
        {
            if (Input.GetMouseButton(0) && Input.GetKey(KeyCode.LeftControl))
            {
                TargetPosition.phi -= Input.GetAxis("Mouse X") * RotateSpeed;
                TargetPosition.theta += Input.GetAxis("Mouse Y") * RotateSpeed;
            }
            else if (Input.GetMouseButton(0))
            {
                Vector3d mousePos = Vector3d.zero;
                mousePos.x = Input.mousePosition.x;
                mousePos.y = Input.mousePosition.y;
                mousePos.z = 0.0;

                Vector3d preMousePos = Vector3d.zero;
                preMousePos.x = PreviousMousePos.x;
                preMousePos.y = PreviousMousePos.y;
                preMousePos.z = 0.0;

                Vector3d oldPosition = View.GetCameraToWorld() * preMousePos;
                Vector3d position = View.GetCameraToWorld() * mousePos;

                if (!(double.IsNaN(oldPosition.x) || double.IsNaN(oldPosition.y) || double.IsNaN(oldPosition.z) || double.IsNaN(position.x) || double.IsNaN(position.y) || double.IsNaN(position.z)))
                {
                    TerrainView.Position current = new TerrainView.Position();

                    GetPosition(current);
                    SetPosition(TargetPosition);

                    View.Move(new Vector3d(oldPosition), new Vector3d(position), DragSpeed);

                    GetPosition(TargetPosition);
                    SetPosition(current);
                }
            }

            PreviousMousePos = new Vector3d(Input.mousePosition);
        }
        */
    }
}