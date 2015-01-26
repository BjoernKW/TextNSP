=head1 NAME

Text::NSP::DataSplitter - 	A package implementing the input data splitter functionality

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

  use Text::NSP::Counter

=head1 DESCRIPTION

=head2 Error Codes

=head2 Methods

=over

=cut

package Text::NSP::Combiner;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use support function library module
use Text::NSP::Environment::SupportFunctionLibrary;

# use tokenizer module
use Text::NSP::Environment::Tokenizer;

our ($VERSION);

$VERSION = '0.0.2';

# constructor
sub new {
	my ($class) = @_;
	my $ngrams;
	my $ngramTotal;
	my $frequencies;
	my $self = {
		ngrams => $ngrams,
		ngramTotal => $ngramTotal,
		frequencies => $frequencies,
	};
	bless($self, $class);
	return $self;
}

# function that starts the n-gram combining process
sub start {
	my ($self, $argv) = @_;
	
	# initialise variable for total number of n-grams
	my $ngramTotal = 0;
	
	# define n-gram hash
	my %ngrams;
	
	# define frequency hash
	my %frequencies;
	
	
	## initialise some support classes and methods

	# initialise option reader
	my $optionReader = new Text::NSP::Environment::OptionReader();
	
	# initialise support function library
	my $supportFunctionLibrary = new Text::NSP::Environment::SupportFunctionLibrary();

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
		my @defaults = ("--ngram", 2);
		$options = $optionReader->getCommandLineArgs(\@defaults, $argv);
	}

	# cut off option
	unless (defined $options->{cutoff}) {
		$options->{cutoff} = 0;
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
	
	# check for source files
	unless (defined $options->{count}) {
		print STDERR "ERROR: An insufficient number of n-gram model files was supplied.\n";
		exit(1);
	}
	
	# if number of source files is < 2, abort
	unless (@{$options->{count}} >= 2) {
		print STDERR "ERROR: An insufficient number of n-gram model files was supplied.\n";
		exit(1);
	}
	
	# iterate over source files
	foreach my $file (@{$options->{count}}) {
		# check if file exists
		unless (-e $file) {
			print STDERR "ERROR: N-gram model file ($file) does not exist.\n";
			exit(1);
		}
	}


	## preliminaries done, main program starts here!
	
	# define line number
	my $lineNumber;

	# define variable for n-gram string
	my $ngramString;
	
	# define variable for n-gram scores
	my $scores;
	
	# define array for storing split score
	my @splitScore;
	
	# define hash for storing split scores
	my %splitScores;
	
	# get frequency combinations	
	my $frequencyCombinations = $supportFunctionLibrary->getFrequencyCombinations($options->{ngram});

	# initialise tokenizer
	my $tokenizer = new Text::NSP::Environment::Tokenizer(
						\%ngrams,
						$ngramTotal,
						\%frequencies,
						$frequencyCombinations,
						$options->{ngram}
					);

	# iterate over source file stack
	foreach my $source (@{$options->{count}}) {
		# reset line number
		$lineNumber = 0;

		# open input file
		open(IN, $source)
			|| die("Can't open n-gram model file <$source>.\n");
			  		
		# iterate over model
		while (<IN>) {
			# increment line number
			$lineNumber++;
					
			# chomp
			chomp($_);
			
			# first line, get total number of n-grams
			if (/^(\d+)\s*$/) {
				if ($lineNumber == 1) {
					# get total and to existing value
					$ngramTotal += $1;
					next;
				} else {
					# malformed input
					print STDERR "Line $lineNumber in NGRAM file <$source> seems to be malformed.\n";
					exit(1);
				}
			}
	
	
			## process scores
			
			# check for scores
			if (/(^.*?<>)([\d|\s]+)$/) {
				# get n-gram and scores
				$scores = $2;
				$ngramString = $1;

				# split scores
				@splitScore = split(/ /, $scores);

				# add information from this line to queue for
				# merge process
				$tokenizer->addNgramEntry($ngramString, \@splitScore, $source);
			} elsif (!(/\s*/)) {
				# malformed input
				print STDERR "Line $lineNumber in NGRAM file <$source> seems to be malformed.\n";
				exit(1);
			}
		}
		
		# close model file
		close(IN);
	}

	# merge models
	$tokenizer->merge();
	
	# if remove n-grams option has been set,
	# remove n-grams below given frequency
	if ($options->{remove} != 0) {
	    foreach my $ngram (keys(%ngrams)) {
    		if ($ngrams{$ngram} < $options->{remove}) {
    			$tokenizer->removeNgram($ngram);
    		}
    	}
	}

	# try to open destination file
	open(DST, ">$options->{destination}")
		|| die("Couldn't open output file: $options->{destination}");

	# print out the total ngrams
	print DST "$ngramTotal\n";

	# close destination file
	close(DST);

	# print merged n-gram counts to destination file
	$tokenizer->printTokens($options);
}

# function for printing a minimal usage note when the user has not provided any
# command line options
sub showMinimalUsageNotes {
	print STDERR "Usage: huge-combine.pl [OPTIONS] --destination DESTINATION --count FILE+\n";
	showAskHelp();
}

# function for printing help messages for this program
sub showHelp {
	print "Usage: huge-combine.pl [OPTIONS] --destination DESTINATION --count FILE+\n";
	print "Combines two or more n-gram FILES and writes the results to DESTINATION.\n\n";

	print "Options:\n\n";

	print "  --ngram N          Combines n-grams files of N tokens for each entry.\n";
	print "						N = 2 by default.\n\n";
    print "  --help             Displays this message.\n\n";
    print "  --version          Displays the version information.\n\n";
   	print "Type 'perldoc huge-combine.pl' for a detailed documentation of this program.\n";
}

# function for printing the version number
sub showVersion {
	print "huge-combine.pl      -        version 0.02\n";
	print "Copyright (C) 2006, Bjoern Wilmsmann\n";
	print "Copyright (C) 2004, Amruta Parundare & Ted Pedersen\n";
	print "Date of Last Update 30/11/06\n";
}

# function for printing an 'ask for help' message
sub showAskHelp {
	print STDERR "Type huge-combine.pl --help for help.\n";
	print STDERR "Type 'perldoc split-data.pl' for detailed description of this program.\n"
}

1;

__END__

