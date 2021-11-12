package WebService::Muzu;

use 5.006;
use strict;
use warnings;

use WebService::Muzu::Artist;
use WebService::Muzu::Channel;
use WebService::Muzu::Image;
use WebService::Muzu::Video;

use parent 'WebService::Muzu::Base';

=head1 NAME

WebService::Muzu - Perl interface to the www.muzu.tv API

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Muzu has a developer's API documented at http://www.muzu.tv/api/

This module makes life easier perl-wise, building in the fetching of the
XML and the processing of it

    use WebService::Muzu;

    my $foo = WebService::Muzu->new();
    ...

=head1 CONSTRUCTOR

=head2 new

Create a L<WebService::Muzu> instance

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

	$self->{url_base} = "http://www.muzu.tv/api";
	}

=head1 METHODS

=head2 get_results_by_browse

=cut

sub get_results_by_browse
	{
	my $self = shift;
	my $hr = shift || {};
	my %hash = %{$hr};
	$hash{_path} = "browse";
	my $doc = $self->fetch_doc(\%hash);

	$self->{_result} = {};
	$self->{_result}->{videos} = [];
	foreach my $video ($doc->findnodes('./videos/video'))
		{
		my $v = WebService::Muzu::Video->new();
		$v->load_node($video);
		push(@{$self->{_result}->{videos}}, $v);
		}

	return $self;
	}

=head2 get_results_by_search

=cut

sub get_results_by_search
	{
	my $self = shift;
	my $hr = shift || {};
	my %hash = %{$hr};
	$hash{_path} = "search";
	my $doc = $self->fetch_doc(\%hash);

	$self->{_result} = {};
	$self->{_result}->{videos} = [];
	foreach my $video ($doc->findnodes('./videos/video'))
		{
		my $v = WebService::Muzu::Video->new();
		$v->load_node($video);
		push(@{$self->{_result}->{videos}}, $v);
		}

	return $self;
	}

=head2 videos

=cut

sub videos
	{
	my $self = shift;
	return @{$self->{_result}->{videos}};
	}

=head1 AUTHOR

Travis Basevi, C<< <travis at verymetalnoise.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-muzu at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Muzu>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Muzu

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Muzu>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Muzu>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Muzu>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Muzu/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Travis Basevi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of WebService::Muzu
