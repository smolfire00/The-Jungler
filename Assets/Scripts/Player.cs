using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Player : MonoBehaviour
{
    public float dir_X;
    public float _speed = 3.0f;
    private BoxCollider2D coll;

    private Rigidbody2D rb;
    private Animator ani;
    Vector3 localScale;
    bool facingRight = false;

    [SerializeField] private AudioSource jumpSoundEffect;

    [SerializeField] private LayerMask jumpableGround;

    // Start is called before the first frame update
    void Start()
    {
        localScale = transform.localScale;
        rb = GetComponent<Rigidbody2D>();
        ani = GetComponent<Animator>();
        coll = GetComponent<BoxCollider2D>();
        dir_X = -1f;
    }

    // Update is called once per frame
    void Update()
    {
        if (Input.GetKey(KeyCode.LeftArrow))
        {
            ani.SetBool("isRunning", true);
            float horizontalInput = Input.GetAxis("Horizontal");
            Vector3 direction = new Vector3(horizontalInput, 0, 0);
            rb.transform.Translate(direction * _speed * Time.deltaTime);
            dir_X = 1f;
        }
        else if (Input.GetKey(KeyCode.RightArrow))
        {
            ani.SetBool("isRunning", true);
            float horizontalInput = Input.GetAxis("Horizontal");
            Vector3 direction = new Vector3(horizontalInput, 0, 0);
            rb.transform.Translate(direction * _speed * Time.deltaTime);
            dir_X = -1f;
        }
        else
        {
            ani.SetBool("isRunning", false);
        }

        if (Input.GetKeyDown(KeyCode.Space) && IsGrounded())
        {
            jumpSoundEffect.Play();
            rb.velocity = new Vector2(rb.velocity.x, 5f);
            ani.SetTrigger("jump");
        }

    }

    private void LateUpdate()
    {
        CheckWhereToFace();
    }
    void CheckWhereToFace()
    {
        if (dir_X > 0)
            facingRight = true;
        else if (dir_X < 0)
        {
            facingRight = false;
        }
        if (((facingRight) && (localScale.x < 0)) || (!facingRight) && (localScale.x > 0))
        {
            localScale.x *= -1;
        }
        transform.localScale = localScale;
    }
    private bool IsGrounded()
    {
        return Physics2D.BoxCast(coll.bounds.center, coll.bounds.size, 0f, Vector2.down, .1f, jumpableGround);
    }

}
