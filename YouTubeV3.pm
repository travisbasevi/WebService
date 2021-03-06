package WebService::YouTubeV3;

use 5.006;
use strict;
use warnings;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Quotekeys = 0;

use lib '/data/videodb/WebService-YouTubeV3/lib';

use WebService::YouTubeV3::OAuth;

# use WebService::YouTubeV3::Activity;
# use WebService::YouTubeV3::Caption;
# use WebService::YouTubeV3::ChannelBanner;
use WebService::YouTubeV3::Channel;
# use WebService::YouTubeV3::ChannelSection;
# use WebService::YouTubeV3::Comment;
# use WebService::YouTubeV3::CommentThread;
# use WebService::YouTubeV3::GuideCategory;
# use WebService::YouTubeV3::i18nLanguage;
# use WebService::YouTubeV3::i18nRegion;
use WebService::YouTubeV3::PlaylistItem;
use WebService::YouTubeV3::Playlist;
use WebService::YouTubeV3::Search;
# use WebService::YouTubeV3::Subscription;
# use WebService::YouTubeV3::Thumbnail;
# use WebService::YouTubeV3::VideoAbuseReportReason;
# use WebService::YouTubeV3::VideoCategory;
use WebService::YouTubeV3::Video;
# use WebService::YouTubeV3::Watermark;

=head1 NAME

WebService::YouTubeV3 - The great new WebService::YouTubeV3!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WebService::YouTubeV3;

    my $foo = WebService::YouTubeV3->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Travis Basevi, C<< <travisb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-youtubev3 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-YouTubeV3>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::YouTubeV3


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-YouTubeV3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-YouTubeV3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-YouTubeV3>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-YouTubeV3/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::YouTubeV3
