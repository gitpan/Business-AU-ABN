package Business::AU::ABN;

# Implements algorithm for validating ABNs, detailed by the ATO at
# http://www.ato.gov.au/content/downloads/nat2956.pdf

# See POD at the end of the file

### Memory Overhead: 52K

use strict;
use UNIVERSAL 'isa';
use base 'Exporter';
use List::Util ();
use overload '""' => 'to_string';

use vars qw{$VERSION @EXPORT_OK $errstr @_WEIGHT};
BEGIN {
	$VERSION = "0.3";
	@EXPORT_OK = 'validate_abn';
	$errstr = '';

	# The set of digit weightings, taken
	# directly from the documentation.
	@_WEIGHT = (10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19);
}





sub new {
	my $class = ref $_[0] || $_[0];

	# Validate the string to create the object for
	my $validated = $class->_validate_abn($_[1]) or return '';

	# Create the object
	bless \$validated, $class;
}

# The validate_abn method acts as a wrapper for the various call
# forms around the true method _validate_abn.
sub validate_abn {
	isa( $_[0], 'Business::AU::ABN' )
		? ref $_[0]
			? shift->to_string            # Object method
			: shift->_validate_abn(shift) # Class method
		: __PACKAGE__->_validate_abn(shift);  # Function call
}

# Do the ACTUAL check, called in class method context only.
# I've tried to keep the code here very very simple, which takes a 
# little more memory, but is much more obvious in function.
# Returns true if correct, false if not, or undef on error.
sub _validate_abn {
	my $class = shift;

	# Reset the error string	
	$errstr = '';

	# Make sure we at least have a string to check
	my $abn = $class->_string($_[0]) ? shift 
		: return $class->_error( 'No value provided to check' );

	# Check we have only whitespace and digits
	if ( $abn =~ /[^\s\d]/ ) {
		return $class->_error( 'ABN contains invalid characters' );
	}

	# Remove all whitespace
	$abn =~ s/\s+//gs;

	# Initial validation is based on the number of digits.
	### A "Group ABN" exists with 14 digits. 
	### We will add support for this later.
	unless ( length $abn == 11 ) {
		return $class->_error( "ABNs are 11 digits, not " . length $abn );
	}

	# Split the 11 digit ABN into an 11 element array
	my @digits = $abn =~ /\d/g;

	# Quotes are directly from the algorithm documentation
	# "Step 1. Subtract 1 from the first ( left ) digit to give a new 11 digit number"
	$digits[0] -= 1;

	# "Step 2. Multiply each of the digits in this new number by its weighting factor"
	@digits = map { $digits[$_] * $_WEIGHT[$_] } (0 .. 10);

	# "Step 3. Sum the resulting 11 products"
	# "Step 4. Divide the total by 89, noting the remainder"
	# "Step 5. If the remainder is zero the number is valid"
	# We find the modulus, which does 4 and 5 in one go.
	if ( List::Util::sum(@digits) % 89 ) {
		return $class->_error( 'ABN looks correct, but fails checksum' );
	}

	# Format and return
	$abn =~ s/^(\d{2})(\d{3})(\d{3})(\d{3})$/$1 $2 $3 $4/ or die "panic!";
	$abn;
}

# Get the ABN as a string
sub to_string { ${$_[0]} }

# Get the error message when validation returns false.
sub errstr { $errstr }





#####################################################################
# Utility Methods

# Is a value a normal string of at least one non-whitespace character
sub _string {
	!! (defined $_[1] and ! ref $_[1] and length $_[1] and $_[1] =~ /\S/);
}
sub _error {
	$errstr = $_[1] ? "$_[1]" : 'Unknown error while validating ABN';
	return ''; # False
}

1;

__END__

=pod

=head1 NAME

Business::AU::ABN - Validate and format Australian Business Numbers

=head1 SYNOPSIS

  # Create a new validated ABN object
  use Business::AU::ABN;
  my $ABN = new Business::AU::ABN( '12 004 044 937' );
  
  # Validate in a single method call
  Business::AU::ABN->validate_abn( '12 004 044 937' );
  
  # Validate in a single function call
  Business::AU::ABN::validate_abn( '12 004 044 937' );
  
  # The validate_abn function is also importable
  use Business::AU:ABN 'validate_abn';
  validate_abn( '12 004 044 937' );

=head1 DESCRIPTION

The Australian Business Number ( ABN ) is a government allocated number
required by all businesses in order to trade in Australia. It is intented to
provide a central, universal, and unique identifier for all businesses.

It's also rather neat, in that it is capable of self-validating. Much like
a credit card number does, a simple algorithm applied to the digits can
confirm that the number is valid. ( Although the business may not actually 
exist ). The checksum algorithm was specifically designed to catch situations
in which you get two digits the wrong way around, or something of that nature.

Business::AU::ABN provides a validation/formatting mechanism, and an object
form of an ABN number. ABNs are reformatted into the most preferred format,
'01 234 567 890'.

The object itself automatically stringifies to the it's formatted number, so
you can do things like C<print "Your ABN $ABN looks OK"> and other things of
that nature.

=head2 Highly flexible validation

Apart from the algorithm itself, most of this module is aimed at making the
validation mechanism as flexible and easy to use as possible.

With this in mind, the C<validate_abn> sub can be accessed in ANY form, and will
just "do what you mean". See the method details for more information.

Also, all validation will take just about any crap as an argument, and not die
or throw a warning. It will just return false.

=head1 METHODS

=head2 new $string

The C<new> method creates a new C<Business::AU::ABN> object. Takes as argument
a value, and validates that it is correct before creating the object. As such
if an object is provided that passes C<$ABN-E<gt>isa('Business::AU::ABN')>,
it IS a valid ABN and does not need to be checked.

Returns a new C<Business::AU::ABN> on success, or sets the error string and
returns false if the string is not an ABN.

=head2 $ABN-E<gt>validate_abn

When called as a method on an object, C<validate_abn> isn't really that useful,
as ABN objects are already assumed to be correct, but the method is included
for completeness sake.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid, or false if not.

=head2 Business::AU::ABN->validate_abn $string

When called as a static method, C<validate_abn> takes a string as an argument and
attempts to validate it as an ABN.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 Business::AU::ABN::validate_abn $string

When called directly as a fully referenced function, C<validate_abn> responds in
exactly the same was as for the static method above.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 validate_abn $string

The C<validate_abn> function can also be imported to your package and used
directly, as in the following example.

  use Business::AU::ABN 'validate_abn';
  my $abn = '01 234 567 890';
  print "Your ABN is " . validate_abn($abn) ? 'valid' : 'invalid';

The imported function reponds identically to the fully referenced function
and the static method.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 to_string

The C<to_string> method returns the ABN as a string. 
This is also the method called by the stringification overload.

=head2 errstr

When C<validate_abn> or C<new> return false, a message describing the problem
can be accessed via any of the following.

  # Global variable
  $Business::AU::ABN::errstr
  
  # Class method
  Business::AU::ABN->errstr
  
  # Function
  Business::AU::ABN::errstr()

=head1 TO DO

Add the method C<ACN> to get the older Australian Company Number from the
ABN, which is a superset of it.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

  http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business%3A%3AAU%3A%3AABN

For other issues, contact the author

=head1 AUTHORS

        Adam Kennedy ( maintainer )
        cpan@ali.as
        http://ali.as/

=head1 COPYRIGHT

Copyright (c) 2003-2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
