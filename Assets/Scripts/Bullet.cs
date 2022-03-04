using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bullet : MonoBehaviour
{
    public int damage = 1;
    public Rigidbody2D rb;
    public float dieTime;

    void Start()
    {
        StartCoroutine(Timer());
    }
    IEnumerator Timer()
    {
        yield return new WaitForSeconds(dieTime);
        Destroy(gameObject);
    }
    private void OnTriggerEnter2D(Collider2D hitInfo)
    {
        Monster monster = hitInfo.GetComponent<Monster>();
        if (monster != null)
        {
            monster.TakeHit(damage);
            Debug.Log(damage);
            Destroy(gameObject);
        }
        
    }
}
