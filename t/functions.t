#!/usr/bin/perl

use strict;
use warnings;
use boolean qw(true false);

use Math::Prime::XS ':all';
use Test::More tests => 17;

local $" = ',';

my $number = 100;
my @range  = (30, 70);
my @prime  = (13) x 2;

my @expected_all_primes = (
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47, 53, 59, 61, 67,
    71, 73, 79, 83, 89, 97,
);
my @expected_range_primes = (
    31, 37, 41, 43, 47, 53, 59, 61, 67,
);
my $expected_prime = $prime[0];

my @got_primes;
foreach my $num (0 .. $number) {
    push @got_primes, $num if is_prime($num);
}
is_deeply(\@got_primes, \@expected_all_primes, "is_prime() [0-$number]");

is_deeply([primes($number)],       \@expected_all_primes, "primes($number)",     );
is_deeply([mod_primes($number)],   \@expected_all_primes, "mod_primes($number)"  );
is_deeply([sieve_primes($number)], \@expected_all_primes, "sieve_primes($number)");
is_deeply([sum_primes($number)],   \@expected_all_primes, "sum_primes($number)"  );
is_deeply([trial_primes($number)], \@expected_all_primes, "trial_primes($number)");

is_deeply([primes(@range)],       \@expected_range_primes, "primes(@range)"      );
is_deeply([mod_primes(@range)],   \@expected_range_primes, "mod_primes(@range)"  );
is_deeply([sieve_primes(@range)], \@expected_range_primes, "sieve_primes(@range)");
is_deeply([sum_primes(@range)],   \@expected_range_primes, "sum_primes(@range)"  );
is_deeply([trial_primes(@range)], \@expected_range_primes, "trial_primes(@range)");

is(primes(@prime),       $expected_prime, "primes(@prime)"      );
is(mod_primes(@prime),   $expected_prime, "mod_primes(@prime)"  );
is(sieve_primes(@prime), $expected_prime, "sieve_primes(@prime)");
is(sum_primes(@prime),   $expected_prime, "sum_primes(@prime)"  );
is(trial_primes(@prime), $expected_prime, "trial_primes(@prime)");

{
    # rt #62632
    my $number = 2000000;
    my $prime  = 1928099;

    my $found = false;
    foreach my $p (sieve_primes($number)) {
        if ($p == $prime) {
            $found = true;
            last;
        }
    }
    ok($found, "sieve_primes($number) - prime $prime not returned");
}
