#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::DCT' ) || print "Bail out!\n";
}

diag( "Testing Math::DCT $Math::DCT::VERSION, Perl $], $^X" );
