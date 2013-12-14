
use strict;
use warnings;

use Test::More;

use Biblio::SICI;

my $sici1 = Biblio::SICI->new();

isa_ok( $sici1, 'Biblio::SICI', 'object instantiated' );

foreach (
	[ '0066-4200(1990)25<>1.0.TX;2-S',                1, 1 ],
	[ '0095-4403(199502/03)21:3<>1.0.TX;2-Z',         1, 1 ],
	[ '1234-5679(1996)<::INS-023456>3.0.CO;2-#',      1, 1 ],
	[ '0361-526X(2011)17:3/4<60-61:AAAAAA>2.0.ZU;2-', 1, 0 ],
	[ '0361-5265(2011)17:3/4<60-61:AAAAAA>2.0.ZU;2-', 0, 0 ],
	)
{
	my ( $valid, $roundTrip ) = $sici1->parse( $_->[0] );
	is( $valid, $_->[1],
		      'parser says, sici is '
			. ( $valid ? 'valid' : 'invalid' )
			. ', but in fact it is '
			. ( $_->[1] ? 'valid' : 'invalid' ) );
	is( $roundTrip, $_->[2],
		      'parser says, string '
			. ( $roundTrip ? 'is' : 'is not' )
			. ' roundtrip safe, but in fact it '
			. ( $_->[2] ? 'is' : 'is not' ) );
	$sici1->reset;
}

done_testing();
