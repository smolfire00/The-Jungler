using UnityEngine;
using UnityEngine.Experimental.Rendering.Universal;

namespace NotSlot.HandPainted2D.Jungle
{
  [RequireComponent(typeof(ParticleSystem))]
  public sealed class PlantsDangerFX : MonoBehaviour
  {
    #region Inspector

    [SerializeField]
    private Color color = new Color(1, 1, 1, 1);

    [SerializeField]
    [Range(0.5f, 10)]
    private float range = 2;

    [Header("Light")]
    [SerializeField]
    [Range(0.1f, 5)]
    private float intensity = 1;

    [SerializeField]
    [Range(0.1f, 10)]
    private float flickerSpeed = 2;

    [SerializeField]
    [Range(0.01f, 1)]
    private float flickerAmount = 0.5f;

    #endregion


    #region Fields

    private float _base;

    private float _counter;

    private Light2D _light;

    #endregion


    #region MonoBehaviour

    private void OnValidate ()
    {
      // Light
      Light2D light2D = GetComponentInChildren<Light2D>(true);
      light2D.color = color;
      light2D.intensity = intensity;
      light2D.pointLightInnerRadius = range / 4;
      light2D.pointLightOuterRadius = range;

      // Particles
      ParticleSystem particles = GetComponent<ParticleSystem>();
      ParticleSystem.MainModule mainModule = particles.main;
      mainModule.startColor = color;

      ParticleSystem.ShapeModule shape = particles.shape;
      shape.radius = range / 2;
    }

    private void Awake ()
    {
      _light = GetComponentInChildren<Light2D>();
    }

    public void Start ()
    {
      _base = _light.intensity;
      _counter = Random.Range(0, 10);
    }

    private void Update ()
    {
      _counter += Time.deltaTime * flickerSpeed;
      _light.intensity = _base + Mathf.Sin(_counter) * flickerAmount;
    }

    #endregion
  }
}