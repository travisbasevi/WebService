package WebService::YouTubeV3::Playlist;

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

    my $yt = WebService::YouTubeV3::Playlist->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub _init
	{
	my $self = shift;
	$self->SUPER::_init(@_);
	$self->{url_base} = "https://www.googleapis.com/youtube/v3/playlists";
	$self->{kind} = "youtube#playlist";
	$self->{get_default} ||= ['snippet','contentDetails'];
	$self->{set_default} ||= ['snippet'];
	}

=head2 fetch

Returns a video by id

$video = $yt->fetch($video_id);
$video = $yt->fetch($video_id, [$part1, $part2]);

=cut

sub list_by_channel
	{
	my $self = shift;
	my ($name, $part, $limit) = @_;

	my $ytc = $self->spawn('Channel');
	$ytc->fetch_by_name($name, 'id');

	my $yts = $self->spawn('Search');
	my @ids = ();
	foreach my $s ( $yts->list(undef, undef, {'channelId' => $ytc->id, 'order' => 'date', 'type' => 'playlist'}, $limit) )
		{
		push(@ids, $s->id_playlistId);
		}

	my @list = ();
	while (@ids) # get error 413 if too many ids in query string
		{
		my @sids = splice(@ids, 0, 50);
		@ids = splice(@ids, 50);
		push(@list, $self->list($part, {'id' => \@sids}, undef, $limit))
		}

	return @list;
	}

=head2 list

Returns a list of playlists

@playlists = $yt->list(\@part, \%filter, \%optional, $limit);

=cut

=head2 playlistitems

Returns the fetched playlist items

@playlistitems = $yt->playlistitems;
@playlistitems = $yt->playlistitems([$part1, $part2]);

=cut

sub list_item
	{
	my $self = shift;
	my ($part, $limit) = @_;

	my $id = $self->id;

	my $pli = $self->spawn('PlaylistItem');

	return $pli->list($part, {'playlistId' => $id}, undef, $limit);
	}

sub list_video
	{
	my $self = shift;
	my ($part, $limit) = @_;

	my $id = $self->id;

	my $pli = $self->spawn('PlaylistItem');

	my @ids = ();
	foreach my $i ( $pli->list('contentDetails', {'playlistId' => $id}, undef, $limit) )
		{
		push(@ids, $i->contentDetails_videoId);
		}

	return $self->list($part, {'id' => \@ids}, undef, $limit);
	}

sub insert_video
	{
	my $self = shift;
	my ($v) = @_;

	if (!ref($v))
		{
		my $video_id = $v;
		$v = $self->spawn('Video');
		if (! $v->fetch($video_id, 'id'))
			{
			return 0;
			}
		}

	my $pli = $self->spawn('PlaylistItem');
	$pli->snippet_playlistId($self->id);
	$pli->snippet_resourceId($v->make_resource_id);

	return $pli->insert;
	}

sub delete_item_all
	{
	my $self = shift;

	my $count = 0;
	foreach my $pli ($self->list_item('id', 0))
		{
		$count += $pli->delete;
		}

	return $count;
	}

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
