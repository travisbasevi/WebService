package WebService::BBCiPlayer;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use XML::Simple qw(:strict);
use URI::Escape;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::BBBiPlayer - Perl interface to the BBB iPlayer metadata

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $XS = new XML::Simple(KeyAttr => [], ForceArray => ['name-credit']);

=head1 SYNOPSIS

BBC has a non-documented API that is documented at http://beebhack.wikia.com/wiki/IPlayer_Metadata

    use WebService::BBCiPlayer;

    my $foo = WebService::BBCiPlayer->new();
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::BBCiPlayer> instance

=cut

#my $BIP = WebService::BBCiPlayer->new();
#$BIP->get_playlist('p0216k4g');
#use Data::Dumper; print Dumper($BIP->{_result});
#print $BIP->url;

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
	$self->{url_base} = "http://www.bbc.co.uk/iplayer/playlist";
	}

=head1 METHODS

=head2 get_video

=cut

sub get_playlist
	{
	my $self = shift;
	my $id = shift;

	my $doc = $self->_fetch_doc($id);
	$self->{_result} = $doc;

	return $self;
	}

sub _fetch_doc
	{
	my $self = shift;
	my ($id) = @_;

	my $u = $self->{url_base} . "/" . $id;

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
			croak "cannot get url $u: ", $response->status_line;
			}

		if (++$attempts >= 10)
			{
			croak "cannot get url $u after 10 attempts";
			}
		}
	}

sub id
	{
	my $self = shift;

	if (exists $self->{_result}->{item}->{group})
		{
		return $self->{_result}->{item}->{group};
		}
	else
		{
		carp "no name item->group found in $self";
		}
	}

sub duration
	{
	my $self = shift;

	if (exists $self->{_result}->{item}->{duration})
		{
		return $self->{_result}->{item}->{duration};
		}
	else
		{
		carp "no name item->duration found in $self";
		}
	}

sub updated_datetime
	{
	my $self = shift;

	if (exists $self->{_result}->{updated})
		{
		my ($date, $time) = $self->{_result}->{updated} =~ /^([\d\-]+)T([\d\:]+)/;
		return "$date $time";
		}
	else
		{
		carp "no name updated found in $self";
		}
	}

sub brand
	{
	my $self = shift;

	if (exists $self->{_result}->{item}->{masterbrand}->{content})
		{
		return $self->{_result}->{item}->{masterbrand}->{content};
		}
	else
		{
		carp "no name item->masterbrand->content found in $self";
		}
	}

sub url
	{
	my $self = shift;

	if (exists $self->{_result}->{link})
		{
		foreach my $h (@{$self->{_result}->{link}})
			{
			if ($h->{rel} eq "alternate")
				{
				return $h->{href};
				}
			}

		carp "no rel value 'alternate' in link found in $self";
		}
	else
		{
		carp "no name item->masterbrand->content found in $self";
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

Please report any bugs or feature requests to C<bug-webservice-bbciplayer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-BBCiPlayer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::BBCiPlayer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-BBCiPlayer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-BBCiPlayer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-BBCiPlayer>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-BBCiPlayer/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::BBCiPlayer
