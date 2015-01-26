=head1 NAME

Text::NSP::NgramSorter - 	A package implementing the n-gram sorting facility

=head1 AUTHORS

Ted Pedersen, tpederse@d.umn.edu
Amruta Purandare, pura0010@umn.edu
Bjoern Wilmsmann, bjoern@wilmsmann.de

=head1 COPYRIGHT

Copyright (C) 2006, Bjoern Wilmsmann
Copyright (C) 2004, Ted Pedersen and Amruta Purandare

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=head1 BUGS

=head1 SEE ALSO

 home page:		http://topicalizer.com/bwilmsmann/wiki/index.php/TextNSP
				http://www.d.umn.edu/~tpederse/nsp.html

 mailing list: 	http://groups.yahoo.com/group/ngram/

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::NgramSorter

=head1 DESCRIPTION

=head2 Error Codes

=head2 Methods

=over

=cut

package Text::NSP::NgramSorter;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use tokenizer module
use Text::NSP::Environment::Tokenizer;

our ($VERSION);

$VERSION = '0.0.4';

# constructor
sub new {
	my ($class) = @_;
	my $self = {};
	bless($self, $class);
	return $self;
}

# function that starts the n-gram sorting process
sub start {
	my ($self, $argv) = @_;
	
	## initialise some support classes and methods

	# initialise option reader
	my $optionReader = new Text::NSP::Environment::OptionReader();

	# define options reference
	my $options;

	# define variable for interactive user input
	my $reply;


	## start

	# check if no command line options have been supplied
	unless (@{$argv} > 0) {
		# show usage notes and exit
		showMinimalUsageNotes();
		exit(1);
	} else {
		# get options
		my @defaults = ("--destination", "sortedOutput.txt", "--mode", "ngram");
		$options = $optionReader->getCommandLineArgs(\@defaults, $argv);
	}


	## process options

	# if help has been requested, show help, then exit
	if (defined $options->{help}) {
		showHelp();
		exit(0);
	}
	
	# if version display has been requested, show help, then exit
	if (defined $options->{version}) {
		showVersion();
		exit(0);
	}

	# error for simultaneous usage of --remove and --freqeuncy
	if (defined $options->{remove} && defined $options->{frequency}) {
		print STDERR "ERROR: --remove and --frequency can't be both used simultaneously.\n";
		exit(1);
	}
	
	# error for missing --model
	unless (defined $options->{model}) {
		print STDERR "ERROR: No n-gram model has been supplied.\n";
		exit(1);
	}


	## preliminaries done, main program starts here!

	# initialise line number
	my $lineNumber = 0;

	# try to open n-gram model file
	open(MODEL, $options->{model})
		|| die("Couldn't open n-gram model file: $options->{model}");

	# define hash for n-grams
	my %ngrams;

	# define variable for n-gram string
	my $ngramString;
	
	# define variable for n-gram score
	my $score;
	
	# define variable for total number of n-grams
	my $total;

	# iterate over model
	while (<MODEL>) {
		# increment line number
		$lineNumber++;
		
		# chomp
		chomp($_);

		# first line, get total number of n-grams
		if (/^(\d+)\s*$/) {
			if ($lineNumber == 1) {
				# get total
				$total = $1;
				next;
			} else {
				# malformed input
				print STDERR "Line $lineNumber in NGRAM file <$options->{model}> seems to be malformed.\n";
				exit(1);
			}
		}
		

		## process scores

		# n-gram count
		if ($options->{mode} eq "ngram") {
			# n-gram count
			if (/^.*?(\d+)\s+.*$/) {
				# get n-gram count
				$score = $1;
				$ngramString = $_;
			} else {
				# malformed input
				print STDERR "Line $lineNumber in NGRAM file <$options->{model}> seems to be malformed.\n";
				exit(1);
			}
		}
		
		# statistical value
		if ($options->{mode} eq "stat") {
			if (/^.*?(\d+)\s+?(-?\d+\.?\d*)\s+.*$/) {
				# get statistical value
				$score = $2;
				$ngramString = $_;
			} else {
				# malformed input
				print STDERR "Line $lineNumber in NGRAM file <$options->{model}> seems to be malformed.\n";
				exit(1);
			}
		}
		
		# push this n-gram to array of n-grams with this particular score
		push(@{$ngrams{$score}}, $ngramString);
		
		# if n-grams below a certain frequency are not to be displayed
		if (defined $options->{frequency}) {
			if ($score < $options->{frequency}) {
				next;
			}
		}
		
		# if n-grams below a certain frequency are to be deleted
		if (defined $options->{remove}) {
			if ($score < $options->{remove}) {
				$total -= $score;
				next;
			}
		}
	}
	
	# close model file
	close(MODEL);
	
	# try to open destination file
	open(DST, ">$options->{destination}" )
		|| die("Couldn't open output file: $options->{destination}");
	
	# print total
	print DST "$total\n";
	
	# print n-gram entries in a sorted fashion
	foreach my $thisScore (sort {$b <=> $a} keys(%ngrams)) {
		foreach my $thisNgram (@{$ngrams{$thisScore}}) {
			print DST $thisNgram . "\n";
		}
	}

	# close destination file
	close(DST);
}

# function for printing a minimal usage note when the user has not provided any
# command line options
sub showMinimalUsageNotes {
	print STDERR "Usage: sort-ngrams.pl [OPTIONS] --model NGRAM";
    showAskHelp();
}

# function for printing help messages for this program
sub showHelp {
	print "Usage:  sort-ngrams.pl [OPTIONS] --model NGRAM --destination DESTINATION\n";

	print "Sorts a given NGRAM file in the descending order of the n-gram scores.\n";
	print "NGRAM should be an n-gram count/score file that is to be sorted.\n";
	print "The sorted output will be written to DESTINATION.\n\n";

	print "OPTIONS:\n\n";
	
	print "  --frequency F      N-grams with counts/scores less than F will not be displayed.\n\n";
	
    print "  --remove L         N-grams with counts/scores less than L are removed from the sample.\n\n";
    
    print "  --mode X			X = ngram|stat\n";
    print "						This defines if an n-gram model or a model containing statistical\n";
    print "						dependencies is to be processed (default: ngram).\n\n";
    
    print "  --help             Displays this message.\n\n";
    print "  --version          Displays the version information.\n\n";
    
	print "Type 'perldoc sort-ngrams.pl' for a detailed documentation of this program.\n";
}

# function for printing the version number
sub showVersion {
	print "sort-ngrams.pl      -        version 0.04\n";
	print "Copyright (C) 2006, Bjoern Wilmsmann\n";
    print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen\n";
    print "Date of Last Update:     30/11/2006\n";
}

# function for printing an 'ask for help' message
sub showAskHelp {
	print STDERR "Type sort-ngrams.pl --help for help.\n";
	print "Type 'perldoc sort-ngrams.pl' for a detailed description of this program.\n"
}

1;

__END__
