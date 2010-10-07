#!/usr/bin/perl

use strict;
use warnings;

use Math::Prime::XS ':all';
use Test::More tests => 11;

local $" = ',';

my $number = 100;
my @range = (30, 70);

my @expected_all_primes = (
    2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
    31, 37, 41, 43, 47, 53, 59, 61, 67,
    71, 73, 79, 83, 89, 97,
);
my @expected_range_primes = (
    31, 37, 41, 43, 47, 53, 59, 61, 67,
);

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
