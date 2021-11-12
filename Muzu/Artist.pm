package WebService::Muzu::Artist;

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

	$self->{url_base} = "http://www.muzu.tv/api/artist/details";
	}

=head2 aname

Sets the artist name to be used in the search

=cut

sub get_results_by_name
	{
	my $self = shift;
	my $aname = shift;

	my $doc = $self->fetch_doc({aname => $aname});

	$self->{_result} = {};
	$self->{_result}->{channel} = [];
	foreach my $channel ($doc->findnodes('/artist/channel'))
		{
		my $c = WebService::Muzu::Channel->new();
		$c->load_node($channel);
		push(@{$self->{_result}->{channel}}, $c);
		}

	return $self;
	}

sub channels
	{
	my $self = shift;
	return @{$self->{_result}->{channel}};
	}

sub videos
	{
	my $self = shift;
	my @videos = ();
	foreach my $channel (@{$self->{_result}->{channel}})
		{
		my @v = $channel->videos;
		push(@videos, @v);
		}
	return @videos;
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
