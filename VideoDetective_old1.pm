package WebService::VideoDetective;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON -support_by_pp;
use XML::Simple;
use Digest::MD5 qw(md5_hex);
use URI ();
use URI::Escape;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::VideoDetective - Perl interface to the www.videodetective.com API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Video Detective has a developer's API documented at http://www.internetvideoarchive.com/iva/support

This module makes life easier perl-wise, building in the fetching of the
XML and the processing of it

    use WebService::VideoDetective;

    my $foo = WebService::VideoDetective->new();
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::VideoDetective> instance

=cut

sub new
	{
	#my $proto = shift;
	#my $class = ref($proto) || $proto;
	
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->_init(@_);

	return $self;
	}

sub _init
	{
	my $self = shift;
	my %config = @_;

	$self->{_result} = {};

	foreach my $k (keys %config)
		{
		if ($k eq 'useragent')
			{
			$self->{useragent} = $config{$k};
			}
		}

	$self->{useragent} ||= LWP::UserAgent->new; # to mock for testing
	$self->{url_base} = "http://api.internetvideoarchive.com/1.0/DataService";
	}

=head1 METHODS

=head2 get_video

=cut

#my $VD = WebService::VideoDetective->new();
#$VD->get_video(994211, "no-way-out");
#print $VD->download;

sub get_video
	{
	my $self = shift;
	my ($id, $title) = @_;

	$title ||= "title";
	$title =~ s/\W/-/g;
	$title =~ s/^-+|-+$//g;
	$title = lc($title);

	my $uri1 = sprintf("http://www.videodetective.com/music/%s/%d", $title, $id);
	my $doc1 = $self->_fetch_source($uri1);
	if ($doc1 =~ /ivaplayer\('ivadiv'\).setup\((\{.+?\})\);/s)
		{
		my $json1 = $1;
		my $hash1 = JSON->new->allow_singlequote(1)->decode($json1);

		my $uri2 = URI->new("http://www.videodetective.net");
		$uri2->path('/flash/players/flashconfiguration.aspx');
		$uri2->query_form([
			customerid => $hash1->{customerid},
			pversion => '5.2',
			publishedid => $hash1->{publishedid},
			playlistid => $hash1->{playlistid},
			videokbrate => $hash1->{videokbrate},
			playerid => $hash1->{playerid},
			sub => $hash1->{sub},
			fmt => $hash1->{fmt},
			]);
		my $url2 = $uri2->as_string;
		my $doc2 = $self->_fetch_source($url2);
		my $hash2 = XMLin($doc2);

		my $url3 = $hash2->{file};
		$url3 .= "&e=" . (time() + 10*60);
		$url3 .= "&h=" . md5_hex("bigbamboo" . $url3); # password/encryption format found via www.showmycode.com using swf from http://www.videodetective.net/flash/players/?pversion=5.2&playerid=365&sub=mvc3 in setConfigParam function
		my $doc3 = $self->_fetch_source($url3);
		my $hash3 = XMLin($doc3);

		#use Data::Dumper; print Dumper($hash3);

		my $doc;
		my $item = $hash3->{channel}->{item};
		foreach my $k (keys %{$item})
			{
			if ($k eq 'jwplayer:id')
				{
				$doc->{id} = $item->{$k};
				}
			elsif ($k eq 'link')
				{
				$doc->{link} = $item->{$k};
				}
			elsif ($k eq 'media:group')
				{
				$doc->{content} = $item->{$k}->{'media:content'};
				}
			elsif ($k eq 'media:thumbnail')
				{
				$doc->{thumbnail} = $item->{$k}->{url};
				}
			elsif ($k =~ /^media:(.+)$/)
				{
				$doc->{$1} = $item->{$k};
				$doc->{$1} =~ s/^\s+|\s+$//g;
				}
			}
		$self->{_result} = $doc;
		}
	}

sub max_resolution
	{
	my $self = shift;
	return $self->_max_resolution_content->{width};
	}

sub duration
	{
	my $self = shift;
	return $self->_max_resolution_content->{duration};
	}

sub filename
	{
	my $self = shift;
	my $url = $self->_max_resolution_content->{url};
	my ($filename) = ($url =~ m!.+/(.+)\?!);
	return $filename;
	}

sub _max_resolution_content
	{
	my $self = shift;

	my $max_resolution = 0;
	my $max_bitrate = 0;
	my $content = {};
	foreach my $v (@{$self->{_result}->{content}})
		{
		if ($v->{width} && $v->{width} > $max_resolution)
			{
			$max_resolution = $v->{width};
			$content = $v;
			}
		elsif ($v->{width} && $v->{bitrate} && $v->{width} == $max_resolution && $v->{bitrate} > $max_bitrate)
			{
			$max_bitrate = $v->{bitrate};
			$content = $v;
			}
		}
	foreach my $v (@{$self->{_result}->{content}})
		{
		if ($v->{bitrate} && $v->{bitrate} > $content->{bitrate})
			{
			carp "max resolution of $max_resolution does not have the max bitrate of " . $v->{bitrate};
			}
		}

	return $content;
	}

sub download
	{
	my $self = shift;
	my %dl_hash = @_;

	if ($self->_max_resolution_content->{url})
		{
		my $ua = LWP::UserAgent->new();
		$ua->timeout(600); # 10 minute timeout
		$ua->default_header('User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:18.0) Gecko/20100101 Firefox/18.0');
		if ($dl_hash{proxy})
			{
			$ua->proxy('http', $dl_hash{proxy});
			}

		my $url = $self->_max_resolution_content->{url};

		if ($self->filename)
			{
			my $r = $ua->get($url, ':content_file' => $self->filename);
			if ($r->is_success)
				{
				#my $size_header = $r3->header("Content-Length");
				#my $size_file = (stat($filename))[7];
				#if ($size_header != $size_file)
				#	{
				#	carp sprintf("warning! byte lengths do not match: header %d != file %d", $size_header, $size_file);
				#	}
				#print "file written to $filename\n";
				return $self->filename;
				}
			else
				{
				croak "error downloading $url: ", $r->status_line;
				}
			}
		else
			{
			croak "cannot find filename in $url";
			}
		}
	else
		{
		croak "no video url found to parse for download (have you loaded a video into the object?)";
		}
	}

sub _fetch_source
	{
	my $self = shift;
	my ($url) = @_;

	my $ua = LWP::UserAgent->new();
	$ua->default_header('User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:18.0) Gecko/20100101 Firefox/18.0');

	my $response = $ua->get($url);
	if ($response->is_success)
		{
		return $response->decoded_content;
		}
	else
		{
		croak "cannot get url $url: ", $response->status_line;
		}
	}

sub _fetch_doc # not yet modified for this module
	{
	my $self = shift;
	my ($type, $id, $fields) = @_;

	my $u = $self->{url_base} . "/" . $type . "/" . $id;
	if (defined($fields) && ref($fields) eq 'ARRAY')
		{
		$u .= "?fields=" . join(',', @{$fields});
		}

	my $ua = $self->{useragent};
	my $attempts = 0;
	while (1)
		{
		my $response = $ua->get($u);
		if ($response->is_success)
			{
			my $content = $response->decoded_content;

#			if (!utf8::is_utf8($content)) # since Perl 5.8.1
#				{
#				$content = decode('iso-8859-1', $content);
#				}

			if ($content)
				{
				if ($content =~ /our service is momentarily interrupted/)
					{
					carp "api unavailable, sleeping for 10s\n";
					sleep(10);
					}
				else
					{
					my $jobj = JSON->new;
					$jobj->utf8(1);

					my $doc = $jobj->decode($content);

					foreach my $k (keys %{$doc})
						{
						if ($k =~ /_time/)
							{
							my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($doc->{$k});
							$doc->{$k} = sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$year, $mon+1, $mday, $hour, $min, $sec);
							}
						}

					return $doc;
					}
				}
			else
				{
				croak "no content found for url: $u";
				}
			}
		else
			{
			croak "cannot get url $u: ", $response->status_line;
			}

		if (++$attempts >= 10)
			{
			croak "cannot get url $u after 10 attempts";
			}
		}
	}

sub artistdirect_id_to_external_source
	{
	my $self = shift;
	my ($id) = @_;

	my $url = sprintf("http://www.artistdirect.com/video/title/%d", $id);
	my $doc = $self->_fetch_source($url);
	if ($doc =~ /isVevoVideo=true/ && $doc =~ /VevoPlayer\('(.+?)'\)/)
		{
		return ('vevo', $1);
		}
	elsif ($doc =~ /externalVideoSource='IVA'/ && $doc =~ m!/a3/includes/js/ivaplayer/0,,(\d+),00\.js!)
		{
		return ('videodetective', $1);
		}
	else
		{
		carp "cannot find external source in url: $url";
		return undef;
		}
	}

sub get_names
	{
	my $self = shift;

	my @names = ();
	foreach my $key (sort keys %{$self->{_result}})
		{
		if (!ref($self->{_result}->{$key}))
			{
			push(@names, $key);
			}
		}

	return @names;
	}

sub get_value
	{
	my $self = shift;
	my $name = shift;

	if (exists $self->{_result}->{$name} && !ref($self->{_result}->{$name}))
		{
		return $self->{_result}->{$name};
		}
	else
		{
		carp "no name '$name' found in $self";
		}
	}

sub AUTOLOAD
	{
	my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*:://;

	if (exists $self->{_result} && exists $self->{_result}->{$name} && !ref($self->{_result}->{$name}))
		{
		return $self->{_result}->{$name};
		}
	else
		{
		carp "no attribute '$name' found in $self";
		}
	}

sub DESTROY # so AUTOLOAD doesn't serve it
	{
	}

=head1 AUTHOR

Travis Basevi, C<< <travis at verymetalnoise.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-dailymotion at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Dailymotion>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Dailymotion

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Dailymotion>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Dailymotion>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Dailymotion>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Dailymotion/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Dailymotion


__END__

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
					#print "file written to $filename\n";
					return $filename;
					}
				else
					{
					croak "error downloading $url5: ", $r5->status_line;
					}
				}
