﻿namespace Experimental
{
    using System;
    using System.Collections.Generic;

    using UnityEngine;

    public class FlightGlobals : MonoBehaviour
    {
        private static FlightGlobals _fetch;
        public static FlightGlobals fetch
        {
            get
            {
                if (_fetch == null)
                {
                    _fetch = (FlightGlobals)FindObjectOfType(typeof(FlightGlobals));
                }

                return _fetch;
            }
        }

        public Vessel activeVessel;
        public static Vessel ActiveVessel
        {
            get
            {
                return fetch.activeVessel;
            }
        }

        public List<Vessel> vessels = new List<Vessel>();
        public static List<Vessel> Vessels
        {
            get
            {
                return fetch.vessels;
            }
        }

        public List<CelestialBody> bodies = new List<CelestialBody>();
        public static List<CelestialBody> Bodies
        {
            get
            {
                return fetch.bodies;
            }
        }

        public static List<GameObject> physicalObjects = new List<GameObject>();

        public static Vector3d getUpAxis(Vector3d position)
        {
            return (position - getMainBody(position).position).normalized;
        }

        public static Vector3d getUpAxis(CelestialBody body, Vector3d position)
        {
            return (position - body.position).normalized;
        }

        public static CelestialBody getMainBody(Vector3d refPos)
        {
            return inSOI(refPos, fetch.bodies[0]);
        }

        private static CelestialBody inSOI(Vector3d pos, CelestialBody body)
        {
            int count = body.orbitingBodies.Count;

            if (count > 0)
            {
                for (int i = 0; i < count; i++)
                {
                    CelestialBody celestialBody = body.orbitingBodies[i];

                    if ((pos - celestialBody.position).sqrMagnitude < celestialBody.sphereOfInfluence * celestialBody.sphereOfInfluence)
                    {
                        return inSOI(pos, celestialBody);
                    }
                }
            }

            return body;
        }

        public static Vector3d getCentrifugalAcc(Vector3d pos, CelestialBody body)
        {
            if (!body.inverseRotation) return Vector3d.zero;

            pos = body.position - pos;

            return Vector3d.Cross(body.angularVelocity, Vector3d.Cross(body.angularVelocity, pos));
        }

        public static Vector3d getCoriolisAcc(Vector3d vel, CelestialBody body)
        {
            if (!body.inverseRotation) return Vector3d.zero;

            return -2 * Vector3d.Cross(body.angularVelocity, vel);
        }

        public static Vector3d getGeeForceAtPosition(Vector3d pos)
        {
            CelestialBody mainBody = getMainBody(pos);

            double magn = (mainBody.position - pos).sqrMagnitude;

            return Vector3d.Normalize(pos - mainBody.position) * -(mainBody.gMagnitudeAtCenter / magn);
        }

        public static CelestialBody getMainBody()
        {
            if (ActiveVessel)
            {
                return ActiveVessel.orbitDriver.referenceBody;
            }

            return getMainBody(Vector3.zero);
        }

        public CelestialBody currentMainBody;

        public bool RefFrameIsRotating
        {
            get
            {
                return currentMainBody.rotates && currentMainBody.inverseRotation;
            }
        }
    }
}