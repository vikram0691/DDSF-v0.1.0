#!perl -T
use v5.014;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DDSF' ) || print "Bail out!\n";
}

diag( "Testing DDSF $DDSF::VERSION, Perl $], $^X" );
