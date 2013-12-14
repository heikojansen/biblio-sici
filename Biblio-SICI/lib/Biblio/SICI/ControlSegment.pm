
package Biblio::SICI::ControlSegment;

# ABSTRACT: The control segment of a SICI

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Biblio::SICI;
with 'Biblio::SICI::Role::ValidSegment', 'Biblio::SICI::Role::RecursiveLink';

=pod

=encoding utf-8

=head1 SYNOPSIS

  my $sici = Biblio::SICI->new();

  $sici->control->csi(2);

=head1 DESCRIPTION

I<Please note:> You are expected to not directly instantiate objects of this class!

The control segment of a SICI describes various aspects of the I<thing> referenced
by the SICI using pre-defined codes.
The segment also contains some meta-information about the SICI itself. 

=head1 ATTRIBUTES

For each attribute, clearer ("clear_") and predicate ("has_") methods
are provided.

=over 4

=item C<csi>

The I<Code Structure Identifier> tells something about which parts of the
SICI carry values.
It can take one of three values:

  B<1> => SICI for Serial Item
  B<2> => SICI for Serial Contribution
  B<3> => SICI for Serial Contribution "with obscure numbering"

Unless a value is explicitly set the object tries to automatically derive the
correct value from analysing the contribution segment.
If no data is present in the contribution segment the final default is B<1>.

=cut

has 'csi' => ( is => 'rw', trigger => 1, lazy => 1, predicate => 1, clearer => 1, builder => 1, );

sub _build_csi {
	my $self = shift;

	if ( $self->_sici()->contribution()->has_localNumber() ) {
		return 3;
	}

	if (   $self->_sici()->contribution()->has_location()
		or $self->_sici()->contribution()->has_titleCode() )
	{
		return 2;
	}

	return 1;
}

sub _trigger_csi {
	my ( $self, $newVal ) = @_;

	if ( not( $newVal == 1 or $newVal == 2 or $newVal == 3 ) ) {
		$self->log_problem_on( 'csi' => ['value not in allowed range (1|2|3)'] );
	}
	else {
		$self->clear_problem_on('csi');
	}

	return;
}

=item C<dpi>

The I<Derivative Part Identifier> tells us, what kind of I<thing> is described
by the SICI. It can take one of four different values:

  B<0> => SICI describes Serial Item or Contribution itself
  B<1> => SICI describes ToC of Serial Item or Contribution
  B<2> => SICI describes Index of Serial Item or Contribution
  B<3> => SICI describes Abstract of Serial Item or Contribution

The default value is B<0>.

=cut

has 'dpi' => (
	is        => 'rw', lazy => 1,
	trigger   => 1,
	default   => quote_sub(q{ return 0 }),
	predicate => 1,
	clearer   => 1,
);

sub _trigger_dpi {
	my ( $self, $newVal ) = @_;

	if ( not( $newVal == 0 or $newVal == 1 or $newVal == 2 or $newVal == 3 ) ) {
		$self->log_problem_on( 'dpi' => ['value not in allowed range (0|1|2|3)'] );
	}
	else {
		$self->clear_problem_on('dpi');
	}

	return;
}

=item C<mfi>

The I<Medium / Format Identifier> can take one of these codes:

  B<CD> => Computer-readable optical media (CD-ROM)
  B<CF> => Computer-readable magnetic disk media
  B<CO> => Online (remote)
  B<CT> => Computer-readable magnetic tape media
  B<HD> => Microfilm
  B<HE> => Microfiche
  B<SC> => Sound recording
  B<TB> => Braille
  B<TH> => Printed text, hardbound
  B<TL> => Printed text, looseleaf
  B<TS> => Printed text, softcover
  B<TX> => Printed text
  B<VX> => Video recording
  B<ZN> => Multiple physical forms
  B<ZU> => Physical form unknown
  B<ZZ> => Other physical form 

The default value is B<ZU>.

=cut

has 'mfi' =>
	( is => 'rw', lazy => 1, trigger => 1, default => 'ZU', predicate => 1, clearer => 1, );

sub _trigger_mfi {
	my ( $self, $newVal ) = @_;

	if ( $newVal !~ /\A(?:C[DFOT]|H[DE]|SC|T[BHLSX]|VX|Z[NUZ])\Z/ ) {
		$self->log_problem_on( 'mfi' => ['unknown identifier'] );
	}
	else {
		$self->clear_problem_on('mfi');
	}

	return;
}

=item C<version>

The number of the standards version to which the SICI should adhere.
The default is B<2> (which means Z39.56-1996), since that is also 
the only currently supported version.

=cut

has 'version' => (
	is        => 'rw', lazy => 1,
	trigger   => 1,
	default   => quote_sub(q{ return 2 }),
	predicate => 1,
	clearer   => 1,
);

sub _trigger_version {
	my ( $self, $newVal ) = @_;

	if ( $newVal != 2 ) {
		$self->log_problem( 'version' => ['unsupported version number (i.e. not "2")'] );
	}
	else {
		$self->clear_problem_on('version');
	}

	return;
}

=back

=head1 METHODS

=over 4

=item STRING C<to_string>()

Returns a stringified representation of the data in the
control segment.

Please note that the check digit is I<not> considered to be a
part of the control segment (but the "-" preceding it in the SICI
string is).

=cut

sub to_string {
	my $self = shift;

	# Every attribute in this class has a default value
	return sprintf( '%d.%d.%s;%d', $self->csi(), $self->dpi(), $self->mfi(), $self->version() );
}

=item C<reset>()

Resets all attributes to their default values.

=cut

sub reset {
	my $self = shift;
	$self->clear_csi();
	$self->clear_problem_on('csi');
	$self->clear_dpi();
	$self->clear_problem_on('dpi');
	$self->clear_mfi();
	$self->clear_problem_on('mfi');
	$self->clear_version();
	$self->clear_problem_on('version');
	return;
}

=item BOOL C<is_valid>()

Checks if the data for the control segment conforms
to the standard.

=back

=head1 SEE ALSO

L<Biblio::SICI::Role::ValidSegment>

=cut

1;
