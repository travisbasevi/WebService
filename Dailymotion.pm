package WebService::Dailymotion;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON;
use URI::Escape;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::Dailymotion - Perl interface to the www.dailymotion.com API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our %FORMAT_PRIORITY = qw(
ld	240
sd	384
hq	480
hd720	720
hd1080	1080
);

=head1 SYNOPSIS

Dailymotion has a developer's API documented at http://www.dailymotion.com/developer

This module makes life easier perl-wise, building in the fetching of the
JSON and the processing of it

    use WebService::Dailymotion;

    my $foo = WebService::Dailymotion->new();
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::Dailymotion> instance

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
	$self->{url_base} = "https://api.dailymotion.com";
	}

=head1 METHODS

=head2 get_video

=cut

sub get_video
	{
	my $self = shift;
	my $id = shift;

	my $doc = $self->_fetch_doc('video', $id, [qw(available_formats created_time description duration id owner tags taken_time title url)]);
	foreach my $k (keys %{$doc})
		{
		if ($k eq 'tags')
			{
			$doc->{$k} = join(', ', @{$doc->{$k}});
			}
		elsif ($k eq 'owner')
			{
			my $user_doc = $self->_fetch_doc('user', $doc->{$k}, [qw(username)]);
			if ($user_doc->{username})
				{
				$doc->{username} = $user_doc->{username};
				}
			}
		elsif ($k eq 'available_formats')
			{
			$doc->{max_resolution} = undef;
			$doc->{best_format} = undef;
			foreach my $f (@{$doc->{$k}})
				{
				if (!$doc->{max_resolution} || $FORMAT_PRIORITY{$f} > $doc->{max_resolution})
					{
					$doc->{max_resolution} = $FORMAT_PRIORITY{$f};
					$doc->{best_format} = $f;
					}
				}
			}
		}

	$self->{_result} = $doc;

	return $self;
	}

sub download
	{
	my $self = shift;
	my %dl_hash = @_;

	if ($self->{_result}->{url})
		{
		my $ua = LWP::UserAgent->new(max_redirect => 0);
		$ua->timeout(600); # 10 minute timeout
		$ua->default_header('User-Agent' => 'Mozilla/5.0 (Windows NT 6.1; WOW64; rv:16.0) Gecko/20100101 Firefox/16.0');
		if ($dl_hash{proxy})
			{
			$ua->proxy('http', $dl_hash{proxy});
			}

		my $url1 = $self->{_result}->{url};
		my $r1 = $ua->get($url1);
		if ($r1->is_success)
			{
			my $c1 = $r1->decoded_content;

			if ($c1 =~ /var\s+flashvars\s*=\s*(\{.+\});/)
				{
				my $jo = JSON->new->utf8(1);
				my $json1 = $jo->decode($1);
				my $json2 = $jo->decode(uri_unescape($json1->{sequence}));

				#use Data::Dumper;
				#print Dumper($json2);
				#exit;

				my $url2;
				my $format = $self->{_result}->{best_format} . 'URL';
				foreach my $sl (@{$json2->{sequence}->[0]->{layerList}->[0]->{sequenceList}})
					{
					if ($sl->{name} eq 'main')
						{
						foreach my $ll (@{$sl->{layerList}})
							{
							if ($ll->{name} eq 'video')
								{
								$url2 = $ll->{param}->{$format};
								}
							}
						}
					}

				if ($url2)
					{
					my $r2 = $ua->get($url2);
					if ($r2->code == 302)
						{
						my $url3 = $r2->header('location');

						my ($ext) = $url3 =~ /\.(\w+)\?/;
						my $filename = $self->{_result}->{id} . "." . $ext;

						my $r3 = $ua->get($url3, ':content_file' => $filename);
						if ($r3->is_success)
							{
							#my $size_header = $r3->header("Content-Length");
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
							croak "error downloading $url3: ", $r3->status_line;
							}
						}
					else
						{
						croak "302 expected for url $url2: ", $r2->status_line;
						}
					}
				else
					{
					croak "cannot find $format in flashvars in url: ", $url1;
					}
				}
			else
				{
				croak "cannot find flashvars in url: ", $url1;
				}
			}
		else
			{
			croak "error downloading $url1: ", $r1->status_line;
			}
		}
	else
		{
		croak "no video url found to parse for download (have you loaded a video into the object?)";
		}
	}

sub _fetch_doc
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
