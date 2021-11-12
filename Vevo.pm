package WebService::Vevo;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON;
use XML::Simple;
use URI ();
use URI::Escape;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::Vevo - Perl interface to the www.vevo.com

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Vevo gives a JSON response at: 
http://videoplayer.vevo.com/VideoService/AuthenticateVideo?isrc=VEVOID

This module makes life easier perl-wise, building in the fetching of the
JSON and the processing of it

    use WebService::Vevo;

    my $foo = WebService::Vevo->new();
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::Vevo> instance

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
	$self->{url_base} = "http://videoplayer.vevo.com/VideoService/AuthenticateVideo";
	}




=head1 METHODS

=head2 get_video

=cut

#my $VEVO = WebService::Vevo->new();
#$VEVO->get_video('USMRG1141599');
#$VEVO->get_video('USUV71002949');
#use Data::Dumper; print Dumper($VEVO->{_result});
#print $VEVO->title, "\n";
#print $VEVO->max_resolution, "\n";

sub get_video
	{
	my $self = shift;
	my ($id) = @_;

	my $uri = URI->new("http://videoplayer.vevo.com");
	$uri->path('/VideoService/AuthenticateVideo');
	$uri->query_form([
		isrc => $id,
		domain => 'www.vevo.com',
		authToken => 'ILL2VEVO-6EF1-4955-9588-3926DAEA9KGF',
		pkey => 'bb8a16ab-1279-4f17-969b-1dba5eb60eda',
		]);
	my $url = $uri->as_string;
	my $doc = $self->_fetch_doc($url);

	my $result = {};
	$result->{isApproved} = $doc->{isApproved};
	if ($doc->{video})
		{
		foreach my $k (keys %{$doc->{video}})
			{
			if ($k eq "metadata")
				{
				foreach my $m (@{$doc->{video}->{$k}})
					{
					$result->{$m->{keyType}} = $m->{keyValue};
					}
				}
			else
				{
				$result->{$k} = $doc->{video}->{$k};
				}
			}
		}

	$self->{_result} = $result;
	}

sub artist
	{
	my $self = shift;
	
	my @artists = ();
	foreach my $a (@{$self->{_result}->{mainArtists}})
		{
		push(@artists, $a->{artistName});
		}
	my @featured = ();
	foreach my $a (@{$self->{_result}->{featuredArtists}})
		{
		push(@featured, $a->{artistName});
		}

	my $artist = join(", ", @artists);
	if (@featured)
		{
		$artist .= " ft. " . join(", ", @featured);
		}

	return $artist;
	}

sub genre
	{
	my $self = shift;
	
	return join(", ", @{$self->{_result}->{genres}});
	}

sub max_resolution
	{
	my $self = shift;

	my ($base, $content) = $self->_max_resolution_content;
	if ($content->{src} =~ /_\d\d\d\d?x(\d\d\d\d?)_/)
		{
		return $1;
		}
	else
		{
		return 0;
		}
	}

sub _max_resolution_content
	{
	my $self = shift;

	my $max_resolution = 0;
	my $base = undef;
	my $content = {};
	foreach my $v (@{$self->{_result}->{videoVersions}})
		{
#		if ($v->{sourceType} == 2) # DOESNT INCLUDE HD STREAMS
#			{
#			my $data = XMLin($v->{data});
#			foreach my $r (values %{$data->{rendition}})
#				{
#				if ($r->{frameWidth} && $r->{frameWidth} >= $max_resolution)
#					{
#					$max_resolution = $r->{frameWidth};
#					$content = $r;
#					}
#				}
#			}
		if ($v->{sourceType} == 13)
			{
			my $xs = new XML::Simple(KeyAttr => [], ForceArray => ['meta']);

			my $data = $xs->XMLin($v->{data});
			if ($data->{rendition}->{name} eq "RTMPAkamai" || $data->{rendition}->{name} eq "RTMPLevel3")
				{
				my $txt = $self->_fetch_source($data->{rendition}->{url});
				my $xml = $xs->XMLin($txt);
				foreach my $v (@{$xml->{body}->{switch}->{video}})
					{
					if ($v->{src} =~ /_\d\d\d\d?x(\d\d\d\d?)_/ && $1 >= $max_resolution)
						{
						$max_resolution = $1;
						$base = $xml->{head}->{meta}->[0]->{base};
						$content = $v;
						}
					}
				}
			}
		}

	return ($base, $content);
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

sub _fetch_doc
	{
	my $self = shift;
	my ($u) = @_;

	my $ua = $self->{useragent};
	my $attempts = 0;
	while (1)
		{
		my $response = $ua->get($u);
		if ($response->is_success)
			{
			my $content = $response->decoded_content;

			if ($content)
				{
				if ($content =~ /our service is momentarily interrupted/) # not applied to VEVO yet
					{
					carp "api unavailable, sleeping for 10s\n";
					sleep(10);
					}
				else
					{
					my $jobj = JSON->new;
					$jobj->utf8(1);

					my $doc = $jobj->decode($content);

					&clean_doc($doc);

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

sub clean_doc
	{
	my ($r) = @_;
	
	if (ref($r) eq "HASH")
		{
		foreach my $k (keys %{$r})
			{
			$r->{$k} = &clean_doc($r->{$k});
			}
		}
	elsif (ref($r) eq "ARRAY")
		{
		foreach my $i (0..$#{$r})
			{
			$r->[$i] = &clean_doc($r->[$i]);
			}
		}
	elsif (ref($r) eq 'JSON::XS::Boolean')
		{
		$r = scalar($r) ? 1 : 0;
		}
	elsif (ref($r) eq "" && defined($r))
		{
		if ($r =~ m!^/Date\((\d+)\d\d\d\)/$!)
			{
			my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($1); # should be a US time rather than gmtime
			return sprintf("%04d-%02d-%02d %02d:%02d:%02d", 1900+$year, $mon+1, $mday, $hour, $min, $sec);
			}
		}

	return $r;
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

1; # End of WebService::Vevo
