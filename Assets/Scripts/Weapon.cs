using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Weapon : MonoBehaviour
{
    // Start is called before the first frame update
    public Transform firePoint;
    public GameObject arrowPrefab;
    public float speed = 5.0f;
    public float shootTimer;

    private bool isShooting;
    private Animator ani;
    [SerializeField] private AudioSource shootSoundEffect;

    private void Start()
    {
        isShooting = false;
        ani = GetComponent<Animator>();
    }
    // Update is called once per frame
    void Update()
    {
        if(Input.GetKeyDown(KeyCode.X) && !isShooting)
        {
            shootSoundEffect.Play();
            StartCoroutine(Shoot());
            ani.SetTrigger("attack");
        }
    }
    IEnumerator Shoot()
    {
        
        if (transform.localScale.x < 0f)
        {
            isShooting = true;
            GameObject arrow = Instantiate(arrowPrefab, firePoint.position, Quaternion.Euler(0, 0, -90));
            arrow.GetComponent<Rigidbody2D>().velocity = new Vector2(speed * 1 * Time.fixedDeltaTime, 0f);
            arrow.transform.localScale = new Vector2(arrow.transform.localScale.x * 1, arrow.transform.localScale.y);
            yield return new WaitForSeconds(shootTimer);
            isShooting = false;
        }
        else
        {
            isShooting = true;
            GameObject arrow = Instantiate(arrowPrefab, firePoint.position, Quaternion.Euler(0, 0, 90));
            arrow.GetComponent<Rigidbody2D>().velocity = new Vector2(speed * -1 * Time.fixedDeltaTime, 0f);
            arrow.transform.localScale = new Vector2(arrow.transform.localScale.x * -1, arrow.transform.localScale.y);
            yield return new WaitForSeconds(shootTimer);
            isShooting = false;
        }
       
    }
}
