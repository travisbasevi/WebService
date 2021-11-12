package WebService::Musicbrainz2;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use XML::Simple qw(:strict);
use URI::Escape;
use Time::HiRes qw(time sleep);

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::Musicbrainz2 - Perl interface to the musicbrainz.org API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $XS = new XML::Simple(KeyAttr => [], ForceArray => ['name-credit']);

our $LAST_QUERY_TIME;

=head1 SYNOPSIS

Musicbrainz has a developer's API documented at 
http://musicbrainz.org/doc/Development/XML_Web_Service/Version_2

This module makes life easier perl-wise, building in the fetching of the
XML and the processing of it

    use WebService::Musicbrainz2;

    my $foo = WebService::Musicbrainz2->new($entity, %config);
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::Musicbrainz2> instance

=cut

#my $MB = WebService::Musicbrainz2->new('artist');
#$MB->lookup('0b88686a-5ed4-4c66-960e-77e9b2981b8a', 'url-rels');
#use Data::Dumper; print Dumper($MB->{_result});
#print $MB->name, "\n";
#my $MB = WebService::Musicbrainz2->new('release');
#$MB->lookup('afc47229-be68-49be-9306-6563a2acbad8');
#use Data::Dumper; print Dumper($MB->{_result});
#print $MB->title, "\n";
#my $MB = WebService::Musicbrainz2->new('recording');
#$MB->lookup('67eb3567-c7f7-48ce-a179-ed98276578f5', 'artists', 'releases');
#use Data::Dumper; print Dumper($MB->{_result});
#print $MB->title, "\n";
#use Data::Dumper; print Dumper($MB->get_artist_credit);
#print $MB->get_release_list_year, "\n";

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
		$self->{useragent}->agent("WebService::Musicbrainz2/$VERSION (travis at verymetalnoise.com)");
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
	$self->{url_base} = "http://musicbrainz.org/ws/2/$entity";
	}

=head1 METHODS

=head2 lookup($mbid)
=head2 lookup($mbid, @inc)

=cut

sub lookup
	{
	my $self = shift;
	my $mbid = shift;
	my @inc = @_;

	$self->{entity} || croak "no entity set";

	my $url = $self->{url_base} . "/" . $mbid;
	if (@inc)
		{
		$url .= "?inc=" . join("+", @inc);
		}

	my $doc = $self->_fetch_doc($url);
	$self->{_result} = $doc->{$self->{entity}};

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
				if (eval { local $SIG{'__DIE__'}; $doc = $XS->XMLin($content) })
					{
					return $doc;
					}
				else
					{
					croak "ERROR! XML error: $@";
					}
				}
			else
				{
				croak "no content found for url: $u";
				}
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

sub name_exists
	{
	my $self = shift;
	my $name = shift;
	$name =~ s/_/-/g;

	return (exists $self->{_result} && exists $self->{_result}->{$name} ? 1 : 0);
	}

sub get_value
	{
	my $self = shift;
	my $name = shift;
	$name =~ s/_/-/g;

	if (exists $self->{_result} && exists $self->{_result}->{$name})
		{
		return $self->{_result}->{$name};
		}
	else
		{
		carp "no attribute '$name' found in $self";
		}
	}

sub AUTOLOAD
	{
	my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*:://;
	$name =~ s/_/-/g;

	return $self->get_value($name);
	}

sub get_artist_credit
	{
	my $self = shift;
	my $ac = $self->get_value('artist-credit');
	if ($ac && $ac->{'name-credit'})
		{
		my $r = {'name' => '', 'sort-name' => '', 'id' => '', 'ids' => []};
		foreach my $nc (@{$ac->{'name-credit'}})
			{
			$r->{name} .= $nc->{artist}->{name};
			$r->{'sort-name'} .= $nc->{artist}->{'sort-name'};
			if ($nc->{joinphrase})
				{
				$r->{name} .= $nc->{joinphrase};
				$r->{'sort-name'} .= $nc->{joinphrase};
				}
			push(@{$r->{ids}}, $nc->{artist}->{id});
			}
		$r->{id} = join("/", @{$r->{ids}});

		return $r;
		}
	}

sub get_release_list_year
	{
	my $self = shift;
	my $rl = $self->get_value('release-list');
	if ($rl && $rl->{'release'})
		{
		my $year;
		my @releases = ref($rl->{'release'}) eq "ARRAY" ? @{$rl->{'release'}} : ($rl->{'release'});
		foreach my $r (@releases)
			{
			if ($r->{date})
				{
				my ($y) = $r->{date} =~ /^(\d\d\d\d)/;
				if (!$year || $year > $y)
					{
					$year = $y;
					}
				}
			}
		return $year;
		}
	}

sub DESTROY # so AUTOLOAD doesn't serve it
	{
	}

=head1 AUTHOR

Travis Basevi, C<< <travis at verymetalnoise.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-vimeo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Musicbrainz2>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Musicbrainz2

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Musicbrainz2>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Musicbrainz2>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Musicbrainz2>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Musicbrainz2/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Musicbrainz2
