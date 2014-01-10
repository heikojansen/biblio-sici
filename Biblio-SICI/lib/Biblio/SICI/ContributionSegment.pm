
package Biblio::SICI::ContributionSegment;

# ABSTRACT: The contribution segment of a SICI

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Biblio::SICI;
with 'Biblio::SICI::Role::ValidSegment', 'Biblio::SICI::Role::RecursiveLink';

use Biblio::SICI::Util ();

=pod

=encoding utf-8

=head1 SYNOPSIS

  my $sici = Biblio::SICI->new();

  $sici->contribution->location('6-21');

=head1 DESCRIPTION

I<Please note:> You are expected to not directly instantiate objects of this class!

The contribution segment of a SICI contains information about a contribution 
to an item, e.g. about an article published in a journal issue.
A SICI can be valid without containing data on a contribution so this segment may
be empty / unused.

For further information please have a look at the standard.

=head1 ATTRIBUTES

For each attribute, clearer ("clear_") and predicate ("has_") methods
are provided.

=over 4

=item C<location>

The location of the contribution within the item. A typical example
would be the range of pages an article was printed on.

=cut

has 'location' => ( is => 'rw', trigger => 1, predicate => 1, clearer => 1, );

sub _trigger_location {
	my ( $self, $newVal ) = @_;

	if ( $newVal !~ /\A${Biblio::SICI::Util::TITLE_CODE}+\Z/ ) {
		$self->log_problem_on( 'location' => ['contains invalid characters'] );
	}
	else {
		$self->clear_problem_on('location');
	}

	return;
}

=item C<titleCode>

A special code of no more than 6 characters, derived from the title 
of the contribution.
Rules for the construction of the code are provided in the standard.

=cut

has 'titleCode' => ( is => 'rw', trigger => 1, predicate => 1, clearer => 1, );

sub _trigger_titleCode {
	my ( $self, $newVal ) = @_;
	my @problems = ();

	if ( length $newVal > 6 ) {
		push @problems, 'contains more than 6 characters';
	}

	if ( $newVal !~ /\A${Biblio::SICI::Util::TITLE_CODE}+\Z/ ) {
		push @problems, 'contains invalid characters';
	}

	if (@problems) {
		$self->log_problem_on( titleCode => \@problems );
	}
	else {
		$self->clear_problem_on('titleCode');
	}

	return;
}

=item C<localNumber>

An opaque number that somehow describes the contribution
in the context of its item.

=back

=cut

has 'localNumber' => ( is => 'rw', trigger => 1, predicate => 1, clearer => 1, );

sub _trigger_localNumber {
	my ( $self, $newVal ) = @_;

	if ( $newVal !~ /\A${Biblio::SICI::Util::TITLE_CODE}+\Z/ ) {
		$self->log_problem_on( 'location' => ['contains invalid characters'] );
	}
	else {
		$self->clear_problem_on('location');
	}

	return;
}

=head1 METHODS

=over 4

=item STRING C<to_string>()

Returns a stringified representation of the data in the
contribution segment.

=cut

sub to_string {
	my $self = shift;
	my $str  = '';

	if ( $self->has_location() ) {
		$str .= $self->location();
	}

	if ( $self->has_titleCode() ) {
		$str .= ':' . $self->titleCode();
	}

	if ( $self->has_localNumber() ) {
		if ( $self->has_location() or $self->has_titleCode() ) {
			$str .= ':' . $self->localNumber();
		}
		else {
			$str .= '::' . $self->localNumber();
		}
	}

	return $str;
}

=item C<reset>()

Resets all attributes to their default values.

Resetting the contribution segment also resets the value of the
C<csi> attribute in the control segment!  

=cut

sub reset {
	my $self = shift;
	$self->clear_location();
	$self->clear_problem_on('location');
	$self->clear_titleCode();
	$self->clear_problem_on('titleCode');
	$self->clear_localNumber();
	$self->clear_problem_on('localNumber');

	$self->_sici()->control()->clear_csi();

	return;
}

=item BOOL C<is_valid>()

Checks if the data for the contribution segment conforms
to the standard.

=back

=head1 SEE ALSO

L<Biblio::SICI::Role::ValidSegment>

=cut

1;
