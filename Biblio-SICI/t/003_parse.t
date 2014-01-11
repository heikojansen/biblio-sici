
use strict;
use warnings;

use Test::More;
use Data::Dumper;

use Biblio::SICI;

my $sici = Biblio::SICI->new();

isa_ok( $sici, 'Biblio::SICI', 'object instantiated' );

foreach (
	' 1234-5679(1996)<::INS-023456>3.0.CO;2-#',
	'0015-6914(19960101)157:1<>1.0.TX;2-V ',
	' 0015-6914 ( 19960101 ) 157:1 < 62:KTSW > 2.0.TX ; 2-F ',
	'1064-3923(199505)6:5<>1.0.TX;2-U',
	'1064-3923(199505)6:5<26:MTW>2.0.TX;2-2',
	'0277-786X()364<123:COIPDA>2.0.TX;2-S',
	'0018-9219(1985)73*<>1.0.TX;2-6',
	'0066-4200(1990)25<>1.0.TX;2-S',
	'0066-4200(1990)25<263:IATIR>2.0.TX;2-A',
	'0095-4403(199312/199401)20:2<>1.0.TX;2-U',
	'0363-0277(19950315)120:5<>1.0.TX;2-V',
	'0363-0277(19950315)120:5<32:IAA>2.0.TX;2-0',
	'0002-8231(199602)47:2<173:POPR:CCC-020173-04>3.0.TX;2-E',
	'0002-8231(199412)45:10<>1.0.TX;2-P',
	'0002-8231(199412)45:10<>1.1.TX;2-M',
	'0002-8231(199412)45:10<>1.2.TX;2-J',
	'0002-8231(199412)45:10<737:TIODIM>2.3.TX;2-M',
	'0147-2593(199606)20:1<>1.0.TX;2-5',
	'0160-6506(194507)176:1<>1.0.HD;2-F',
	'0737-8831(1992)10:4<7:OAFFPC>2.0.TX;2-K',
	'0278-7687(1996)12<>1.0.CO;2-J',
	'0163-5808(199206)21:2<>1.0.TX;2-Z',
	'1055-2685(19950418)21:8<>1.0.TX;2-P',
	'1071-5800(199621)4<>1.0.CO;2-T',
	'1070-9916(199433)1:3<>1.0.TX;2-I',
	'0002-9769(199606/07)27:6<>1.0.TX;2-1',
	'0916-6564(199503)55<>1.0.TX;2-G',
	'1048-6542(1996)7:4<>1.0.CO;2-W',
	'0730-2312(199512)131:6:2<>1.0.TX;2-K',
	'0024-2160(199412)6:16:4<>1.0.TX;2-T',
	'0926-5473(1992)A:7<>1.0.TX;2-7',
	'0913-5707(199403)J77A:3<>1.0.TX;2-6',
	'0361-526X(199021/22)17:3/4<>1.0.TX;2-P',
	'1055-2685(19950623)21:13<>1.0.TX;2-I',
	'0095-5892(198408)21:8+<1:CD>2.0.TX;2-O',
	'0093-7673(19950910)+<>1.0.TX;2-R',
	'0015-6914(19950605)+<27:AMMIH>2.0.TX;2-I',
	'0031-9015(1985)43:13<>1.0.TX;2-M',
	'0095-4403(199502/03)21:3<>1.0.TX;2-Z',
	'1068-5723(19930729)1:5<>1.0.CO;2-6',
	'0730-9295(199206)11:2<168:CRFAOC>2.0.TX;2-#',
	'1064-6965(19950403)12:13<III.C.1:NAFS>2.0.CO;2-7',
	'0048-4474(199623)<:F>2.0.CO;2-T',
	'0036-8075(19950224)267<1186:AT3AAL>2.0.TX;2-W',
	'8756-2324(198603/04)65:2<4:QTAP>2.0.TX;2-I',
	'0003-9632(198307/09)46:3+<1:LPLMSL>2.0.TX;2-I',
	'0741-8647(199503)12:3<81:ATIS>2.0.TX;2-G',
	'1069-7799(19950223)4:14<1:LPF$MI>2.0.CO;2-Q',
	'0163-8610(199006)19<6:IITCD>2.0.TX;2-L',
	'0149-4953(199504)24:4<118:T$BTC>2.0.TX;2-J',
	'0010-2571(1934/1935)7<307:DFDDD=>2.0.TX;2-P',
	'0006-2510(19950506)107:18<94:BIMAJF>2.0.TX;2-F',
	'0015-6914(19960101)157:1<S-5:SBT>2.0.TX;2-L',
	'0002-8231(199412)45:10<>1.2.TX;2-J',
	'0165-3806(1996)<::PII-S1065-3806(96)000403-8>3.0.TX;2-6',
	'0737-8831(1993)11:1<94:MEMAWT:ERIC-EJ462869>3.0.TX;2-8',
	'0361-526X(199021/22)17:3/4<187:TSAATI>2.0.TX;2-G',
	'0095-4403(199502/03)21:3<12:WATIIB>2.0.TX;2-J',

	#'1080-6563(199606)20:1<>1.0.CO;2-O', # ?
	#'0096-736X(1990)*<>1.0.HE;2-3', # wrong check char?
	#'0899-1847(199503)13:3<18:AF4CNT>2.0.TX;2-7', # wrong check char?
	#'0015-6914(19960101)157:1<S-4>2.2.TX;2-R', # wrong check char?
	#'0002-8231(199412)45:10<760:AEPMFA:CCC-0002-8231/94/10,00760-05>3.0.TX;2-D', # wrong check char?
	)
{
	my ( $valid, $roundTrip, $parserProblems ) = $sici->parse($_);

	is( $valid, 1,
		      "parse valid SICI; '$_'; parser problems: "
			. join( '; ', @{$parserProblems} )
			. "; validity problems: "
			. Dumper( { $sici->list_problems() } ) );
	is( $roundTrip, 1, "successful round-trip; in: '$_', out: '" . $sici->to_string() . "'" );

	$sici->reset;
} ## end foreach ( '1234-5679(1996)<::INS-023456>3.0.CO;2-#'...)

done_testing();
