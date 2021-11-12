package WebService::Muzu::Base;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use XML::LibXML;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::Muzu::Base - core module for the Muzu webservice

=head1 SYNOPSIS

This module shouldn't be called directly, please see
L<../Muzu.pm> for full information

=head1 SUBROUTINES/METHODS

=head2 function1

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

	$self->{_query} = {};
	foreach my $k (keys %config)
		{
		if ($k eq 'useragent')
			{
			$self->{useragent} = $config{$k};
			}
		else
			{
			$self->{_query}->{$k} = $config{$k};
			}
		}

	$self->{useragent} ||= LWP::UserAgent->new; # to mock for testing
	$self->{_query}->{format} ||= "xml"; # rss is the other option
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

sub fetch_doc
	{
	my $self = shift;
	my $query_tmp = shift;
	
	my %query = %{$self->{_query}};
	if ($query_tmp)
		{
		@{\%query}{keys %{$query_tmp}} = values %{$query_tmp};
		#foreach my $k (keys %{$query_tmp})
		#	{
		#	$query{$k} = $query_tmp->{$k};
		#	}
		}

	my $u = $self->{url_base};
	my $qs = "";
	foreach my $k (sort keys %query)
		{
		if ($k eq "_path")
			{
			$u .= "/" . $query{$k};
			}
		elsif ($k !~ /^_/)
			{
			$qs .= $qs ? "&" : "";
			$qs .= _urlencode($k) . "=" . _urlencode($query{$k});
			}
		}
	if ($qs)
		{
		$u .= "?" . $qs;
		}
	$self->{_last_url} = $u;

	my $ua = $self->{useragent};
	my $response = $ua->get($u);
	if ($response->is_success)
		{
		my $content = $response->decoded_content;

#		if (!utf8::is_utf8($content)) # since Perl 5.8.1
#			{
#			$content = decode('iso-8859-1', $content);
#			}

		if ($content)
			{
			my $doc = XML::LibXML->load_xml(string => $content);
			if (my ($error) = $doc->findnodes('/error'))
				{
				croak "Muzu error ", $error->getAttribute('code'), ": ", $error->getAttribute('description');
				}
			else
				{
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
	}

sub _urlencode
	{
	my $toencode = shift;
	if (defined($toencode))
		{
		utf8::encode($toencode);
		$toencode =~ s/([^A-Za-z0-9\-_.~])/uc sprintf("%%%02X",ord($1))/eg;
		$toencode =~ s/\%20/\+/g;

		return $toencode;
		}
	else
		{
		return undef;
		}
	}

sub DESTROY
	{
	}

=head2 function2

=cut

sub function2 {
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

1; # End of WebService::Muzu
