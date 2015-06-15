use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::YouTubeV3',
    AUTHOR              => q{Travis Basevi <travisb@cpan.org>},
    VERSION_FROM        => 'lib/WebService/YouTubeV3.pm',
    ABSTRACT_FROM       => 'lib/WebService/YouTubeV3.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-YouTubeV3-*' },
);
