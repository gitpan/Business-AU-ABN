#!/usr/bin/perl -w

# Formal testing for Business::AU::ABN

use strict;
use File::Spec::Functions qw{:ALL};
use lib catdir( updir(), updir(), 'modules' ), # Development testing
        catdir( updir(), 'lib' );              # Installation testing
use UNIVERSAL 'isa';
use Test::More tests => 38;

# Check their perl version
BEGIN {
	$| = 1;
	ok( $] >= 5.005, "Your perl is new enough" );
}





# Does the module load
use_ok( 'Business::AU::ABN' );




# Some checks we don't catch below
is( Business::AU::ABN->new, undef, 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( undef ), undef, 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( '' ), undef, 'Bad ->new call returns as expected' );
is( Business::AU::ABN->new( ' ' ), undef, 'Bad ->new call returns as expected' );
isa_ok( Business::AU::ABN->new( '1' ), 'Business::AU::ABN' );
isa_ok( Business::AU::ABN->new( 'a' ), 'Business::AU::ABN'  );
isa_ok( Business::AU::ABN->new( ' 1' ), 'Business::AU::ABN'  );
my $foo = Business::AU::ABN->new( '    a    ' );
isa_ok( $foo, 'Business::AU::ABN'  );
is( $foo->to_string, '    a    ', "Correct string retrieved" );
is( "$foo", '    a    ', "Object stringifies correctly" );



# The main set of checks
my @tests = (
	undef              ,  '',   # Use , and not => otherwise undef becomes 'undef'
	''                 => '',
	' '                => '',
	'a'                => '',
	'1'                => '',
	'31 103 572 158'   => '31 103 572 158',
	'31103572158'      => '31 103 572 158',
	' 31 103 572 158 ' => '31 103 572 158',
	'31 103 572 157'   => '',
	'31 103 572 157 '  => '',
	);
while ( @tests ) {
	check_validation( shift(@tests), shift(@tests) );
}





# Do a validation check in all four forms
sub check_validation {
	my $value = shift;
	my $result = shift;
	my $message = defined $result ? "'$result'" : 'undef';

	# Check the full function form
	is( Business::AU::ABN::validate( $value ), $result, "Function     : $message" );

	# Check the static method form
	is( Business::AU::ABN->validate( $value ), $result, "Static method: $message" );

	# Check the object method form
	my $ABN = Business::AU::ABN->new( $value );
	if ( $result ) {
		isa_ok( $ABN, 'Business::AU::ABN' );
	} else {
		# It's ok, we can handle an error
		return 1;
	}

	is( $ABN->validate, $result, "Object method: $message" );
}

1;
