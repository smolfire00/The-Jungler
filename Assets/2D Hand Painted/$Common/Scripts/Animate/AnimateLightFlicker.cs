using UnityEngine;
using Random = UnityEngine.Random;
using UnityEngine.Experimental.Rendering.Universal;

namespace NotSlot.HandPainted2D
{
  [RequireComponent(typeof(Light2D))]
  [AddComponentMenu("2D Hand Painted/Animate/Light Flicker")]
  public sealed class AnimateLightFlicker : MonoBehaviour
  {
    #region Inspector

    [SerializeField]
    [Range(0.1f, 10)]
    private float speed = 2;

    [SerializeField]
    [Range(0.01f, 1)]
    private float amount = 0.5f;

    #endregion


    #region Fields

    private float _base;

    private float _counter;

    private Light2D _light;

    #endregion


    #region MonoBehaviour

    private void Awake ()
    {
      _light = GetComponent<Light2D>();
    }

    public void Start ()
    {
      _base = _light.intensity;
      _counter = Random.Range(0, 10);
    }

    private void Update ()
    {
      _counter += Time.deltaTime * speed;
      _light.intensity = _base + Mathf.Sin(_counter) * amount;
    }

    #endregion
  }
}