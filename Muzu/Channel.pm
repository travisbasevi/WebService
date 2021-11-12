package WebService::Muzu::Channel;

use 5.006;
use strict;
use warnings;
use Carp;

use parent 'WebService::Muzu::Base';

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

	$self->{url_base} = "http://www.muzu.tv/api/channel/details";

	#$hash->{soundoff} = "n";
	#$hash->{autostart} = "n";
	$self->{_query}->{videotype} = "hq";
	# width
	# height
	# includeAll
	}

=head2 aname

Sets the artist name to be used in the search

=cut

sub get_results_by_vanityname
	{
	my $self = shift;
	my $vname = shift;

	my $doc = $self->fetch_doc({vname => $vname});

	$self->{_result} = {};
	$self->load_node($doc->findnodes('/channel'));

	return $self;
	}

sub get_results_by_token
	{
	my $self = shift;
	my $token = shift;

	my $doc = $self->fetch_doc({token => $token});

	$self->{_result} = {};
	$self->load_node($doc->findnodes('/channel'));

	return $self;
	}

sub channel
	{
	return shift;
	}

sub image
	{
	my $self = shift;
	return $self->{_result}->{image};
	}

sub thumbnails
	{
	my $self = shift;
	return @{$self->{_result}->{thumbnails}};
	}

sub videos
	{
	my $self = shift;
	return @{$self->{_result}->{videos}};
	}

sub load_node
	{
	my $self = shift;
	my $channel = shift;

	foreach my $a ($channel->attributes())
		{
		my $name = $a->localName;
		my $value = $a->getValue;
		$self->{_result}->{$name} = $value;
		}

	foreach my $node ($channel->getChildrenByTagName('*'))
		{
		my $name = $node->localName;

		if ($name eq 'name' || $name eq 'description' || $name eq 'tags' || $name eq 'url' || $name eq 'embed')
			{
			my $value = $node->to_literal;
			if (defined $value)
				{
				$value =~ s/^\s+|\s+$//g;
				}
			$self->{_result}->{$name} = $value;
			}
		elsif ($name eq 'vanity')
			{
			next; # ignore this, only comes from video.channel, and is duplicated data of the vanityname attribute
			}
		elsif ($name eq 'image')
			{
			my $i = WebService::Muzu::Image->new();
			$i->load_node($channel->findnodes('./image'));
			$self->{_result}->{image} = $i;
			}
		elsif ($name eq 'thumbnails')
			{
			$self->{_result}->{thumbnails} = [];
			foreach my $image ($channel->findnodes('./thumbnails/image'))
				{
				my $i = WebService::Muzu::Image->new();
				$i->load_node($image);
				push(@{$self->{_result}->{thumbnails}}, $i);
				}
			}
		elsif ($name eq 'videos')
			{
			$self->{_result}->{videos} = [];
			if ($channel->findnodes('./videos/playlist'))
				{
				foreach my $video ($channel->findnodes('./videos/playlist/video')) # ignoring playlist node (which has a playlist id) as it seems insignificant (can add methods for it later if it becomes meaningful)
					{
					my $v = WebService::Muzu::Video->new();
					$v->load_node($video);
					push(@{$self->{_result}->{videos}}, $v);
					}
				}
			elsif ($channel->findnodes('./videos/video'))
				{
				foreach my $video ($channel->findnodes('./videos/video')) # this logic is for when processing channel via Muzu::Artist
					{
					my $v = WebService::Muzu::Video->new();
					$v->load_node($video);
					push(@{$self->{_result}->{videos}}, $v);
					}
				}
			}
		else
			{
			carp "unknown channel childnode tag: $name";
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
