#!/usr/bin/env perl

=head1 NAME

huge-count.pl

=head1 SYNOPSIS

Runs count.pl efficiently on a huge data.

=head1 USGAE

huge-count.pl [OPTIONS] DESTINATION [SOURCE]+

=head1 INPUT

=head2 Required Arguments:

=head3 [SOURCE]+

Input to huge-count.pl should be a -

=over

=item 1. Single plain text file

Or

item 2. Single flat directory containing multiple plain text files

Or

=item 3. List of multiple plain text files

=back

=head3 DESTINATION

A complete path to a writable directory to which huge-count.pl can write all 
intermediate and final output files. If DESTINATION does not exist, 
a new directory is created, otherwise, the current directory is simply used
for writing the output files. 

NOTE: If DESTINATION already exists and if the names of some of the existing 
files in DESTINATION clash with the names of the output files created by 
huge-count, these files will be over-written w/o prompting user. 

=head2 Optional Arguments:

=head4 --split P

This option should be specified when SOURCE is a single plain file. huge-count
will divide the given SOURCE file into P (approximately) equal parts, 
will run count.pl separately on each part and will then recombine the bigram 
counts from all these intermediate result files into a single bigram output 
that shows bigram counts in SOURCE.

If SOURCE file contains M lines, each part created with --split P will 
contain approximately M/P lines. Value of P should be chosen such that
count.pl can be efficiently run on any part containing M/P lines from SOURCE.
As #words/line differ from files to files, it is recommended that P should
be large enough so that each part will contain at most million words in total.

=head4 --token TOKENFILE

Specify a file containing Perl regular expressions that define the tokenization
scheme for counting. This will be provided to count.pl's --token option.

--nontoken NOTOKENFILE

Specify a file containing Perl regular expressions of non-token sequences 
that are removed prior to tokenization. This will be provided to the 
count.pl's --nontoken option.

--stop STOPFILE

Specify a file of Perl regex/s containing the list of stop words to be 
omitted from the output BIGRAMS. Stop list can be used in two modes -

AND mode declared with '@stop.mode = AND' on the 1st line of the STOPFILE

or

OR mode declared using '@stop.mode = OR' on the 1st line of the STOPFILE.

In AND mode, bigrams whose both constituent words are stop words are removed
while, in OR mode, bigrams whose either or both constituent words are 
stopwords are removed from the output.

=head4 --window W

Tokens appearing within W positions from each other (with at most W-2 
intervening words) will form bigrams. Same as count.pl's --window option.

=head4 --remove L

Bigrams with counts less than L in the entire SOURCE data are removed from
the sample. The counts of the removed bigrams are not counted in any 
marginal totals. This has same effect as count.pl's --remove option.

=head4 --frequency F

Bigrams with counts less than F in the entire SOURCE are not displayed. 
The counts of the skipped bigrams ARE counted in the marginal totals. In other
words, --frequency in huge-count.pl has same effect as the count.pl's 
--frequency option.

=head4 --newLine

Switches ON the --newLine option in count.pl. This will prevent bigrams from 
spanning across the lines.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 PROGRAM LOGIC

=over 

=item * STEP 1

 # create output dir
 if(!-e DESTINATION) then 
 mkdir DESTINATION;

=item * STEP 2

=over 4

=item 1. If SOURCE is a single plain file -

Split SOURCE into P smaller files (as specified by --split P). 
These files are created in the DESTINATION directory and their names are 
formatted as SOURCE1, SOURCE2, ... SOURCEP.

Run count.pl on each of the P smaller files. The count outputs are also 
created in DESTINATION and their names are formatted as SOURCE1.bigrams,
SOURCE2.bigrams, .... SOURCEP.bigrams.

=item 2. SOURCE is a single flat directory containing multiple plain files -

count.pl is run on each file present in the SOURCE directory. All files in
SOURCE are treated as the data files. If SOURCE contains sub-directories,
these are simply skipped. Intermediate bigram outputs are written in
DESTINATION.

=item 3. SOURCE is a list of multiple plain files -

If #arg > 2, all arguments specified after the first argument are considered
as the SOURCE file names. count.pl is separately run on each of the SOURCE 
files specified by argv[1], argv[2], ... argv[n] (skipping argv[0] which 
should be DESTINATION). Intermediate results are created in DESTINATION.

Files specified in the list of SOURCE should be relatively small sized 
plain files with #words < 1,000,000.

=back

In summary, a large datafile can be provided to huge-count in the form of 

a. A single plain file (along with --split P)

b. A directory containing several plain files

c. Multiple plain files directly specified as command line arguments

In all these cases, count.pl is separately run on SOURCE files or parts of
SOURCE file and intermediate results are written in DESTINATION dir.

=back

=head2 STEP 3

Intermediate count results created in STEP 2 are recombined in a pair-wise
fashion such that for P separate count output files, C1, C2, C3 ... , CP,

C1 and C2 are first recombined and result is written to huge-count.output

Counts from each of the C3, C4, ... CP are then combined (added) to 
huge-count.output and each time while recombining, always the smaller of the
two files is loaded.

=head2 STEP 4

After all files are recombined, the resultant huge-count.output is then sorted
in the descending order of the bigram counts. If --remove is specified, 
bigrams with counts less than the specified value of --remove, in the final 
huge-count.output file are removed from the sample and their counts are 
deleted from the marginal totals. If --frequency is selected, bigrams with
scores less than the specified value are simply skipped from output.

=head1 OUTPUT

After huge-count finishes successfully, DESTINATION will contain -

=over

=item * Intermediate bigram count files (*.bigrams) created for each of the 
given SOURCE files or split parts of the SOURCE file.

=item * Final bigram count file (huge-count.output) showing bigram counts in
the entire SOURCE.

=back

=head1 BUGS

huge-count.pl doesn't consider bigrams at file boundaries. In other words,
the result of count.pl and huge-count.pl on the same data file will
differ if --newLine is not used, in that, huge-count.pl runs count.pl
on multiple files separately and thus looses the track of the bigrams 
on file boundaries. With --window not specified, there will be loss 
of one bigram at each file boundary while its W bigrams with --window W. 

Functionality of huge-count is same as count only if --newLine is used and 
all files start and end on sentence boundaries. In other words, there 
should not be any sentence breaks at the start or end of any file given to
huge-count.

=head1 AUTHOR

Bjoern Wilmsmann, Ruhr-University, Bochum.

Amruta Purandare, Ted Pedersen.
University of Minnesota at Duluth.

=head1 COPYRIGHT

Copyright (c) 2006,

Bjoern Wilmsmann, Ruhr-University, Bochum.
bjoern@wilmsmann.de


Copyright (c) 2004,

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to

The Free Software Foundation, Inc.,
59 Temple Place - Suite 330,
Boston, MA  02111-1307, USA.

=cut

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use locale for localised tokenization
use locale;

# modules for file operations
use File::Copy;
use File::Path;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use support function library module
use Text::NSP::Environment::SupportFunctionLibrary;

# use modules providing main functionality
use Text::NSP::Combiner;
use Text::NSP::Counter;
use Text::NSP::DataSplitter;


## initialise some support classes and methods

# initialise option reader
my $optionReader = new Text::NSP::Environment::OptionReader();

# initialise support function library
my $supportFunctionLibrary = new Text::NSP::Environment::SupportFunctionLibrary();

# instantiate main application classes
my $combiner = new Text::NSP::Combiner();
my $counter = new Text::NSP::Counter();
my $dataSplitter = new Text::NSP::DataSplitter();

# define options reference
my $options;

# define global counter variables;
my $i;
my $j;

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
	my @defaults = ("--frequency", 0, "--remove", 0, "--ngram", 2, "--parser", "HTML");
	$options = $optionReader->getCommandLineArgs(\@defaults, \@ARGV);
}


## process options

# if help has been requested, show help, then exit
if (defined $options->{help}) {
	showHelp();
	exit(0);
}

# if version has been requested, show version, then exit
if (defined $options->{version}) {
	showVersion();
	exit(0);
}

# remove option
unless (defined $options->{remove}) {
	$options->{remove} = 0;
}

# cut off option
unless (defined $options->{frequency}) {
	$options->{frequency} = 0;
}

# window option
unless (defined $options->{window}) {
	$options->{window} = $options->{ngram};
	if (defined $options->{verbose}) {
		print "Using default window size = $options->{window}\n";
	}
}


## error handling

# handle illegal value for ngram option
if ($options->{ngram} <= 0) {
	print STDERR "Cannot process ngrams with value 'n' smaller than 1\n";
	showAskHelp();
	exit(1);
}

# handle illegal value for window option
if ($options->{window} < $options->{ngram}
	|| ($options->{ngram} == 1 && $options->{window} != 1 ))
{
	print STDERR "Illegal value for window size. Should be >= size of ngram (1 if size of ngram is 1).\n";
	showAskHelp();
	exit(1);
}

# handle illegal value for remove and frequency cut-off options
if ($options->{remove} != 0 && $options->{frequency} != 0) {
	print STDERR "--remove and --frequency options cannote be used together.\n";
	showAskHelp();
	exit(1);
}


## main program

# Check, if given destination is a directory. If it does not
# exist, create it.
if(-e $options->{destination}) {
	unless(-d $options->{destination}) {
		print STDERR "ERROR: $options->{destination} is not a directory.\n";
		exit(1);
	}
} else {
	mkdir($options->{destination});
}


## counting process

# initialise flag for 'directory changed' status
my $directoryChanged = 0;

# define file name string
my $file;

# Check, if source is a directory. If so, read it, otherwise
# try to read single file
if (-d $options->{source}) {
	opendir(DIR, $options->{source})
		|| die"ERROR: Error in opening source directory <$options->{source}>.\n";
	
	# iterate over files in directory
	my $file;
	while(defined($file = readdir(DIR))) {
		# if file name merely consists of dots, skip file
		if ($file =~ /^\.\.?$/) {
			next;
		}
		
		# if object is a file, run counting process on that file
		if(-f "$options->{source}/$file") {
			$supportFunctionLibrary->runMultipleCount("$options->{source}/$file", $options);
		}
	}
} elsif (-f $options->{source}) {
	# if split option is given
	if(defined $options->{split}) {
		# copy source file to destination directory
		copy($options->{source}, $options->{destination});
		
		# copy token file to destination directory
		if(defined $options->{token}) {
			copy($options->{token}, $options->{destination});
		}
		
		# copy non-token file to destination directory
		if(defined $options->{nontoken}) {
			copy($options->{nontoken}, $options->{destination});
		}

		# copy stopword file to destination directory
		if(defined $options->{stop}) {
			copy($options->{stop}, $options->{destination});
		}
		
		# change to destination directory
		chdir($options->{destination});
		$directoryChanged = 1;

		# start data splitter
		$dataSplitter->start(["--parts", $options->{split}, "--data", $options->{source}]);

		# open destination directory
		opendir(DIR, ".")
			|| die("ERROR: Error in opening destination directory <$options->{destination}>.\n");
			
	    # remove path and file name suffix
   		my $justFile = $options->{source};
	    $justFile =~ s/.*\/(.+)/$1/;

		# iterate over destination directory
		while(defined ($file = readdir(DIR))) {
			# if file is source file
			if($file =~ /$justFile\d+/ && $file !~ /\.ngrams/) {
				$supportFunctionLibrary->runMultipleCount($file, $options);
			}
		}
		
		# close directory
		close(DIR);
	} else {
		# print warning and exit, if split option not given
		print STDERR "Warning: You can run count.pl directly on the single source file\n";
		print STDERR "if don't want to split the source.\n";
		exit(0);
	}
} elsif ($options->{source} =~ /,/) {
	# split source files
	my @sourceFiles = split(/,\s*?/, $options->{source});

	# iterate over source files
	foreach my $sourceFile (@sourceFiles) {
		# check if given source actually is a file
		if(-f $sourceFile) {
			# run count on this file
			$supportFunctionLibrary->runMultipleCount($sourceFile, $options);
		} else {
			# print error otherwise
			print STDERR "ERROR: $sourceFile should be a plain file.\n";
			exit(1);
		}
	}
} else {
	# show minimal usage notes, if insufficient arguments have been supplied
	showMinimalUsageNotes();
	exit(1);
}


## recombining counts

# if directory has not been changed yet do so now
if($directoryChanged != 1) {
	chdir($options->{destination});
}

# open destination directory
opendir(DIR, ".")
	|| die("ERROR: Error in opening destination directory <$options->{destination}>.\n");

# initialise output file name
my $output = "huge-count.output";

# remove existing output files from previous processing
if(-e $output) {
	rmtree($output);
}

# iterate over files in destination directory
my @processQueue;
while(defined ($file = readdir(DIR))) {
	# if file is n-gram model
	if($file =~ /\.ngrams$/) {
		# push file to queue
		push(@processQueue, $file);
	}
}

# close destination directory
close(DIR);

# combine file in process queue
$combiner->start(["--remove", $options->{remove}, "--frequency", $options->{frequency}, "--destination", $output, "--count", @processQueue, "--ngram", $options->{ngram}]);


## message

# print message
print STDOUT "Please check the output in $options->{destination}/$output.\n";


## local functions

# function for printing a minimal usage note when the user has not provided any
# command line options
sub showMinimalUsageNotes {
        print "Usage: huge-count.pl [OPTIONS] --destination DESTINATION --source [SOURCE]+\n";
        showAskHelp();
}

# function for printing help messages for this program
sub showHelp {
	print "Usage:  huge-count.pl [OPTIONS] --destination DESTINATION --source [SOURCE]+\n\n";

	print "Efficiently runs count.pl on a huge data.\n\n";

	print "SOURCE\n";
	print "		Could be a -\n\n";

	print "					1. single plain file\n";
	print "					2. single flat directory containing multiple plain files\n";
	print "					3. list of plain files separate by ','\n\n";

	print "DESTINATION\n";
	print "		Should be a directory where output is written.\nv";
			
	print "OPTIONS:\n\n";

	print "		--split P\n";
	print "			If SOURCE is a single plain file, --split has to be specified to\n";
	print "			split the source file into P parts and to run count.pl separately\n";
	print "			on each part.\n\n";

	print "		--token TOKENFILE\n";
	print "			Specify a file containing Perl regular expressions that define the\n";
	print "			tokenization scheme for counting.\n\n";

	print "		--nontoken NOTOKENFILE\n";
	print "			Specify a file containing Perl regular expressions of non-token\n";
	print "			sequences that are removed prior to tokenization.\n";

	print "		--stop STOPFILE\n";
	print "			Specify a file containing Perl regular expressions of stop words\n";
	print "			that are to be removed from the output bigrams.\n\n";

	print "  	--ngram N\n";
	print "			Creates n-grams of N tokens each. N = 2 by default.\n\n";

	print "		--window W\n";
	print "			Specify the window size for counting.\n\n";

	print "		--remove L\n";
	print "			Bigrams with counts less than L will be removed from the sample.\n\n";

	print "		--frequency F\n;";
	print "			Bigrams with counts less than F will not be displayed.\n\n";

	print "		--newLine\n";
	print "			Prevents bigrams from spanning across the new-line characters.\n\n";

	print "		--help\n";
	print "			Displays this message.\n\n";

	print "		--url\n";
	print "			Supply input text via URL.\n\n";

	print "		--urlfile\n";
	print "			Supply input URLs via text file with\n";
	print "         one line for each URL.\n\n";

	print " 	--parser\n";
	print "			Defines which parser to use for URLs, default\n";
	print "         is HTML, other option is XML.\n\n";

	print "		--version\n";
	print "	        Displays the version information.\n\n";
	
	print "		--debug\n";
	print "			Use debug mode.\n\n";

	print "			Type 'perldoc huge-count.pl' to view detailed documentation of huge-count.\n";
}

# function for printing the version number
sub showVersion {
	print "huge-count.pl      -       Version 0.04\n";
	print "Copyright (C) 2006, Bjoern Wilmsmann\n";
    print "Copyright (C) 2004, Amruta Purandare & Ted Pedersen.\n";
	print "Date of Last Update 10/12/06\n";
}

# function for printing an 'ask for help' message
sub showAskHelp {
	print STDERR "Type huge-count.pl --help for help.\n";
}


