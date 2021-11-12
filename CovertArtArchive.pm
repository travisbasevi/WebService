package WebService::CoverArtArchive;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON;
use URI::Escape;
use Time::HiRes qw(time sleep);

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::CoverArtArchive - Perl interface to the http://coverartarchive.org API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $JSON = JSON->new->utf8(1);

our $LAST_QUERY_TIME;

=head1 SYNOPSIS

Cover Art Archive has a developer's API documented at 
http://musicbrainz.org/doc/Cover_Art_Archive/API

This module makes life easier perl-wise, building in the fetching of the
JSON and the processing of it

    use WebService::CoverArtArchive;

    my $foo = WebService::CoverArtArchive->new($entity, %config);
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::CoverArtArchive> instance

=cut

#my $CAA = WebService::CoverArtArchive->new('release-group');
#$CAA->lookup('340fa5e1-e136-4281-bfb6-c8d8fdd5319e');
my $CAA = WebService::CoverArtArchive->new('release');
$CAA->lookup('44071ee8-d80e-4149-83d3-3f1d54189a1f');
use Data::Dumper; print Dumper($CAA);

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
	my $entity = shift;
	my %config = @_;

	$self->{_result} = {};

	foreach my $k (keys %config)
		{
		if ($k eq 'useragent')
			{
			$self->{useragent} = $config{$k};
			}
		}

	if (! $self->{useragent}) # to mock for testing
		{
		$self->{useragent} = LWP::UserAgent->new;
		$self->{useragent}->agent("WebService::CoverArtArchive/$VERSION (travis at verymetalnoise.com)");
		}

	if ($entity)
		{
		$self->set_entity($entity);
		}
	}

sub set_entity
	{
	my $self = shift;
	my $entity = shift;

	$self->{entity} = $entity;
	$self->{url_base} = "http://coverartarchive.org/$entity";
	}

=head1 METHODS

=head2 lookup($mbid)
=head2 lookup($mbid, @inc)

=cut

sub lookup
	{
	my $self = shift;
	my $mbid = shift;
	my $option = shift;

	$self->{entity} || croak "no entity set";

	my $url = $self->{url_base} . "/" . $mbid;
	if ($option)
		{
		$url .= "/" . $option;
		}

	$self->{_result} = $self->_fetch_doc($url)->{images};

	return $self;
	}

sub _fetch_doc
	{
	my $self = shift;
	my ($u) = @_;

	my $ua = $self->{useragent};
	my $attempts = 0;
	while (1)
		{
		my $t = time();
		if ($LAST_QUERY_TIME && $t - $LAST_QUERY_TIME < 1)
			{
			sleep(1 - $t + $LAST_QUERY_TIME);
			}

		my $response = $ua->get($u);
		$LAST_QUERY_TIME = time();

		if ($response->is_success)
			{
			my $content = $response->decoded_content;

#			if (!utf8::is_utf8($content)) # since Perl 5.8.1
#				{
#				$content = decode('iso-8859-1', $content);
#				}

			if ($content)
				{
				my $doc;
				if (eval { local $SIG{'__DIE__'}; $doc = $JSON->decode($content) })
					{
					return $doc;
					}
				else
					{
					croak "ERROR! JSON error: $@";
					}
				}
			else
				{
				croak "no content found for url: $u";
				}
			}
		elsif ($response->code == 307)
			{
			croak "redirected to binary image by url $u: ", $response->code, " ", $response->status_line;
			}
		elsif ($response->code == 400)
			{
			croak "{mbid} cannot be parsed as a valid UUID for url $u: ", $response->code, " ", $response->status_line;
			}
		elsif ($response->code == 404)
			{
			croak "either there is no such MBID, or the community have not chosen an image to represent the MBID for url $u: ", $response->code, " ", $response->status_line;
			}
		elsif ($response->code == 501)
			{
			croak "request method is not supported for url $u: ", $response->code, " ", $response->status_line;
			}
		elsif ($response->code == 503)
			{
			croak "user has exceeded their rate limit for url $u: ", $response->code, " ", $response->status_line;
			}
		else
			{
			croak "cannot get url $u: ", $response->code, " ", $response->status_line;
			}

		if (++$attempts >= 10)
			{
			croak "cannot get url $u after 10 attempts";
			}
		}
	}

sub get_image_refs
	{
	my $self = shift;

	my @result = ();
	foreach my $i (@{$self->{_result}})
		{
		push(@result, $i);
		}

	return @result;
	}

=head1 AUTHOR

Travis Basevi, C<< <travis at verymetalnoise.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-vimeo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-CoverArtArchive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::CoverArtArchive

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-CoverArtArchive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-CoverArtArchive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-CoverArtArchive>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-CoverArtArchive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::CoverArtArchive
