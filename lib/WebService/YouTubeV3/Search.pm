package WebService::YouTubeV3::Search;

use 5.006;
use strict;
use warnings;

use Carp;
use URI ();
use URI::QueryParam;

use parent 'WebService::YouTubeV3::Base';

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

    my $yt = WebService::YouTubeV3::Search->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub _init
	{
	my $self = shift;
	$self->SUPER::_init(@_);
	$self->{url_base} = "https://www.googleapis.com/youtube/v3/search";
	$self->{get_default} ||= ['snippet'];
	}

=head2 list

Returns a list of search results

@search = $yt->list(\@part, \%filter, \%optional, $limit);

=cut

=head1 AUTHOR

Travis Basevi, C<< <travisb at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-youtubev3 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-YouTubeV3>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
