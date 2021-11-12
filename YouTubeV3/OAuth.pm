package WebService::YouTubeV3::OAuth;

use 5.006;
use strict;
use warnings;

use Carp;
use URI ();
use URI::QueryParam;

use parent 'WebService::YouTubeV3::Base';

our $ACCESS_TOKEN = {};

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

    my $yt = WebService::YouTubeV3::Videos->new();
    ...

=head1 SUBROUTINES/METHODS

=head2 new

=cut

sub new
	{
	my $class = shift;
	my %config = @_;

	my $self = {};
	bless($self, $class);

	$self->{_config} = \%config;

	$self->{_config}->{json} ||= JSON->new->utf8(1);

	if (!$self->{_config}->{useragent})
		{
		$self->{_config}->{useragent} = LWP::UserAgent->new;
		$self->{_config}->{useragent}->agent("$0/0.1 " . $self->{_config}->{useragent}->agent);
		}

	$self->{client_secrets_file} = $self->{_config}->{client_secrets_file} || 'google_client_secrets.json';
	$self->{access_token_file} = $self->{_config}->{access_token_file} || 'google_access_token.json';

	if (! $ACCESS_TOKEN->{$self->{access_token_file}})
		{
		my $at = $self->read_json($self->{access_token_file});
		if (!$at || !$at->{access_token})
			{
			$self->log("attempting remote oauth");
			$at = $self->remote_oauth;
			}
		$ACCESS_TOKEN->{$self->{access_token_file}} = $at;
		}
	$self->{access_token_hash} = $ACCESS_TOKEN->{$self->{access_token_file}};

	return $self;
	}

=head2 list

Returns a list of videos

$video = $yt->list($video_id);
$video = $yt->list($video_id, [$part1, $part2]);
$videos = $yt->list([$video1_id, $video2_id, ...]);

=cut

sub remote_oauth
	{
	my $self = shift;

	my $cs = $self->read_json($self->{client_secrets_file});

	my $req = HTTP::Request->new(POST => "https://accounts.google.com/o/oauth2/device/code");
	$req->header('Content-Type' => 'application/x-www-form-urlencoded');

	my $uri = URI->new("", "http");
	$uri->query_param('client_id', $cs->{installed}->{client_id});
	$uri->query_param('scope', 'https://www.googleapis.com/auth/youtube');
	$req->content($uri->query);

	my $r = $self->useragent->request($req);
	if ($r->is_success)
		{
		my $start_time = time();
		$self->log("*** GET SUCCESS");
		my $json = $self->json->decode($r->content);
		#print Dumper($json);
		$self->log("go to url: " . $json->{verification_url});
		$self->log("enter code: " . $json->{user_code});

		$req = HTTP::Request->new(POST => "https://accounts.google.com/o/oauth2/token");
		$req->header('Content-Type' => 'application/x-www-form-urlencoded');

		$uri = URI->new("", "http");
		$uri->query_param('client_id', $cs->{installed}->{client_id});
		$uri->query_param('client_secret', $cs->{installed}->{client_secret});
		$uri->query_param('code', $json->{device_code});
		$uri->query_param('grant_type', 'http://oauth.net/grant_type/device/1.0');
		$req->content($uri->query);

		#print $req->as_string; exit;

		while (time() - $start_time < $json->{expires_in})
			{
			my $r = $self->useragent->request($req);
			if ($r->is_success)
				{
				if ($r->content =~ /authorization_pending/)
					{
					sleep($json->{interval});
					}
				else
					{
					my $json = $self->json->decode($r->content);
					if ($json->{access_token})
						{
						$self->write_json($self->{access_token_file}, $json);
						return $json;
						}
					}
				}
			else
				{
				$self->log("*** GET FAILURE: " . $r->code . ": " . $r->message);
				print $r->content;
				exit;
				}
			}
		}
	else
		{
		$self->log("*** GET FAILURE: " . $r->code . ": " . $r->message);
		print $r->content;
		exit;
		}
	}

sub refresh_access_token
	{
	my $self = shift;

	my $at = $self->{access_token_hash};
	my $cs = $self->read_json($self->{client_secrets_file});

	my $req = HTTP::Request->new(POST => "https://www.googleapis.com/oauth2/v3/token");
	$req->header('Content-Type' => 'application/x-www-form-urlencoded');

	my $uri = URI->new("", "http");
	$uri->query_param('client_id', $cs->{installed}->{client_id});
	$uri->query_param('client_secret', $cs->{installed}->{client_secret});
	$uri->query_param('refresh_token', $at->{refresh_token});
	$uri->query_param('grant_type', 'refresh_token');
	$req->content($uri->query);

	#print $req->as_string; exit;
	#use Data::Dumper; print Dumper($self->{useragent});

	my $r = $self->useragent->request($req);
	if ($r->is_success)
		{
		my $json = $self->json->decode($r->content);
		if ($json->{access_token})
			{
			# need to merge json into access_token as it doesn't include refresh_token
			foreach my $k (keys %{$json})
				{
				$at->{$k} = $json->{$k};
				}
			$self->write_json($self->{access_token_file}, $at);

			# following shouldn't be necessary as they're the same hashref but included anyway
			$ACCESS_TOKEN->{$self->{access_token_file}} = $at;
			$self->{access_token_hash} = $at;
			}
		}
	else
		{
		$self->log("*** GET FAILURE: " . $r->code . ": " . $r->message);
		print $r->content;
		exit;
		}
	}

=head1 AUTHOR

Travis Basevi, C<< <travisb at cpan.org> >>

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
