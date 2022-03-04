using System;
using UnityEngine;

namespace NotSlot.HandPainted2D
{
  [AddComponentMenu("2D Hand Painted/Animate/Translate Loop")]
  public sealed class AnimateTranslateLoop : MonoBehaviour
  {
    #region Inspector

    [Range(-2, 2)]
    [SerializeField]
    private float speed = -0.2f;

    [SerializeField]
    private float leftWorldX = default;

    [SerializeField]
    private float rightWorldX = default;

    #endregion


    #region MonoBehavior

    private void Update ()
    {
      Transform myTransform = transform;
      Vector3 pos = myTransform.position;
      pos.x += speed * Time.deltaTime;

      if ( speed > 0 )
      {
        if ( pos.x >= rightWorldX )
          pos.x = leftWorldX;
      }
      else
      {
        if ( pos.x <= leftWorldX )
          pos.x = rightWorldX;
      }

      myTransform.position = pos;
    }

    private void OnDrawGizmosSelected ()
    {
      Gizmos.color = Color.yellow;

      Vector3 from = new Vector3(leftWorldX, transform.position.y - 1);
      Vector3 to = new Vector3(leftWorldX, transform.position.y + 1);
      Gizmos.DrawLine(from, to);

      from.x = rightWorldX;
      to.x = rightWorldX;
      Gizmos.DrawLine(from, to);
    }

    #endregion
  }
}