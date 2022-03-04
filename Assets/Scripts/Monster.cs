using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Monster : MonoBehaviour
{
    public float Hitpoints;
    public float MaxHitPoints = 5;
    public HealthBarBehaviour HealthBar;
    public GameObject coinPrefab;

    private void Start()
    {
        Animator anim = GetComponent<Animator>();
        Hitpoints = MaxHitPoints;
        HealthBar.SetHealth(Hitpoints,MaxHitPoints);
    }

    public void TakeHit(float damage)
    {
        Hitpoints -= damage;
        HealthBar.SetHealth(Hitpoints,MaxHitPoints);
        if (Hitpoints <=0)
        {
            Destroy(gameObject);
            Instantiate(coinPrefab, transform.position, Quaternion.Euler(0, 0, -90));
        }
    }
}
