package WebService::YouTubeV3::Video;

use 5.006;
use strict;
use warnings;

use Carp;
use URI ();
use URI::QueryParam;

use Data::Dumper;
use JSON;

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

    my $yt = WebService::YouTubeV3::Video->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub _init
	{
	my $self = shift;
	$self->SUPER::_init(@_);
	$self->{url_base} = "https://www.googleapis.com/youtube/v3/videos";
	$self->{kind} = "youtube#video";
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
	foreach my $s ( $yts->list(undef, undef, {'channelId' => $ytc->id, 'order' => 'date', 'type' => 'video'}, $limit) )
		{
		push(@ids, $s->id_videoId);
		}

	return $self->list($part, {'id' => \@ids}, undef, $limit);
	}

sub list_related
	{
	my $self = shift;
	my ($part, $limit) = @_;

	my $yts = $self->spawn('Search');
	my @ids = ();
	foreach my $s ( $yts->list(undef, {'relatedToVideoId' => $self->id}, {'type' => 'video'}, $limit) )
		{
		push(@ids, $s->id_videoId);
		}

	return $self->list($part, {'id' => \@ids}, undef, $limit);
	}

=head2 list

Returns a list of videos

@videos = $yt->list(\@part, \%filter, \%optional, $limit);

=cut

sub relatedVideoId
	{
	my $self = shift;
	my ($limit) = @_;

	my $yts = $self->spawn('Search');
	my @ids = ();
	foreach my $s ( $yts->list(undef, {'relatedToVideoId' => $self->id}, {'type' => 'video'}, $limit) )
		{
		push(@ids, $s->id_videoId);
		}

	return @ids;
	}

sub contentDetails_regionRestriction
	{
	# this does not reliably appear - especially for removed videos/accounts
	my $self = shift;
	return $self->check_value('contentDetails_regionRestriction') ? $self->get_value('contentDetails_regionRestriction') : {};
	}

sub duration_in_seconds
	{
	my $self = shift;

	my $duration = $self->contentDetails_duration;
	if ($duration =~ /^PT((\d+)H)?((\d+)M)?((\d+)S)?$/)
		{
		return 3600*($2 || 0) + 60*($4 || 0) + ($6 || 0);
		}
	else
		{
		carp "unknown contentDetails_duration format: ", $duration;
		}
	}

sub publishedat_iso9075
	{
	my $self = shift;

	my $publishedat = $self->snippet_publishedAt;
	if ($publishedat =~ /^(\d\d\d\d-\d\d-\d\d)T(\d\d:\d\d:\d\d)(\.\d\d\d)?Z$/)
		{
		return "$1 $2";			
		}
	else
		{
		carp "unknown snippet_publishedAt format: ", $publishedat;
		}
	}

sub tags_as_keywords
	{
	my $self = shift;

	if ($self->{_get}->{snippet} && $self->{_get}->{snippet}->{tags}) # doesn't exist for every video
		{
		my $tags = $self->snippet_tags;
		if ($tags && ref($tags) eq "ARRAY")
			{
			return join(", ", @{$tags});
			}
		else
			{
			return "";
			}
		}
	else
		{
		return "";
		}
	}

sub fetch_ytdlp
	{
	my $self = shift;

	my ($id) = @_;
	if ($id)
		{
		$self->id($id);
		}

	if (!$self->{_get}->{ytdlp})
		{
		my $uri = URI->new("https://www.youtube.com/watch");
		$uri->query_param('v', $self->id);
		my $url = $uri->as_string;

		my $JSON = JSON->new->utf8;
		my $json = `/usr/local/bin/yt-dlp -J "$url"`;
		$self->{_get}->{ytdlp} = $JSON->decode($json);

		# print Dumper($self->{_get}->{ytdlp});
		}

	return $self->{_get}->{ytdlp};
	}

sub ytdlp_formats
	{
	my $self = shift;

	my ($id) = @_;
	if ($id)
		{
		$self->id($id);
		}

	my $ytdlp = $self->fetch_ytdlp($id);
	# print Dumper($ytdlp->{formats});

	foreach my $f (@{$ytdlp->{formats}})
		{
		foreach my $k (keys %{$f})
			{
			if (!defined($f->{$k}))
				{
				$f->{$k} = undef;	
				}
			elsif (ref($f->{$k}))
				{
				delete($f->{$k});
				}
			elsif ($f->{$k} eq 'none')
				{
				$f->{$k} = undef;	
				}
			}
		}

	return $ytdlp->{formats};
	}

sub _none2undef
	{
	# gone blank on how to do this properly with scalarrefs. TUMOUR!
	# so operating direct on the refs in $self->ytdlp_formats

	my $obj = shift;

	if (!defined($obj))
		{
		return undef;
		}
	elsif (ref($obj) eq 'HASH')
		{
		foreach my $k (keys %{$obj})
			{
			&_none2undef($obj->{$k});
			}
		}
	elsif (ref($obj) eq 'ARRAY')
		{
		foreach my $a (@{$obj})
			{
			&_none2undef($a);
			}
		}
	elsif (!ref($obj) && defined($obj) && $obj eq 'none')
		{
		return undef;
		}
	else
		{
		return \$obj;
		}
	}


=head1 AUTHOR

Travis Basevi, C<< <travisb at cpan.org> >>

=head1 QUICK SYNC

rsync -avz /home/travis/lib/WebService coyote:/home/travis/lib/ --dry-run

cd /home/travis/lib/WebService
git add .; git commit; git push

cd /home/travis/lib/WebService
git pull

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
