package WebService::Muzu::Image;

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

	#$hash->{soundoff} = "n";
	#$hash->{autostart} = "n";
	$self->{_query}->{videotype} = "hq";
	# width
	# height
	# includeAll

	$self->{url_base} = "http://www.muzu.tv/api/image";
	}

=head2 aname

Sets the artist name to be used in the search

=cut

sub get_results_by_video_id
	{
	my $self = shift;
	my $id = shift;

	my $doc = $self->fetch_doc({id => $id, _path => "video"});

	$self->{_result} = {};
	$self->load_node($doc->findnodes('/image'));

	return $self;
	}

sub get_results_by_channel_token
	{
	my $self = shift;
	my $id = shift;

	my $doc = $self->fetch_doc({id => $id, _path => "channel"});

	$self->{_result} = {};
	$self->load_node($doc->findnodes('/image'));

	return $self;
	}

sub image
	{
	return shift;
	}

sub load_node
	{
	my $self = shift;
	my $image = shift;

	foreach my $a ($image->attributes())
		{
		my $name = $a->localName;
		my $value = $a->getValue;
		$self->{_result}->{$name} = $value;
		}

	foreach my $node ($image->getChildrenByTagName('*'))
		{
		my $name = $node->localName;

		if ($name eq 'url')
			{
			my $value = $node->to_literal;
			if (defined $value)
				{
				$value =~ s/^\s+|\s+$//g;
				}
			$self->{_result}->{$name} = $value;
			}
		else
			{
			carp "unknown image childnode tag: $name";
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
