package Business::AU::ABN;

# See POD at the end of the file

use strict;
use UNIVERSAL 'isa';
use base 'Exporter';
use List::Util ();
use overload '""' => 'to_string';

use vars qw{$VERSION @EXPORT_OK @_WEIGHT};
BEGIN {
	$VERSION = "0.2";
	require Exporter;
	@EXPORT_OK = 'validate';

	# The set of digit weightings
	@_WEIGHT = (10, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19);
}






sub new {
	my $class = shift;

	# Make sure the argument is a normal string
	# with at least one non-whitespace character.
	$class->_string($_[0]) or return undef;

	bless \(my $tmp = shift), $class;
}

# The validate method acts as a wrapper for the various call
# forms around the true method _validate.
sub validate {
	my $self = isa( ref $_[0], 'Business::AU::ABN' )
		? shift                             # Object method
		: isa( $_[0], 'Business::AU::ABN' )
			? shift->new( @_ )          # Static method
			: __PACKAGE__->new( @_ )    # Function call
		or return '';
	$self->_validate ? "$self" : '';
}

# Do the ACTUAL check, called in object method context only.
# Implements algorithm for validating ABNs provided by the ATO at
# http://www.ato.gov.au/content/downloads/nat2956.pdf
# I've tried to keep the code here very very simple, which takes a 
# little more memory, but is much more obvious in function.
# Returns true if correct, false if not, or undef on error.
sub _validate {
	my $self = isa( ref $_[0], 'Business::AU::ABN' ) ? shift : return undef;

	# Check we have only whitespace and digits
	if ( $$self =~ /[^\s\d]/ ) {
		return ''; # "ABN contains invalid characters"
	}

	# Strip off leading and trailing whitespace
	$$self =~ s/^\s+//;
	$$self =~ s/\s+$//;

	# Do any further checks on a copy, so we don't over-alter
	# their value on success.
	my $abn = $$self;

	# Remove all remaining whitespace
	$abn =~ s/\s+//gs;

	# Initial validation is based on the number of digits.
	### A "Group ABN" exists with 14 digits. We will add support for this later.
	unless ( length $abn == 11 ) {
		return ''; # "ABNs are 11 digits, not" . length $abn
	}

	# Since it is the correct length, update the object with the
	# correct layout of the digits. From this point on, we won't
	# need to modify the value.
	$$self = $abn;
	$$self =~ s/^(\d\d)(\d\d\d)(\d\d\d)(\d\d\d)$/$1 $2 $3 $4/ or die "panic!";

	# Split the 11 digit ABN into an 11 element array
	my @digits = split /(?<=\d)(?=\d)/, $abn;

	# Algorithm Step 1
	# "Subtract 1 from the first ( left ) digit to give a new 11 digit number"
	$digits[0] -= 1;

	# Algorithm Step 2
	# "Multiply each of the digits in this new number by its weighting factor"
	my @products = map { $digits[$_] * $_WEIGHT[$_] } (0 .. 10);

	# Algorithm Step 3
	# "Sum the resulting 11 products"
	my $sum = List::Util::sum( @products );

	# Algorithm Step 4
	# "Divide the total by 89, noting the remainder"
	my $remainder = $sum % 89;

	# Algorithm Step 5
	# "If the remainder is zero the number is valid"
	unless ( $remainder == 0 ) {
		return ''; # Incorrect ABN, fails checksum
	}

	# The number is valid
	return 1;
}

# Get the ABN as a string
sub to_string { ${$_[0]} }





#####################################################################
# Utility Methods

# Is a value a normal string of at least one non-whitespace character
sub _string {
	my ($class, $string) = @_;
	!! (defined $string and ! ref $string and length $string and $string =~ /\S/);
}

1;

__END__

=pod

=head1 NAME

Business::AU::ABN - Format and validate ABNs ( Australian Business Number )

=head1 SYNOPSIS

  # Create a new ABN object
  use Business::AU::ABN;
  my $ABN = new Business::AU::ABN( '12 004 044 937' );
  
  # Validate the ABN
  $ABN->validate;
  
  # Validate in a single method call
  Business::AU::ABN->validate( '12 004 044 937' );
  
  # Validate in a single function call
  Business::AU::ABN::validate( '12 004 044 937' );
  
  # The validate function is also importable
  use Business::AU:ABN 'validate';
  validate( '12 004 044 937' );

=head1 DESCRIPTION

The Australian Business Number ( ABN ) is a government allocated number
required by all businesses in order to trade in Australia. It is intented to
provide a central, universal, and unique identifier for all businesses.

It's also rather neat, in that it is capable of self-validating. Much like
a credit card number does, a simple algorithm applied to the digits can
confirm that the number is valid. ( Although the business may not actually 
exist ). The checksum algorithm is specifically designed to catch situations
in which you get two digits the wrong way around, or worse.

Business::AU::ABN implements an object form of an ABN number. It has the 
ability to validate, and automatically reformates the number into the common
and most prefered format, '01 234 567 890'.

The object itself automatically stringifies to the it's formatted number, so
you can do things like C<print "Your ABN $ABN looks OK"> and other things of
that nature.

=head2 Highly flexible validation

Apart from the algorithm itself, most of this module is aimed at making the
validation mechanism as flexible and easy to use as possible.

With this in mind, the C<validate> sub can be accessed in ANY form, and will
just "do what you mean". See the method details for more information.

=head1 METHODS

=head2 new $string

The C<new> method creates a new C<Business::AU::ABN> object. It expects as
argument a defined string containing at least one non-whitespace character,
or it will immediately return C<undef>.

The method does not reformat or check the string provided in any way.

=head2 to_string

The C<to_string> method returns the ABN as a string. This is the method called
by the stringification overload. Providing that the ABN has been validated,
this method will return the ABN in the correct '01 234 567 890' format.

=head2 $ABN-E<gt>validate

When called as a method on an object, C<validate> does a number of simple 
format checks on the string originally provided, cleaning up and reformatting
whitespace as needed. It then runs a checksum validation on the value.

Returns true if the ABN is valid, or false if not

=head2 Business::AU::ABN->validate $string

When called as a static method, C<validate> takes a string as an argument and
attempts to validate it. When called in this form, the method is a little more
flexible, and should tolerate just about any crap as an argument, returning 
false.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 Business::AU::ABN::validate $string

When called directly as a fully referenced function, C<validate> responds in
exactly the same was as for the static method above.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head2 validate $string

The C<validate> function can also be imported to your package and used
directly, as in the following example.

  use Business::AU::ABN 'validate';
  my $abn = '01 234 567 890';
  print "Your ABN is " . validate($abn) ? 'valid' : 'invalid';

The imported function reponds identically to the fully referenced function
and the static method.

Returns the correctly formatted ABN (which is also 'true' in boolean context)
if the ABN is valid. Returns false otherwise.

=head1 TO DO

Add the method C<acn> to derive the older Australian Company Number

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
