package Biblio::SICI::Role::RecursiveLink;

# ABSTRACT: Role to provide a "link" to the parent Biblio::SICI

use strict;
use warnings;

use Moo::Role;
use Sub::Quote;

=pod

=encoding utf-8

=head1 DESCRIPTION

A role that provides an attribute used to provide internal access 
to the parent C<Biblio::SICI> object from the three segment classes.

B<For internal use only!>

=head1 ATTRIBUTES

=over 4

=item _sici

Weak ref to the parent object.

=cut

has '_sici' => (
	is       => 'ro',
	required => 1,
	isa      => quote_sub(q{ my ($val) = @_; die unless ( $val->isa('Biblio::SICI') ) }),
	weak     => 1,
);

=back

=cut

1;
