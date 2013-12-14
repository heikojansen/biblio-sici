
package Biblio::SICI;

# ABSTRACT: Provides methods for assembling, parsing, manipulating and serialising SICIs

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Biblio::SICI::ItemSegment;
use Biblio::SICI::ContributionSegment;
use Biblio::SICI::ControlSegment;

use Biblio::SICI::Util qw( calculate_check_char );

=pod

=encoding utf-8

=head1 SYNOPSIS

  use Biblio::SICI;

  my $sici = Biblio::SICI->new()->parse($someSICI);

  # or

  my $sici2 = Biblio::SICI->new();

  $sici2->item->issn('0361-526X');

  # ... setting more data attributes ...
  
  if ( $sici2->is_valid ) {
      say $sici->to_string;
  }

=head1 DESCRIPTION

A "Serial Item and Contribution Identifier" (SICI) is a code (ANSI/NISO
standard Z39.56) used to uniquely identify specific volumes, articles 
or other identifiable parts of a periodical.

This module provides methods for assembling, parsing, manipulating and
serialising SICIs.

Both internal implementation and public API are currently considered BETA
and may change without warning in a future release. For more information 
on this have a look at the L<TODO section|/TODO> below.

=head1 CONFIGURATION

You may specify the following option when instantiating a SICI object
(i.e., when calling the "new()" constructor):

=over 4

=item C<mode>

Can be either C<strict> or C<lax>.

C<strict> mode means that any operation that gets called with an 
invalid (according to the standard) value for an attribute will
C<die()>.

C<lax> mode means that any value is accepted and that you can use
the C<is_valid()> and C<list_problems()> methods to analyze the 
object state.

=back

=head1 ATTRIBUTES

=over 4

=item C<item>

An instance of L<Biblio::SICI::ItemSegment>; this segment contains
information about the serial item itself.

=cut

has 'item' => (
	is   => 'ro',
	lazy => 1,
	isa => quote_sub(q{ die unless ( defined $_[0] and $_[0]->isa('Biblio::SICI::ItemSegment') ) }),
	builder =>
		quote_sub(q{ my ($self) = @_; return Biblio::SICI::ItemSegment->new( _sici => $self ); }),
	init_arg => undef,
);

=item C<contribution>

An instance of L<Biblio::SICI::ContributionSegment>; this segment
contains information about an individual contribution to the whole
item, e.g. an article in a journal issue.

=cut

has 'contribution' => (
	is   => 'ro',
	lazy => 1,
	isa  => quote_sub(
		q{ die unless ( defined $_[0] and $_[0]->isa('Biblio::SICI::ContributionSegment') ) }),
	builder => quote_sub(
		q{ my ($self) = @_; return Biblio::SICI::ContributionSegment->new( _sici => $self ); }),
	init_arg => undef,
);

=item C<control>

An instance of L<Biblio::SICI::ControlSegment>; this segment
contains some meta-information about the thing described by the
SICI and about the SICI itself.

=cut

has 'control' => (
	is   => 'ro',
	lazy => 1,
	isa  => quote_sub(
		q{ my ($val) = @_; die unless ( defined $val and $val->isa('Biblio::SICI::ControlSegment') ) }
	),
	builder => quote_sub(
		q{ my ($self) = @_; return Biblio::SICI::ControlSegment->new( _sici => $self ); }),
	init_arg => undef,
);

=item C<mode>

Describes wether the object enforces strict conformance to
the standard or not.
Can be set to either C<strict> or C<lax>.
This attribute is the only one that can be specified directly
in the call of the constructor.

Please keep in mind that changing the value does B<not> mean
that the attributes already present are re-checked!

=cut

has 'mode' => (
	is       => 'rw',
	isa      => quote_sub(q{ my ($val) = @_; die unless ( $val eq 'strict' or $val eq 'lax' ) }),
	required => 1,
	coerce   => sub {
		my ($val) = @_;
		$val = join( '', split( " ", lc($val) ) );
		return $val if ( $val eq 'strict' or $val eq 'lax' );
		return 'lax';
	},
	default => 'lax',
);

=item C<parsedString>

Returns the original string that was passed to the C<parse()> 
method or C<undef> if C<parse> was not called before.

=cut

has 'parsedString' => ( is => 'rwp', init_arg => undef, );

=back

=head1 METHODS

=over 4

=item C<parse>( STRING )

Tries to disassemble a string passed to it into the various
components of a SICI.

If I<strict> mode is enabled, it will C<die()> if no valid 
SICI can be derived from the string.

If I<lax> mode is enabled, it returns a list of two values 
indicating if the derived SICI is valid (first value) and 
if a round-trip using C<to_string()> would result in the 
exact same string (second value). 

=cut

sub parse {
	my ( $self, $string ) = @_;
	my $strictMode = $self->mode() eq 'strict' ? 1 : 0;

	unless ($string) {
		if ($strictMode) {
			die 'no string to parse';
		}
		else {
			return ( 0, undef );
		}
	}

	if ( $string =~ /;([0-9])-[0-9A-Z#]\Z/ ) {
		if ( "$1" ne "2" ) {
			if ($strictMode) {
				die 'unhandled SICI version';
			}
			else {
				return ( 0, undef );
			}
		}
	}

	my $mode = $self->mode();
	$self->_set_parsedString($string);

	my @chars = split( //, $string );
	my $issn = '';
	while ( exists( $chars[0] ) and $chars[0] =~ /[0-9X-]/ ) {
		$issn .= shift @chars;
	}
	$self->item()->issn($issn) if $issn;
	if ( exists( $chars[0] ) and $chars[0] eq '(' ) {
		shift @chars;
		my $chrono = '';
		while ( exists( $chars[0] ) and $chars[0] =~ /[0-9\/]/ ) {
			$chrono .= shift @chars;
		}
		$self->item()->chronology($chrono);
	}
	if ( exists( $chars[0] ) and $chars[0] eq ')' ) {
		shift @chars;
	}
	my $enum = '';
	while ( exists( $chars[0] ) and $chars[0] ne '<' ) {
		$enum .= shift @chars;
	}
	if ( $enum =~ /\A([A-Z0-9\/]+):([A-Z0-9\/]+)(?::([+*]))?\Z/ ) {
		$self->item()->volume($1);
		$self->item()->issue($2);
		$self->item()->supplOrIdx($3) if $3;
	}
	elsif ($enum) {
		$self->item()->enumeration($enum);
	}
	if ( exists( $chars[0] ) and $chars[0] eq '<' ) {
		shift @chars;
	}
	my $contrib = '';
	while ( exists( $chars[0] ) and $chars[0] ne '>' ) {
		$contrib .= shift @chars;
	}
	if ($contrib) {
		if ( $contrib =~ /\A::(.+)\Z/ ) {
			$self->contribution()->localNumber($1);
		}
		elsif ( $contrib =~ /\A:([^:]+)(?::(.+))?\Z/ ) {
			$self->contribution()->titleCode($1);
			$self->contribution()->localNumber($2) if $2;
		}
		elsif ( $contrib =~ /\A([^:]+):([^:]+)(?::(.+))?\Z/ ) {
			$self->contribution()->location($1);
			$self->contribution()->titleCode($2);
			$self->contribution()->localNumber($3) if $3;
		}
		else {
			$self->contribution()->location($contrib);
		}
	}
	if ( exists( $chars[0] ) and $chars[0] eq '>' ) {
		shift @chars;
	}
	if ( exists( $chars[0] ) ) {
		$self->control()->csi( shift @chars );
	}
	if ( exists( $chars[0] ) ) {
		shift @chars;    # should be "."
	}
	if ( exists( $chars[0] ) ) {
		$self->control()->dpi( shift @chars );
	}
	if ( exists( $chars[0] ) ) {
		shift @chars;    # should be "."
	}
	if ( exists( $chars[0] ) and exists( $chars[1] ) ) {
		$self->control()->mfi( join( '', splice( @chars, 0, 2 ) ) );
	}
	if ( exists( $chars[0] ) ) {
		shift @chars;    # should be ";"
	}
	if ( exists( $chars[0] ) ) {
		$self->control()->version( shift @chars );
	}

	my $isValid = $self->is_valid();
	if ( $strictMode && !$isValid ) {
		die 'parsing failed: invalid SICI';
	}

	my $roundTrip = ( $self->parsedString() eq $self->to_string() ? 1 : 0 );
	return ( $isValid, $roundTrip );
} ## end sub parse

=item C<to_string>

Serializes the object to a string using the separator characters
specified in the standard and returns it together with the check
character appended.

Does B<not> verify if the resulting SICI is valid!

=cut

sub to_string {
	my $self = shift;

	my $str = $self->_to_string();
	my $cs  = calculate_check_char($str);

	return $str . $cs;
}

sub _to_string {
	my $self = shift;

	my $item    = $self->item()->to_string();
	my $contrib = $self->contribution()->to_string();
	my $control = $self->control()->to_string();

	return sprintf( '%s<%s>%s-', $item, $contrib, $control );
}

=item STRING C<checkchar>()

Stringifies the object first, then calculates (and returns) 
the checksum character.
Does B<not> check, if the stringified SICI is valid!

=cut

sub checkchar {
	my $self = shift;

	my $siciAsString = $self->_to_string();

	return calculate_check_char($siciAsString);
}

=item C<reset>()

Resets all attributes to their default values.

Does not modify the C<mode> attribute.

=cut

sub reset {
	my $self = shift;
	$self->item()->reset();
	$self->contribution()->reset();
	$self->control()->reset();
	return;
}

=item BOOL C<is_valid>()

Determines if all of the attribute values stored in the object
are valid and returns either a I<true> or I<false> value.

B<TODO> check if any required information is missing!

=cut

sub is_valid {
	my $self = shift;

	my $itemIsValid    = $self->item()->is_valid();
	my $contribIsValid = $self->contribution()->is_valid();
	my $controlIsValid = $self->control()->is_valid();

	if ( $itemIsValid && $contribIsValid && $controlIsValid ) {
		return 1;
	}

	return 0;
}

=item HASHREF C<list_problems>()

Returns either a hash of hashes of arrays containing the 
problems that were found when setting the various attributes
of the SICI segments or C<undef> if there are no problems.

The first hash level is indexed by the three SICI segments:
I<item>, I<contribution>, and/or I<control>.

The level below is indexed by the attribute names (cf. the
docs of the segment modules).

For every attribute the third level contains an array reference
with descriptive messages.

  {
      'contribution' => {
          'titleCode' => [
              'contains more than 6 characters',
          ],
      },
  };

B<TODO> check for meta problems (e.g. missing attributes).

=cut

sub list_problems {
	my $self = shift;

	my $hasProblems = 0;
	my %problems    = ();
	if ( not $self->item()->is_valid() ) {
		$hasProblems++;
		$problems{'item'} = { $self->item()->list_problems() };
	}
	if ( not $self->contribution()->is_valid() ) {
		$hasProblems++;
		$problems{'contribution'} = { $self->contribution()->list_problems() };
	}
	if ( not $self->control()->is_valid() ) {
		$hasProblems++;
		$problems{'control'} = { $self->control()->list_problems() };
	}

	if ($hasProblems) {
		return %problems;
	}
	return;
}

1;

=back

=head1 TODO

The parsing of SICI strings sort-of works but I need to find
out more about how the code copes with real world SICIs (i.e. 
especially those that are slightly malformed or invalid).

It would probably make for a better programming style if I were
using real type specifications for the attributes. On the other
hand doing so would make the module employ overly strict checks
when dealing with imperfect SICIs. 
Since type checks in Moo (or Moose) know nothing about the object, 
the only other solution I can think of would be using objects of 
type C<Biblio::SICI> act as frontend for instances of either 
I<Biblio::SICI::Strict> or I<Biblio::SICI::Lax>.
This would require two separate sets of type definitions and make 
everything more complicated - and I am not sure if would provide 
us with a better way to handle and report formal problems.

That said, I´m also not particularly happy with how 
C<list_problems()> works right now and I´d be grateful for any
suggestions for improvements (or for positive feedback if it works
for you).

Also for now only problems with the available data are detected
while missing or inconsistend data is not checked for.

And of course we need a more comprehensive test suite.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Serial_Item_and_Contribution_Identifier>

=cut
