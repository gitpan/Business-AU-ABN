require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Business::AU::ABN',
	'VERSION_FROM' => 'lib/Business/AU/ABN.pm',
	'PREREQ_PM'    => {
		List::Util => 1.11,

		# For the tests
		File::Spec => 0.83,
		Test::More => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'   => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT' => 'Format and validate ABNs ( Australian Business Number )',
	) : (),
);
