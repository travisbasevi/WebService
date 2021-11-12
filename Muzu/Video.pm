package WebService::Muzu::Video;

use 5.006;
use strict;
use warnings;

use Carp;
use XML::LibXML;
use LWP::UserAgent;
use URI ();
use JSON ();

use utf8;
use Encode;

use Time::HiRes;
use Digest::SHA;
use Digest::MD5;
use MIME::Base64;

use parent 'WebService::Muzu::Base';

my %month2num = qw(Jan 01 Feb 02 Mar 03 Apr 04 May 05 Jun 06 Jul 07 Aug 08 Sep 09 Oct 10 Nov 11 Dec 12);

=head1 NAME

WebService::Muzu - The great new WebService::Muzu!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use WebService::Muzu;

    my $foo = WebService::Muzu->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub _init
	{
	my $self = shift;
	$self->SUPER::_init(@_);

	#$hash->{soundoff} = "n";
	#$hash->{autostart} = "n";
	$self->{_query}->{videotype} = "hq";
	# width
	# height
	# includeAll

	$self->{url_base} = "http://www.muzu.tv/api/video/details";
	}

=head2 aname

Sets the artist name to be used in the search

=cut

sub get_results_by_video_id
	{
	my $self = shift;
	my $id = shift;

	my $doc = $self->fetch_doc({id => $id});

	$self->{_result} = {};
	$self->load_node($doc->findnodes('/video'));

	return $self;
	}

sub video
	{
	return shift;
	}

sub max_resolution
	{
	my $self = shift;

	my $max_resolution = 0;
	foreach my $k (keys %{$self->{_result}})
		{
		if ($k =~ /^v(\d+)p$/ && $self->{_result}->{$k})
			{
			$max_resolution = $1 > $max_resolution ? $1 : $max_resolution;
			}
		}

	return $max_resolution;
	}

sub download
	{
	my $self = shift;
	my %dl_hash = @_;

#	if (!$dl_hash{viewhash})
#		{
#		croak "cannot download without a viewhash argument";
#		}

	if ($self->{_result}->{embed})
		{
		my $embed = $self->{_result}->{embed};
		$embed =~ s/\&/&amp;/g;
		$embed =~ s/(<\/object>).+$/$1/sg;

		#use Data::Dumper;
		#print Dumper($embed);

		my $doc = XML::LibXML->load_xml(string => $embed);
		my $url1;
		foreach my $param ($doc->findnodes('/object/param'))
			{
			my %attr = ();
			foreach my $a ($param->attributes())
				{
				$attr{$a->localName} = $a->getValue;
				}
			if ($attr{'name'} eq 'movie')
				{
				$url1 = $attr{'value'};
				last;
				}
			}

		if ($url1)
			{
			#my $ua = $self->{useragent};
			my $ua = LWP::UserAgent->new(max_redirect => 0);
			$ua->timeout(600); # 10 minute timeout
			$ua->default_header('User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:16.0) Gecko/20100101 Firefox/16.0'); # appears to ban on libwww-perl
			if ($dl_hash{proxy})
				{
				$ua->proxy('http', $dl_hash{proxy});
				}

			my $r1 = $ua->get($url1);
			if ($r1->code == 302)
				{
				my $url2 = $r1->header('location');
				my $uri2 = URI->new($url2);
				my %qs2 = $uri2->query_form();
				if ($qs2{p})
					{
					my $json2 = JSON->new->utf8(1)->decode($qs2{p});

					my $uri3 = URI->new($json2->{serverURL});
					$uri3->path('/player/playerInit');
					$uri3->query_form([
						pi => 0,
						areaName => $json2->{areaName},
						ai => $json2->{vidId},
						ni => $json2->{t},
						country => $json2->{country},
						hostName => '',
						randomVideo => 'false',
						networkVersion => $json2->{networkVersion},
						jbMode => 'false',
						loadAll => 'false',
						device => $json2->{device},
						]);
					my $url3 = $uri3->as_string;
					# this doesn't supply anything useful (looking for viewhash)
					#my $r3 = $ua->get($url3);
					#if ($r3->is_success)
					#	{
					#	my $json3 = JSON->new->decode($r3->decoded_content(charset => 'UTF-8'));
					#	}

					my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
					my $stime = gmtime($seconds);
					$stime =~ s/ (\d\d\d\d)$/ GMT-0000 $1/;
					my $viewhash = MIME::Base64::encode_base64(Digest::SHA::sha256($stime . substr($microseconds,0,3) . Digest::SHA::sha1_base64(time()) . $json2->{vidId}));
					$viewhash =~ s/[^a-zA-Z 0-9]+//g; # superfluous? that's what the source code does

					my $uri4 = URI->new('http://player.muzu.tv/player/requestVideo');
					$uri4->query_form([
						qv => $self->max_resolution,
						ai => $json2->{vidId},
						cn => 0, # count number in playlist?
						tm => 0, # offset in seconds
						networkVersion => '1265919724', # $json2->{networkVersion},
						vt => 'y',
						country => $json2->{country},
						viewhash => $viewhash, #$dl_hash{viewhash},
						hostName => 'http://www.muzu.tv',
						areaName => 'channel', # $json2->{areaName},
						playlistId => 0,
						ni => '81467', # $json2->{t},
						device => 'web.onsite', # $json2->{device},
						]);

					my $url4 = $uri4->as_string;

					my $r4 = $ua->get($url4);
					if ($r4->is_success)
						{
						my $json4 = JSON->new->utf8(1)->decode($r4->decoded_content);

						if ($json4->{url} eq "http://player.muzu.tv/player/invalidVideo")
							{
							carp "cannot download video: \"invalidVideo\"";
							return undef;
							}
						elsif ($json4->{url} eq "http://player.muzu.tv/player/invalidDevice")
							{
							carp "cannot download video: \"invalidDevice\"";
							return undef;
							}
						elsif ($json4->{url} eq "http://player.muzu.tv/player/invalidTerritory")
							{
							carp "cannot download video: \"invalidTerritory\"";
							return undef;
							}
						else
							{
							my $uri5 = URI->new($json4->{url});
							my ($ext) = $uri5->path =~ /.+\.(.+)$/;
							#my $filename = "D:/Video/Music/Youtube/" . $json2->{vidId} . "." . $ext;
							my $filename = $json2->{vidId} . "." . $ext;
							my $url5 = $uri5->as_string;
							my $r5 = $ua->get($url5, ':content_file' => $filename);
							if ($r5->is_success)
								{
								#my $size_header = $ua->default_header("Content-Length");
								#my $size_file = (stat($filename))[7];
								#if ($size_header != $size_file)
								#	{
								#	carp sprintf("warning! byte lengths do not match: header %d != file %d", $size_header, $size_file);
								#	}

								my $size_file = (stat($filename))[7];
								if ($size_file < 1024*1024)
									{
									carp sprintf("error downloading $url5: file is too small: %d", $size_file);
									return undef;
									}
								else
									{
									#print "file written to $filename\n";
									return $filename;
									}
								}
							elsif ($r5->code == 403)
								{
								carp "cannot download video: 403 Forbidden";
								return undef;
								}
							else
								{
								croak "error downloading $url5: ", $r5->status_line;
								}
							}
						}
					else
						{
						croak "error downloading $url4: ", $r4->status_line;
						}
					}
				else
					{
					croak "unknown query string for url $url1: p not found";
					}
				}
			elsif ($r1->code == 500 && $r1->status_line =~ /Connection refused/)
				{
				carp "cannot download video: \"Connection refused\"";
				return undef;
				}
			else
				{
				croak "302 expected for url $url1: ", $r1->status_line;
				}
			}
		else
			{
			croak "cannot find movie value in embed html: ", $embed;
			}
		}
	else
		{
		croak "no embed html found to parse for download (have you loaded a video into the object?)";
		}
	}

=head2 channel_vanityname

Channel vanityname which can then be passed to ::Channel get_results_by_vanity_name

=cut

sub channel_vanityname
	{
	my $self = shift;
	return $self->{_result}->{channel}->{vanityname};
	}

sub thumbnails
	{
	my $self = shift;
	return @{$self->{_result}->{thumbnails}};
	}

sub load_node
	{
	my $self = shift;
	my $video = shift;

	foreach my $a ($video->attributes())
		{
		my $name = $a->localName;
		my $value = $a->getValue;
		if ($value eq 'true')
			{
			$self->{_result}->{$name} = 1;
			}
		elsif ($value eq 'false')
			{
			$self->{_result}->{$name} = 0;
			}
		elsif ($value =~ /^(\d\d)\-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\-(\d\d\d\d)$/)
			{
			$self->{_result}->{$name} = $3 . "-" . $month2num{$2} . "-" . $1;
			}
		else
			{
			$self->{_result}->{$name} = $value;
			}
		}

	foreach my $node ($video->getChildrenByTagName('*'))
		{
		my $name = $node->localName;

		if ($name eq 'title' || $name eq 'description' || $name eq 'artistname' || $name eq 'tags' || $name eq 'url' || $name eq 'embed')
			{
			my $value = $node->to_literal;
			if (defined $value)
				{
				$value =~ s/^\s+|\s+$//g;
				}
			$self->{_result}->{$name} = $value;
			}
		elsif ($name eq 'image')
			{
			my $i = WebService::Muzu::Image->new();
			$i->load_node($video->findnodes('./image'));
			$self->{_result}->{image} = $i;
			}
		elsif ($name eq 'thumbnails')
			{
			$self->{_result}->{thumbnails} = [];
			foreach my $image ($video->findnodes('./thumbnails/image'))
				{
				my $i = WebService::Muzu::Image->new();
				$i->load_node($image);
				push(@{$self->{_result}->{thumbnails}}, $i);
				}
			}
		elsif ($name eq 'channel')
			{
			# not a full set of channel data, thus just maintain a hash
			# could allow a $video->channel method which fetches the channel data but would imply duplication of data as it would fetch the same video data
			$self->{_result}->{channel} = {};
			my ($channel) = $video->findnodes('./channel');
			foreach my $a ($channel->attributes())
				{
				$self->{_result}->{channel}->{$a->localName} = $a->getValue;
				}
			foreach my $cnode ($channel->getChildrenByTagName('*'))
				{
				$self->{_result}->{channel}->{$cnode->localName} = $cnode->to_literal;
				$self->{_result}->{channel}->{$cnode->localName} =~ s/^\s+|\s+$//g;
				}
			}
		else
			{
			carp "unknown video childnode tag: $name";
			}
		}
	}

=head1 AUTHOR

Travis Basevi, C<< <travis at verymetalnoise.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-muzu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Muzu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
