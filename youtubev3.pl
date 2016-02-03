#!/usr/bin/perl

use strict;
use warnings;
use v5.10;
use Carp;

use utf8;
use Encode;
binmode(STDOUT, ":utf8");

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Quotekeys = 0;

$| = 1;
open(STDERR, ">&STDOUT");

use lib '/data/videodb/WebService-YouTubeV3/lib';

use WebService::YouTubeV3;

my %config;
$config{client_secrets_file} = '/data/videodb/google_client_secrets.json';
$config{access_token_file} = '/data/videodb/google_access_token.json';
my $ytv = WebService::YouTubeV3::Video->new(%config);
#print Dumper($ytv);
$ytv->fetch('kK_1h7gGZ0U', ['snippet', 'contentDetails']);
print Dumper($ytv);

exit;

my $yt = WebService::YouTubeV3::PlaylistItem->new(%config);
print Dumper( $yt->list('contentDetails', {'playlistId' => 'PLB772FEEA50714FBA'}, undef, 5) );

exit;

my $ytp = WebService::YouTubeV3::Playlist->new(%config);
$ytp->fetch('B772FEEA50714FBA');
print Dumper($ytp->list_video);

exit;

my $ytc = WebService::YouTubeV3::Channel->new(%config);
my $channel_id = $ytc->fetch_by_name('IndianaVEVO', 'id')->id;
my $yts = WebService::YouTubeV3::Search->new(%config);
print Dumper($yts->list(undef, undef, {'channelId' => $channel_id, 'order' => 'date', 'type' => 'video'}));

exit;


#$p->delete_all_playlistitems;

#my @pli = $p->playlistitems;
#$pli[0]->delete;

#my $yt = WebService::YouTubeV3::PlaylistItem->new(%config);
#$yt->fetch('PLVUeaYHfpyQnFHYlNPo7Ttw39NSyW_vJ8SYnIyGEObsg');
#print Dumper($yt);
#$yt->delete;


exit;

my $ytv = WebService::YouTubeV3::Video->new(%config);
my $v = $ytv->fetch('1lAZdQ7NxV8');

my $yt = WebService::YouTubeV3::PlaylistItem->new(%config);
$yt->id('PLVUeaYHfpyQnFHYlNPo7Ttw39NSyW_vJ8SYnIyGEObsg');
$yt->snippet_playlistId('PLbSSXvZypB84QRshGKULA06eQUwyIHT8E');
$yt->snippet_resourceId($v->make_resource_id);
$yt->snippet_position(5);
$yt->update;
print Dumper($yt);

exit;

my $v = $ytv->fetch('vmlZGBikjgU');
print Dumper($v);

exit;

$ytv->blah('bleh');
$ytv->foo_bar({'beep' => 'val'});
$ytv->foo_bar_baa('beep');
#print Dumper($ytv->{_set});

exit;


my $yt = WebService::YouTubeV3::Playlist->new(%config);
my @s = $yt->fetch_by_channel('rageabc');
#my @s = $yt->list(undef, undef, {'channelId' => 'UCjiqmRU94m41huo9myUz7QA', 'order' => 'date'});
print Dumper(\@s);


__END__

my $ytp = WebService::YouTubeV3::Playlist->new(%config);
my $p = $ytp->fetch('PLbSSXvZypB84nvA7dsiKKgxg1a6JHWI9r');
say $p->etag;
say $p->contentDetails_itemCount;
print Dumper($p);
print Dumper({$p->get_result});


#my @pli = $p->playlistitems;
#print Dumper(\@pli);


my $ytv = WebService::YouTubeV3::Video->new(%config);
my $c = $ytv->clone;
print Dumper($ytv, $c);

my $v = $ytv->fetch('dpiGr4CDqOE');
say $v->etag;
say $v->snippet_description;
print Dumper($v->snippet_thumbnails_default);
print Dumper($v);
#print Dumper($ytv);

                                contentDetails => {
                                                    caption => 'false',
                                                    definition => 'sd',
                                                    dimension => '2d',
                                                    duration => 'PT3M57S',
                                                    licensedContent => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
                                                    regionRestriction => {
                                                                           allowed => [
                                                                                        'AS',
                                                                                        'AR',
                                                                                        'BR',
                                                                                        'AU',
                                                                                        'CX',
                                                                                        'CR',
                                                                                        'CO',
                                                                                        'BO',
                                                                                        'CA',
                                                                                        'AW',
                                                                                        'CC',
                                                                                        'EC',
                                                                                        'PE',
                                                                                        'NZ',
                                                                                        'PA',
                                                                                        'UM',
                                                                                        'HM',
                                                                                        'HN',
                                                                                        'GT',
                                                                                        'NF',
                                                                                        'MX',
                                                                                        'MF',
                                                                                        'PR',
                                                                                        'NI',
                                                                                        'UY',
                                                                                        'VE',
                                                                                        'PY',
                                                                                        'VI',
                                                                                        'US',
                                                                                        'JP',
                                                                                        'SV'
                                                                                      ]
                                                                         }
                                                  },

                               player => {
                                            embedHtml => '<iframe type=\'text/html\' src=\'http://www.youtube.com/embed/SAFv2NEE-_c\' width=\'640\' height=\'360\' frameborder=\'0\' allowfullscreen=\'true\'/>'
                                          }

                                snippet => {
                                             categoryId => '10',
                                             channelId => 'UCCQd3l-XmXQ7C2fI6rH41dw',
                                             channelTitle => 'MidnightOilVEVO',
                                             description => 'Music video by Midnight Oil performing US Forces. (C) 1997 Midnight Oil',
                                             liveBroadcastContent => 'none',
                                             localized => {
                                                            description => 'Music video by Midnight Oil performing US Forces. (C) 1997 Midnight Oil',
                                                            title => 'Midnight Oil - US Forces'
                                                          },
                                             publishedAt => '2009-10-03T19:25:49.000Z',
                                             thumbnails => {
                                                             default => {
                                                                          height => 90,
                                                                          url => 'https://i.ytimg.com/vi/SAFv2NEE-_c/default.jpg',
                                                                          width => 120
                                                                        },
                                                             high => {
                                                                       height => 360,
                                                                       url => 'https://i.ytimg.com/vi/SAFv2NEE-_c/hqdefault.jpg',
                                                                       width => 480
                                                                     },
                                                             medium => {
                                                                         height => 180,
                                                                         url => 'https://i.ytimg.com/vi/SAFv2NEE-_c/mqdefault.jpg',
                                                                         width => 320
                                                                       }
                                                           },
                                             title => 'Midnight Oil - US Forces'
                                           }

                                statistics => {
                                                commentCount => '366',
                                                dislikeCount => '25',
                                                favoriteCount => '0',
                                                likeCount => '588',
                                                viewCount => '184366'
                                              }
   
                                   status => {
                                            embeddable => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
                                            license => 'youtube',
                                            privacyStatus => 'public',
                                            publicStatsViewable => $VAR1->{_result}[0]{status}{embeddable},
                                            uploadStatus => 'processed'
                                          }

                                topicDetails => {
                                                  relevantTopicIds => [
                                                                        '/m/014psz',
                                                                        '/m/016clz',
                                                                        '/m/04rlf',
                                                                        '/m/09lgd'
                                                                      ],
                                                  topicIds => [
                                                                '/m/0136b0',
                                                                '/m/0mltxr'
                                                              ]
                                                }
