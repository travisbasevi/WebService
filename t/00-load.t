#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WebService::YouTubeV3' ) || print "Bail out!\n";
}

diag( "Testing WebService::YouTubeV3 $WebService::YouTubeV3::VERSION, Perl $], $^X" );
