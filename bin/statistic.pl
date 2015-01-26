#!/usr/bin/env perl

=head1 NAME

statistic.pl

=head1 SYNOPSIS

Program taking an n-gram-frequency file (as created by count.pl) and subsequently
calculating statistical dependency between the n-grams. The statistical measure
according to which the dependency is to be calculated has to be supplied as a
library which will be dynamically loaded.
This is a complete re-write of the original script by Satanjeev Banerjee, bane0025@d.umn.edu
and Ted Pedersen, tpederse@d.umn.edu

=head1 DESCRIPTION

See perldoc README.pod

=head1 BUGS

=head1 SEE ALSO

 home page: 

=head1 AUTHORS

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse@d.umn.eduE<gt>

Satanjeev Banerjee,          Carnegie Mellon University
                             E<lt>satanjeev@cmu.eduE<gt>

Amruta Purandare,            University of Pittsburgh
                             E<lt>amruta@cs.pitt.eduE<gt>

Bridget Thomson-McInnes,     University of Minnesota Twin Cities
                             E<lt>bthompson@d.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

Bjoern Wilmsmann,            Ruhr-University Bochum
							 E<lt>bjoern@wilmsmann.deE<gt>

=head1 HISTORY

Last updated: $Id: statistic.pl,v 1.20 2006/11/21 17:45:00 Bjoern Wilmsmann

=head1 BUGS


=head1 SEE ALSO

http://topicalizer.com/bwilmsmann/wiki/index.php/TextNSP

http://groups.yahoo.com/group/ngram/

http://www.d.umn.edu/~tpederse/nsp.html


=head1 COPYRIGHT

Copyright (C) 2000-2006, Ted Pedersen, Satanjeev Banerjee, Amruta
Purandare, Bridget Thomson-McInnes, Saiyam Kohli and Bjoern
Wilmsmann

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut


#
###############################################################################
#
#                       -------         CHANGELOG       ---------
#
#version        date            programmer      List of changes       change-id
#
# 0.73		 16/11/2006		Bjoern Wilmsmann	re-write			  BW.73.1
#
# 0.72       08/02/2005            Ted        Made use of Config and
#                                             File::Spec modules to
#                                             detect system dependent
#                                             PATH variable separator
#                                             character - : or ; and
#                                             system dependent file
#                                             separator character - / or \.
#                                             Similar changes made to
#                                             all the .pm files in
#                                             Measures sub-directory
#
# 0.69       06/14/2004            Amruta     Changed the internal     ADP.71
#                                             N-gram separator #
#                                             to <||>
#
# 0.67       02/19/2004            Amruta     Used stat scores         ADP.67.1
#                                             as keys of the hash
#                                             instead of the N-grams
#                                             This reduces the memory
#                                             consumption when large
#                                             Ngrams have same scores
#
# 0.57       07/01/2003            Ted        (1) if destination file  TDP.57.3
#                                             found, check for
#                                             source before proceeding
#
###############################################################################
#-----------------------------------------------------------------------------
#                              Start of Program
#-----------------------------------------------------------------------------


## include external libraries

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use support function library module
use Text::NSP::Environment::SupportFunctionLibrary;

# use File::Spec
use File::Spec;


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
unless (@ARGV > 0) {
	# show usage notes and exit
	showMinimalUsageNotes();
	exit(1);
} else {
	# get options
	my @defaults = ("--ngram", 2, "--precision", 4);
	$options = $optionReader->getCommandLineArgs(\@defaults, \@ARGV);
}


## process options

# create the floating point conversion format as required by sprintf
my $floatFormat = join('', '%', '.', $options->{precision}, 'f');

# if help has been requested, print out help!
if (defined $options->{help}) {
    showHelp();
    exit(0);
}

# if version has been requested, show version!
if (defined $options->{version}) {
    showVersion();
    exit(0);
}


## frequency combinations

# define reference for frequency combinations
my $frequencyCombinations;

# get default frequency combinations (we won't allow getting combinations from file here,
# as this would lead to errors unless all possible frequency combinations for a given n-gram
# are supplied; since getting all possible frequency combinations is the default behaviour,
# there is no use for a 'supply frequency combinations via file' option)
$frequencyCombinations = $supportFunctionLibrary->getFrequencyCombinations($options->{ngram});

# define indices for frequency combinations for ngram size = 2
my $n11Index;
my $np1Index;
my $n1pIndex;

# define indices for frequency combinations for ngram size = 3
my $n111Index;
my $n1ppIndex;
my $np1pIndex;
my $npp1Index;
my $n11pIndex;
my $np11Index;
my $n1p1Index;

# define index for n-gram total
my $ngramIndex;

# get frequency combination indices according to n-gram size
my $i;
if ($options->{ngram} == 2) {
    # get combination indices
    $i = 0;
	foreach my $combination (@{$frequencyCombinations}) {
		my $combinationString = join (" ", @{$combination});
    	if ($combinationString eq "0 1")  {
    		$n11Index = $i;
    	} elsif ($combinationString eq "0") { 
    		$np1Index  = $i;
    	} elsif ($combinationString eq "1") {
    		$n1pIndex = $i;
    	}
    	$i++;
  	}
  	$ngramIndex = $n11Index;
} elsif ($options->{ngram} == 3) {
    # get combination indices
    $i = 0;
	foreach my $combination (@{$frequencyCombinations}) {
		my $combinationString = join (" ", @{$combination});
		if ($combinationString eq "0 1 2")  {
    		$n111Index = $i;
    	} elsif ($combinationString eq "0") { 
    		$n1ppIndex  = $i;
    	} elsif ($combinationString eq "1") {
    		$np1pIndex = $i;
		} elsif ($combinationString eq "2") { 
    		$npp1Index  = $i;
    	} elsif ($combinationString eq "0 1") {
    		$n11pIndex = $i;
    	} elsif ($combinationString eq "1 2") { 
    		$np11Index  = $i;
    	} elsif ($combinationString eq "0 2") {
    		$n1p1Index = $i;
		}
		$i++;
	}
  	$ngramIndex = $n111Index;
}

# if precision value is no integer, revert to default
unless ($options->{precision} =~ /^\d+$/) {
    print STDERR "Value for switch --precision should be integer >= 0. Using 4.\n";
    $options->{precision} = 4;
}

# write frequency combinations to file if option has been set
if (defined $options->{get_freq_combo}) {
	$supportFunctionLibrary->writeFrequencyCombinations($frequencyCombinations, $options->{get_freq_combo});
}

# check to see if a library has been supplied at all!
unless (defined $options->{library}) {
    print STDERR "No statistics library has been supplied.\n";
    askHelp();
    exit(1);
}


## statistics library

# now remove the ".pm" in the end of the statistic filename, if present
$options->{library} =~ s/\.pm$//;

# define error messages for loading statistics library
my $onlyBigramDefinedError = "Error: This measure is only defined for bigrams.\n";
my $onlyTrigramDefinedError = "Error: This measure is only defined for trigrams.\n";
my $onlyBigramAndTrigramDefinedError = "Error: This measure is only defined for bigrams and trigrams.\n";

# define variables for include and use directives
my $libraryCategory;
my $includeName;
my $useName;

# deal with the various ways a library might have been supplied in
# and set directives accordingly
if ($options->{library} =~ /::/) {
	# if library is given with complete path, separated by '::'
	my @libComponents = split(/::/, $options->{library});
	$libComponents[$#libComponents] = $libComponents[$#libComponents] . ".pm";
	$includeName = File::Spec->catfile(@libComponents);
	$useName = $options->{library};
} elsif ($options->{library} eq "ll" || $options->{library} eq "pmi"
		|| $options->{library} eq "tmi"
    	|| $options->{library} eq "ps") {
    		if ($options->{ngram} == 2 || $options->{ngram} == 3) {
    			$libraryCategory = "MI::";
  			} else {
    			print STDERR $onlyBigramAndTrigramDefinedError;
    			exit(1);
  			}
} elsif ($options->{library} eq "x2"|| $options->{library} eq "phi"
		|| $options->{library} eq "tscore") {
		if($options->{ngram} == 2) {
   			$libraryCategory = "CHI::";
  		} else {
			print STDERR $onlyBigramDefinedError;
    		exit(1);
  		}
} elsif ($options->{library} eq "leftFisher"||$options->{library} eq "rightFisher"||$options->{library} eq "twotailed") {
	if ($options->{ngram} == 2) {
    	if ($options->{library} eq "leftFisher") {
      		$options->{library} = "left";
    	} elsif ($options->{library} eq "rightFisher") {
		      $options->{library} = "right";
    	}
		$libraryCategory = "Fisher::";
  	} else {
    	print STDERR $onlyBigramDefinedError;
    	exit(1);
  	}
} elsif ($options->{library} eq "ll3"||$options->{library} eq "tmi3") {
  	$options->{library} =~ s/3//;
  	if($options->{ngram} == 3) {
		$libraryCategory = "MI::";
	} else {
		print STDERR $onlyTrigramDefinedError;
    	exit(1);
  	}
} elsif ($options->{library} eq "dice" || $options->{library} eq "jaccard") {
	if ($options->{ngram} == 2) {
		$libraryCategory = "Dice::";
  	} else {
    	print STDERR $onlyBigramDefinedError;
    	exit(1);
  	}
} elsif ($options->{library} eq "odds") {
	if($options->{ngram} == 2) {
		$libraryCategory = "";
  	} else {
    	print STDERR $onlyBigramDefinedError;
    	exit(1);
  	}
} else {
	# default category for both bigrams and trigrams
	if ($options->{ngram} == 2) {
		$libraryCategory = "";
  	} elsif ($options->{ngram} == 3) {
    	$libraryCategory = "";
  	} else {
    	print STDERR $onlyBigramAndTrigramDefinedError;
    	exit(1);
  	}
}

# build use and include directives
$useName = 'Text::NSP::Measures::' . $options->{ngram} . 'D::' . $libraryCategory . $options->{library};
$libraryCategory =~ s/::$//;
$includeName = File::Spec->catfile('Text', 'NSP', 'Measures', $options->{ngram}. 'D', $libraryCategory, $options->{library} . '.pm');

# use statistics library
require $includeName;
import $useName;

# if stat
if($options->{library} eq 'pmi' && defined $options->{pmi_exp}) {
    $useName->initializeStatistics($options->{pmi_exp});
} else {
	$useName->initializeStatistic();
 	if(defined $options->{pmi_exp}) {
    	print STDERR "The --pmi_exp parameter is not valid for the selected measure.\n";
  	}
}


## destination file

# check if a destination has been supplied
unless (defined $options->{destination}) {
	print STDERR "No output file (DESTINATION) supplied.\n";
	showAskHelp();
	exit(1);
}

# check to see if destination exists, and if so, ask if we should overwrite it
if (-e $options->{destination}) {
	print "Output file $options->{destination} already exists! Overwrite (Y/N)?";
	$reply = <STDIN>;
	chomp($reply);
	$reply = uc($reply);
	if ($reply ne "Y") {
		exit(0);
	}
}

# try to open destination file
open(DST, ">$options->{destination}" )
	|| die("Couldn't open output file: $options->{destination}\n");


## source file

# check if a source has been supplied..
unless (defined $options->{source}) {
    print STDERR "No input file (SOURCE) supplied.\n";
    askHelp();
    exit(1);
}

# now check if source exists.
unless (-e $options->{source}) {
    print STDERR "Can't find input file (SOURCE) $options->{source}.\n";
    exit(1);
}

# now open the source file.
open(SRC, "$options->{source}")
	|| die("Can't open input file $options->{source}, quitting.\n");


## read metadata

# line index
my $lineNo = 0;

# temporary variable for line content
my $tempLine;

# now read in the optional --extended data and write them out to the destination file
# if --extended has been selected
my $extendedFlag = 1;
while ($extendedFlag) {
    $tempLine = <SRC>;
    $lineNo++;

    if ($tempLine =~ /^@/ && !($tempLine =~ /^@@/ )) {
    	if (defined $options->{extended}) {
      		print DST $tempLine;
      	}
    } else {
    	$extendedFlag = 0;
    }
}

# $tempLine now should contain the total number of n-grams!
my $totalNgrams = $tempLine;

# chomp $totalNgrams
if (defined $totalNgrams) {
    chomp($totalNgrams);
}

# check to see if we really have an ngram-total
unless (defined $totalNgrams && $supportFunctionLibrary->isInteger($totalNgrams)) {
    print STDERR ("$options->{source} does not look like a n-gram frequency file at line number $lineNo.\n");
    exit(1);
}


## preliminaries done, main program starts here!

# define hash for storing statistical values
my %statistic;

# define variable for counter checking total number of n-grams
my $totalNgramCount = 0;

# go through each line of n-gram model
while (<SRC>) {
	# increment line index
    $lineNo++;
    
    # chomp line content
    chomp($_);

    # store content in variable
    my $ngramString = $_;

    # split by '<>'. thus @tokens will have all the separate tokens
    # that make up this n-gram and its last element will be the string
    # of space separated numbers
    my @tokens = split(/<>/, $ngramString);

    # check if we have enough tokens! if not, complain and quit
    if ($#tokens != $options->{ngram}) {
      print STDERR "Wrong number of tokens in n-gram on line $lineNo. Expecting $options->{ngram}.\n";
      exit(1);
    }

    # put the frequency values for this n-gram into @numbers
    my @numbers = split(/ /, $tokens[$#tokens]);

    # remove the last element from tokens (the n-gram frequencies)
    pop(@tokens);

    # check, if the number of frequency values is equal to the number
    # of frequency combinatiosn
    if ($#numbers != @{$frequencyCombinations} - 1) {
      print STDERR "Wrong number of frequency values on line $lineNo. Expecting"
      				. @{$frequencyCombinations} - 1
      				. "\n";
      exit(1);
    }

    # if we are doing frequency cutoffs and the frequency of this
    # n-gram is below the cut off level, then skip this iteration of
    # the loop
    if (defined $options->{frequency} && $numbers[$ngramIndex] < $options->{frequency}) {
    	next;
    }
    
    # define reference for storing n-gram frequency values
    my %values;
    
    # write values to hash, according to given n-gram size
    if ($options->{ngram} == 2) {
      	%values = (
      				n11 => $numbers[$n11Index],
					n1p => $numbers[$n1pIndex],
					np1 => $numbers[$np1Index],
        			npp => $totalNgrams
        		  );
    } elsif ($options->{ngram} == 3) {
    	%values = (
    				n111 => $numbers[$n111Index],
        			n1pp => $numbers[$n1ppIndex],
        			np1p => $numbers[$np1pIndex],
        			npp1 => $numbers[$npp1Index],
        			n11p => $numbers[$n11pIndex],
        			n1p1 => $numbers[$n1p1Index],
        			np11 => $numbers[$np11Index],
        			nppp => $totalNgrams
        		  );
    }

	# add to total n-gram count
   	$totalNgramCount += $numbers[$ngramIndex];

    # calculate the statistic and create the statistic hash by
    # using the function implemented by the respective statistics
    # library
    my $statisticValue = calculateStatistic(%values);
    
    # check for errors/warnings
    my $errorCode;
    my $errorMessage = "";
    if($errorCode = $useName->getErrorCode()) {
      # error
      if ($errorCode =~ /^1/) {
        printf(STDERR "Error from statistic library!\n  Error code: %d\n", $errorCode);
        $errorMessage = $useName->getErrorMessage();
        unless ($errorMessage eq "") {
	        print STDERR "Error message: $errorMessage\n";
        }
        exit(1);
      }
      
      # warning
      if ($errorCode =~ /^2/) {
        printf(STDERR "Warning from statistic library!\n  Warning code: %d\n", $errorCode);
        $errorMessage = $useName->getErrorMessage();
        unless ($errorMessage eq "") {
	        print STDERR "Warning message: $errorMessage\n";
        }
        print STDERR "Skipping ngram $ngramString\n";
        next;
      }
    }

	# get score for this n-gram
    my $statisticScore = sprintf($floatFormat, $statisticValue);

    # n-grams stored in %statistic are separated by <||>
    if ($ngramString =~ /<\|\|>/) {
		print STDERR "Detected sequence <||> within n-gram $ngramString.\n" . 
					 "statistic.pl will not behave as expected.\n";
  		exit(1);
    }
    
    # write score to statistics hash
    $statistic{$statisticScore} .= $ngramString."<||>";
}

# close source file
close(SRC);


## validate source file

# to check that the sum of all Ngram counts is less than or equal
# to the total Ngram count.
if($totalNgramCount > $totalNgrams) {
    print STDERR ("$options->{source} does not look like a ngram frequency file. The total ngrams should be greater than the sum of counts of all the ngrams.");
    exit(1);
}


## output

# that completes the calculations. now to write out the data onto the
# destination file, ranking the ngrams according to the statistic just
# calculated. we will do formatted as well as unformatted printing.
# but first print out some @ data if -extended is chosen
$options->{library} = $useName->getStatisticName();

# if extended output was requested
if (defined $options->{extended}) {
    # name of statistics library
    print DST "\@statistic.StatisticName=$options->{library}\n";

    # formatted/unformatted output
    if (defined $options->{format}) {
  		print DST "\@statistic.Formatted=1\n";
    } else {
    	print DST "\@statistic.Formatted=0\n";
    }

    # frequency cut off
    if (defined $options->{frequency}) {
    	print DST "\@statistic.Frequency=$options->{frequency}\n";
    }

    # rank
    if ($options->{show} > 0) {
    	print DST "\@statistic.Rank=$options->{show}\n";
    }

    # score cut off
    if (defined $options->{score}) {
    	print DST "\@statistic.Score=$options->{score}\n";
    }
}

# close destination file
close(DST);

# print in a formatted or unformatted fashion
$supportFunctionLibrary->printStatistic($options, $totalNgrams, \%statistic);


## help displayer functions

# function to output a minimal usage note when the user has not provided any
# commandline options
sub showMinimalUsageNotes {
    print "Usage: statistic.pl [OPTIONS] --library STATISTICS_LIBRARY --destination DESTINATION --source SOURCE\n";
    showAskHelp();
}

# function to output help messages for this program
sub showHelp {
    print "Usage: statistic.pl [OPTIONS] --library STATISTICS_LIBRARY --destination DESTINATION --source SOURCE\n\n";

    print "Loads the given STATISTICS_LIBRARY, calculates the statistic on n-grams\n";
    print "in SOURCE and outputs results to DESTINATION. SOURCE must be an\n";
    print "n-gram-frequency file output by count.pl. N-grams in DESTINATION are\n";
    print "ranked on the value of their statistic.\n\n";

    print "OPTIONS:\n\n";

    print "  --ngram N          Assumes that n-grams in SOURCE file have N\n";
    print "                     tokens each. N = 2 by default.\n\n";

    print "  --get_freq_combo FILE \n";
    print "                     Prints out the frequency combinations being\n";
    print "                     used to FILE. If frequency combinations have\n";
    print "                     been provided through --set_freq_combo switch\n";
    print "                     above these are output; otherwise the default\n";
    print "                     combinations being used are output.\n\n";

    print "  --frequency N      Ignores all n-grams with frequency < N.\n\n";

    print "  --show N           Shows only n-grams with rank <= N (undefined means 'show all').\n\n";

    print "  --precision N      Displays values upto N places of decimal.\n\n";

    print "  --score N          Shows only n-grams which have score >= N.\n\n";
    
    print "  --pmi_exp N		Additional exponent option for the PMI measure.\n\n";

    print "  --extended         Outputs chosen parameters in \"extended\"\n";
    print "                     format, and retains any extended data in\n";
    print "                     SOURCE. By default, suppresses any extended\n";
    print "                     information in SOURCE, and outputs no new\n";
    print "                     parameters.\n\n";

    print "  --format           Creates formatted output.\n\n";

    print "  --version          Prints the version number.\n\n";

    print "  --help             Prints this help message.\n\n";

}

# function to show version number
sub showVersion {
    print "statistic.pl     -      version 0.73\n";
    print "Copyright (C) 2006, Bjoern Wilmsmann\n";
    print "Copyright (C) 2000-2004, Ted Pedersen, Satanjeev Banerjee, Amruta Purandare\n";
    print "Date of Last Update: 21/11/2006\n";
}

# function to output "ask for help" message when the user's goofed up!
sub showAskHelp {
    print STDERR "Type statistic.pl --help for help.\n";
}

