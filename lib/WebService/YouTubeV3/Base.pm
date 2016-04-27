package WebService::YouTubeV3::Base;

use 5.006;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON;

use utf8;
use Encode;

our $AUTOLOAD;

=head1 NAME

WebService::YouTubeV3::Base - core module for the YouTubeV3 webservice

=head1 SYNOPSIS

This module shouldn't be called directly, please see
L<../YouTubeV3.pm> for full information

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

	$self->{_config} = \%config;
	$self->{_get} = {};
	$self->{_set} = {};

	$self->{_config}->{json} ||= JSON->new->utf8(1);

	if (!$self->{_config}->{useragent})
		{
		$self->{_config}->{useragent} = LWP::UserAgent->new;
		$self->{_config}->{useragent}->agent("$0/0.1 " . $self->{_config}->{useragent}->agent);
		$self->{_config}->{useragent}->timeout(30);
		}

	$self->{_config}->{oauth} ||= WebService::YouTubeV3::OAuth->new(%{$self->{_config}});
	}

sub json
	{
	my $self = shift;
	return $self->{_config}->{json};
	}

sub useragent
	{
	my $self = shift;
	return $self->{_config}->{useragent};
	}

sub oauth
	{
	my $self = shift;
	return $self->{_config}->{oauth};
	}

sub next_page
	{
	my $self = shift;
	return $self->{next_page} || undef;
	}

sub prev_page
	{
	my $self = shift;
	return $self->{prev_page} || undef;
	}

sub fetch
	{
	my $self = shift;
	my ($id, $part) = @_;

	my @list = $self->list($part, {'id' => $id}, undef, 1);
	if (@list)
		{
		$self->{_get} = $list[0]->{_get};
		return 1;
		}
	else
		{
		$self->{_get} = undef;
		return 0;
		}
	}

sub list
	{
	my $self = shift;
	my ($part, $filter, $opt, $limit) = @_;

	$part ||= $self->{get_default};
	$filter ||= {};
	$opt ||= {};
	$limit = defined($limit) ? $limit : 50;

	$opt->{maxResults} ||= 50;
	if ($limit && $opt->{maxResults} > $limit)
		{
		$opt->{maxResults} = $limit;
		}

	my $uri = URI->new($self->{url_base});
	$uri->query_param('part', ref($part) eq "ARRAY" ? join(',', @{$part}) : $part);
	my ($fk) = sort keys %{$filter};
	if ($fk)
		{
		$uri->query_param($fk, ref($filter->{$fk}) eq "ARRAY" ? join(',', @{$filter->{$fk}}) : $filter->{$fk});
		}
	foreach my $ok (sort keys %{$opt})
		{
		$uri->query_param($ok, $opt->{$ok});
		}

	my @get = ();
	$self->{_get} = {};
	while ($uri)
		{
		my $json = $self->fetch_doc($uri, 'GET');
		$self->{next_page} = $json->{nextPageToken};
		$self->{prev_page} = $json->{prevPageToken};
		$self->{total_results} = $json->{pageInfo}->{totalResults};

		foreach my $item (@{$json->{items}})
			{
			my $r = $self->clone;
			$r->{_get} = $item;
			push(@get, $r);
			if ($limit && @get >= $limit)
				{
				last;
				}
			}

		if ($json->{nextPageToken} && (!$limit || @get < $limit))
			{
			$uri->query_param('pageToken', $json->{nextPageToken});
			}
		else
			{
			undef $uri;
			}
		}

	return @get;
	}

sub insert
	{
	my $self = shift;
	my ($part, $opt) = @_;

	$part ||= $self->{set_default};
	$opt ||= {};

	my $uri = URI->new($self->{url_base});
	$uri->query_param('part', ref($part) eq "ARRAY" ? join(',', @{$part}) : $part);
	foreach my $ok (sort keys %{$opt})
		{
		$uri->query_param($ok, $opt->{$ok});
		}

	my $json = $self->fetch_doc($uri, 'POST', $self->{_set});
	if ($json)
		{
		$self->{_set} = {};
		$self->{_get} = $json;
		return 1;
		}
	else
		{
		$self->{_get} = undef;
		return 0;
		}
	}

sub update
	{
	my $self = shift;
	my ($part, $opt) = @_;

	$part ||= $self->{set_default};
	$opt ||= {};

	my $uri = URI->new($self->{url_base});
	$uri->query_param('part', ref($part) eq "ARRAY" ? join(',', @{$part}) : $part);
	foreach my $ok (sort keys %{$opt})
		{
		$uri->query_param($ok, $opt->{$ok});
		}

	my $json = $self->fetch_doc($uri, 'PUT', $self->{_set});
	if ($json)
		{
		$self->{_set} = {};
		$self->{_get} = $json;
		return 1;
		}
	else
		{
		$self->{_get} = undef;
		return 0;
		}
	}

sub delete
	{
	my $self = shift;
	my ($opt) = @_;

	$opt ||= {};

	my $uri = URI->new($self->{url_base});
	$uri->query_param('id', $self->id);
	foreach my $ok (sort keys %{$opt})
		{
		$uri->query_param($ok, $opt->{$ok});
		}

	return $self->make_request($uri, 'DELETE');
	}

sub make_resource_id
	{
	my $self = shift;

	my $hash = {};
	$hash->{kind} = $self->{kind};
	my ($id) = $self->{kind} =~ /.+#(.+)/;
	$id .= "Id";
	$hash->{$id} = $self->id;

	return $hash;
	}

sub get_all
	{
	my $self = shift;

	my $get = {};
	_sub_get_all($get, "", $self->{_get});

	return $get;
	}

sub _sub_get_all
	{
	my ($get, $prefix, $hash) = @_;

	foreach my $k (sort keys %{$hash})
		{
		my $p = $prefix . ($prefix ? "_" : "") . $k;
		if (ref($hash->{$k}) eq 'HASH')
			{
			_sub_get_all($get, $p, $hash->{$k});
			}
		else
			{
			$get->{$p} = $hash->{$k};
			}
		}
	}

sub check_value
	{
	my $self = shift;
	my $name = shift;

	my $ok = 1;
	my $h = $self->{_get};
	foreach my $w (split(/_/, $name))
		{
		if (ref($h) eq 'HASH' && exists $h->{$w})
			{
			$h = $h->{$w};
			}
		else
			{
			$ok = 0;
			last;
			}
		}

	return $ok;
	}

sub get_value
	{
	my $self = shift;
	my $name = shift;

	my $ok = 1;
	my $h = $self->{_get};
	foreach my $w (split(/_/, $name))
		{
		if (ref($h) eq 'HASH' && exists $h->{$w})
			{
			$h = $h->{$w};
			}
		else
			{
			$ok = 0;
			last;
			}
		}
	if ($ok)
		{
		return $h;
		}
	else
		{
		carp "no attribute '$name' found in $self";
		}
	}

sub set_value
	{
	my $self = shift;
	my ($name, $val) = @_;

	my $ok = 1;
	my $h = $self->{_set};
	my @words = split(/_/, $name);
	my $count = 0;
	foreach my $w (@words)
		{
		$count++;
		if (ref($h) eq 'HASH')
			{
			if ($count == @words)
				{
				$h->{$w} = $val;
				}
			elsif (!exists $h->{$w})
				{
				$h->{$w} = {};
				}
			$h = $h->{$w};
			}
		else
			{
			$ok = 0;
			last;
			}
		}

	if ($ok)
		{
		return $self;
		}
	else
		{
		carp "clash in object structure for '$name' in $self";
		}
	}

sub AUTOLOAD
	{
	my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*:://;

	if (@_)
		{
		return $self->set_value($name, @_);
		}
	else
		{
		return $self->get_value($name);
		}
	}

sub fetch_doc
	{
	my $self = shift;
	my ($uri, $method, $body) = @_;

	foreach my $try (1..5)
		{
		my $req = HTTP::Request->new($method => $uri->as_string);
		$req->header('Authorization' => $self->oauth->{access_token_hash}->{token_type} . ' ' . $self->oauth->{access_token_hash}->{access_token});
		if ($body)
			{
			$req->header('Content-Type' => 'application/json');
			my $json = $self->json->encode($body);
			$req->content(Encode::encode_utf8($json));
			}
		$self->{_last_url} = $uri->as_string;
		$self->{_last_etag} = undef;
		$self->log($method . " " . $uri->as_string);
		#print $req->dump;

		my $r = $self->useragent->request($req);
		if ($r->is_success)
			{
			#print $r->content;
			my $ref;
			if (eval { $ref = $self->json->decode($r->content) })
				{
				$self->{_last_etag} = $ref->{etag};
				return $ref;
				}
			elsif ($try < 5)
				{
				carp "JSON DECODE FAILURE (try $try/5): " . join("; ", $@);
				sleep 10;
				}
			else
				{
				croak "JSON DECODE FAILURE (exit): " . join("; ", $@);
				}
			}
		elsif ($try == 1 && $r->code == 401 && $self->oauth->{access_token_hash}->{refresh_token})
			{
			$self->log("attempting token refresh");
			$self->oauth->refresh_access_token;
			}
		else
			{
			my $reason = "";
			if ($r->content)
				{
				my $ref;
				if (eval { $ref = $self->json->decode($r->content) })
					{
					foreach my $e (@{$ref->{error}->{errors}})
						{
						$reason .= $reason ? ", " : "";
						$reason .= $e->{domain} . ": " . $e->{reason};
						}
					}
				else
					{
					$reason = $r->content;
					}
				}

			if ($try < 5)
				{
				carp "$method FAILURE (try $try/5): error " . $r->code . " (" . $r->message . ") " . $reason;
				sleep 10;
				}
			elsif ($r->code == 403)
				{
				carp "$method FAILURE (ignore): error " . $r->code . " (" . $r->message . ") " . $reason;
				}
			else
				{
				croak "$method FAILURE (exit): error " . $r->code . " (" . $r->message . ") " . $reason;
				}
			}
		}
	}

sub make_request
	{
	my $self = shift;
	my ($uri, $method, $body) = @_;

	foreach my $try ('access', 'refresh')
		{
		my $req = HTTP::Request->new($method => $uri->as_string);
		$req->header('Authorization' => $self->oauth->{access_token_hash}->{token_type} . ' ' . $self->oauth->{access_token_hash}->{access_token});
		if ($body)
			{
			$req->header('Content-Type' => 'application/json');
			my $json = $self->json->encode($body);
			$req->content(Encode::encode_utf8($json));
			}
		$self->{_last_url} = $uri->as_string;
		$self->{_last_etag} = undef;
		$self->log($method . " " . $uri->as_string);
		#print $req->dump;

		my $r = $self->useragent->request($req);
		if ($r->code == 204)
			{
			$self->{_last_etag} = 0;
			return 1;
			}
		elsif ($r->code == 401 && $try eq 'access' && $self->oauth->{access_token_hash}->{refresh_token})
			{
			$self->log("attempting token refresh");
			$self->oauth->refresh_access_token;
			}
		else
			{
			croak "$method FAILURE: error" . $r->code . ": " . $r->message;
			}
		}
	}

sub spawn
	{
	my $self = shift;
	my $name = shift;

	my $class = ref($self);
	$class =~ s/(.+::).+/$1$name/;

	return $class->new(%{$self->{_config}});
	}

sub clone
	{
	my $old = shift;

	my $class = ref($old);
	my $new = $class->new(%{$old->{_config}});

	foreach my $k (keys %{$old->{_get}})
		{
		$new->{_get}->{$k} = _clone_ref($old->{_get}->{$k});
		}

	return $new;
	}

sub _clone_ref
	{
	my $r = shift;

	if (ref($r) eq "ARRAY")
		{
		[map _clone_ref($_), @{$r}];
		}
	elsif (ref($r) eq "HASH")
		{
		+{map { $_ => _clone_ref($r->{$_}) } keys %{$r} };
		}
	else
		{
		$r;
		}
	}

sub read_json
	{
	my $self = shift;
	my $file = shift;

	local $/;
	if (open(my $fh, '<', $file))
		{
		my $json_text = <$fh>;
		close($fh);
		if ($json_text)
			{
			return $self->json->decode($json_text);
			}
		else
			{
			return undef;
			}
		}
	else
		{
		return undef;
		}
	}

sub write_json
	{
	my $self = shift;
	my ($file, $json) = @_;

	open(my $fh, '>', $file) || croak "cannot write open file $file: $!";
	print $fh $self->json->encode($json);
	close($fh);
	}

sub log
	{
	my $self = shift;
	my $str = shift;
	$str ||= "";
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time);
	print sprintf("[%04d-%02d-%02d %02d:%02d:%02d] %s\n", 1900+$year, $mon+1, $mday, $hour, $min, $sec, $str);
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

1; # End of WebService::YouTubeV3
