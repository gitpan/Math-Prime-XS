#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef CHAR_BIT
# define BYTE_BITS CHAR_BIT /* limits.h */
#else
# define BYTE_BITS 8        /* at least 8 bits wide */
#endif

#define BIT_VECTOR(num) ((num) / 2) /* double space for uneven numbers */

#define EVEN_NUM(num) ((num) % 2 == 0)

#define NUM_SET(num_entry, var_ptr, num_pos, num_val) \
    (*num_entry).ptr = var_ptr;                       \
    (*num_entry).pos = num_pos;                       \
    (*num_entry).val = num_val;                       \

#define NUM_LEN(nums) (sizeof (nums) / sizeof (num_entry))

#ifndef I_STDBOOL
enum { false, true };
#endif

typedef struct {
    unsigned long **ptr;
    unsigned int pos;
    unsigned long val;
} num_entry;

static void
store (const num_entry *numbers, unsigned int len, unsigned int *pos)
{
    unsigned int i;
    for (i = 0; i < len; i++)
      {
        unsigned long **p      = numbers[i].ptr;
        const unsigned int pos = numbers[i].pos;
        if (*p)
          {
            Renew (*p, pos + 1, unsigned long);
            Zero  (*p + pos, 1, unsigned long);
          }
        else
          Newxz (*p, 1, unsigned long);
        (*p)[pos] = numbers[i].val;
      }
    if (pos) /* keep it optional */
      (*pos)++;
}

MODULE = Math::Prime::XS                PACKAGE = Math::Prime::XS

void
xs_mod_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long i, n;
    PPCODE:
      for (n = 2; n <= number; n++)
        {
          bool is_prime = true;
          if (n > 2 && EVEN_NUM (n))
            continue;
          for (i = 2; i < n; i++)
            {
              if (n % i == 0)
                {
                  is_prime = false;
                  break;
                }
            }
          /* (n % 1 == 0) && (n % n == 0) */
          if (is_prime && n >= base)
            {
              EXTEND (SP, 1);
              PUSHs (sv_2mortal(newSVuv(n)));
            }
        }

void
xs_sieve_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long *composite = NULL;
      unsigned long i, n;
    PPCODE:
      const unsigned long square_root = sqrt (number); /* truncates */
      const unsigned int size_bits = sizeof (unsigned long) * BYTE_BITS;

      Newxz (composite, (BIT_VECTOR (number) / size_bits) + 1, unsigned long);

      for (n = 3; n <= square_root; n += 2) /* uneven numbers only */
        {
          /* (n * n) - start with square */
          /* (2 * n) - skip even number  */
          for (i = (n * n); i <= number; i += (2 * n))
            {
              const unsigned int bits  = BIT_VECTOR (i - 2) % size_bits;
              const unsigned int field = BIT_VECTOR (i - 2) / size_bits;

              composite[field] |= (unsigned long)1 << bits;
            }
        }
      for (n = 2; n <= number; n++)
        {
          if (n > 2 && EVEN_NUM (n))
            continue;
          else if (!EVEN_NUM (n) && composite[BIT_VECTOR (n - 2) / size_bits] & ((unsigned long)1 << (BIT_VECTOR (n - 2) % size_bits)))
            continue;
          else if (n >= base)
            {
              EXTEND (SP, 1);
              PUSHs (sv_2mortal(newSVuv(n)));
            }
        }

      Safefree (composite);

void
xs_sum_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long *primes = NULL, *sums = NULL;
      unsigned int pos = 0;
      unsigned long n;
    PPCODE:
      for (n = 2; n <= number; n++)
        {
          bool is_prime = true;
          const unsigned long square_root = sqrt (n); /* truncates */
          unsigned int c;
          for (c = 0; c < pos && primes[c] <= square_root; c++)
            {
              unsigned long sum = sums[c];
              while (sum < n)
                sum += primes[c];
              sums[c] = sum;
              if (sum == n)
                {
                  is_prime = false;
                  break;
                }
            }
          if (is_prime)
            {
              num_entry numbers[2];
              NUM_SET (&numbers[0], &primes, pos, n);
              NUM_SET (&numbers[1], &sums,   pos, 0);
              store (numbers, NUM_LEN (numbers), &pos);

              if (n >= base)
                {
                  EXTEND (SP, 1);
                  PUSHs (sv_2mortal(newSVuv(n)));
                }
            }
        }

      Safefree (primes);
      Safefree (sums);

void
xs_trial_primes (number, base)
      unsigned long number
      unsigned long base
    PROTOTYPE: $$
    INIT:
      unsigned long *primes = NULL;
      unsigned int pos = 0;
      unsigned long start = 1;
      unsigned long i, n;
    PPCODE:
      for (n = 2; n <= number; n++)
        {
          bool is_prime = true;
          unsigned long square_root; /* calculate later for efficiency */
          if (n > 2 && EVEN_NUM (n))
            continue;
          square_root = sqrt (n); /* truncates */
          for (i = start; i <= square_root; i++)
            {
              bool save_as_prime = true;
              unsigned long c;
              /* not prime */
              if (i == 1)
                continue;
              /* even number */
              else if (EVEN_NUM (i))
                continue;
              /* number to resume from equals square root */
              else if (start == square_root)
                continue;
              /* check for non-uniqueness */
              else if (primes && i <= primes[pos - 1])
                continue;
              for (c = 2; c < i; c++)
                {
                  if (i % c == 0)
                    {
                      save_as_prime = false;
                      break;
                    }
                }
              /* (i % 1 == 0) && (i % i == 0) */
              if (save_as_prime)
                {
                  num_entry numbers[1];
                  NUM_SET (&numbers[0], &primes, pos, i);
                  store (numbers, NUM_LEN (numbers), &pos);
                }
            }
          if (primes)
            {
              unsigned int c;
              for (c = 0; c < pos; c++)
                {
                  if (n % primes[c] == 0)
                    {
                      is_prime = false;
                      break;
                    }
                }
            }
          if (is_prime && n >= base)
            {
              EXTEND (SP, 1);
              PUSHs (sv_2mortal(newSVuv(n)));
            }
          /* Optimize calculating the minor primes for trial division
             by starting from the previous square root.  */
          start = square_root;
        }

      Safefree (primes);
