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

/* ULONG_MAX_IS_ODD_COMPOSITE is true if ULONG_MAX is odd and composite.
   Checking mod 3 is enough to detect 2^32-1 and 2^64-1 (and other even
   number of bits).  */
#define ULONG_MAX_IS_ODD_COMPOSITE              \
  ((ULONG_MAX % 2) == 0 || (ULONG_MAX % 3) == 0)

enum { false, true };

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
      /* For the sqrt(), casting double->ulong probably follows the fpu
         rounding mode, so might round either up or down.  If up then the
         last trial division may be unnecessary, but not harmful.
       */

      /* special case for 2 if it's in range, then can use n+=2 for odd n in
         the loop */
      if (base <= 2) {
        base = 3;
        if (number >= 2) {
          XPUSHs (sv_2mortal(newSVuv(2)));
        }
      }

      /* next higher odd number, if not odd already */
      base |= 1;

      /* If number==ULONG_MAX then n<=number is always true and would be an
         infinite loop.  If ULONG_MAX and ULONG_MAX-1 are both composites
         (which is so for 2^32-1 and 2^64-1) then can stop before them, by
         shortening "number" to ULONG_MAX-2.  If not (some strange ULONG_MAX
         value) then check for n>=ULONG_MAX-1 below so n+=2 doesn't
         overflow.
       */
      if (ULONG_MAX_IS_ODD_COMPOSITE) {
        /* usual case of 2^32-1 or 2^64-1 */
        if (number > ULONG_MAX-2)
          number = ULONG_MAX-2;
      }

      for (n = base; n <= number; n += 2)
        {
          unsigned long limit = (unsigned long) sqrt(n);
          for (i = 3; i <= limit; i+=2)
            {
              if (n % i == 0)
                goto NEXT_OUTER;
            }
          /* (n % 1 == 0) && (n % n == 0) */
          XPUSHs (sv_2mortal(newSVuv(n)));

        NEXT_OUTER:
          if (! ULONG_MAX_IS_ODD_COMPOSITE) { /* some unusual ULONG_MAX */
            if (n >= ULONG_MAX-1)
              break;
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
