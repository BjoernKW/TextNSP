=head1 NAME

Text::NSP::Counter - 	A package implementing the n-gram counting functionality

=head1 AUTHORS

Satanjeev Banerjee, bane0025@d.umn.edu
Ted Pedersen, tpederse@d.umn.edu
Bjoern Wilmsmann, bjoern@wilmsmann.de

=head1 COPYRIGHT

Copyright (C) 2006, Bjoern Wilmsmann
Copyright (C) 2000-2003, Ted Pedersen and Satanjeev Banerjee

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

package Text::NSP::Counter;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use locale for localised tokenization
use locale;

# DEBUG: use stop watch module for measuring time
use Text::NSP::Time::StopWatch;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use support function library module
use Text::NSP::Environment::SupportFunctionLibrary;

# use tokenizer module
use Text::NSP::Environment::Tokenizer;

# use optional LWP module
eval {
	require LWP::UserAgent;
};

our ($VERSION);

$VERSION = '0.5.8';

# constructor
sub new {
	my ($class) = @_;
	my $self = {};
	bless($self, $class);
	return $self;
}

# function that starts the whole n-gram counting process
sub start {
	my ($self, $argv) = @_;
	
	## initialise some support classes and methods

	# DEBUG: initialise first stop watch
	my $stopWatch = new Text::NSP::Time::StopWatch();

	# DEBUG: initialise second stop watch
	my $stopWatch2 = new Text::NSP::Time::StopWatch();

	# DEBUG: initialise third stop watch
	my $stopWatch3 = new Text::NSP::Time::StopWatch();

	# initialise option reader
	my $optionReader = new Text::NSP::Environment::OptionReader();

	# initialise support function library
	my $supportFunctionLibrary = new Text::NSP::Environment::SupportFunctionLibrary();

	# define options reference
	my $options;

	# define global counter variables;
	my $i;
	my $j;

	# define variable for interactive user input
	my $reply;


	## start

	# DEBUG: start watch
	$stopWatch->startTime();

	# check if no command line options have been supplied
	unless (@{$argv} > 0) {
		# show usage notes and exit
		showMinimalUsageNotes();
		exit(1);
	} else {
		# get options
		my @defaults = ("--frequency", 0, "--remove", 0, "--ngram", 2, "--parser", "HTML", "--algorithm", 1);
		$options = $optionReader->getCommandLineArgs(\@defaults, $argv);
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


	## frequency combinations

	# define reference for frequency combinations
	my $frequencyCombinations;

	# get frequency combinations from file or use defaults
	if (defined $options->{set_freq_combo}) {
		$frequencyCombinations =
			$supportFunctionLibrary->getFrequencyCombinations(
		  		$options->{ngram},
				$options->{set_freq_combo}
		 	);
	} else {
		$frequencyCombinations =
			$supportFunctionLibrary->getFrequencyCombinations(
				$options->{ngram}
		  	);
	}

	# write frequency combinations to file if option has been set
	if (defined $options->{get_freq_combo}) {
		$supportFunctionLibrary->writeFrequencyCombinations(
			$frequencyCombinations,
		  	$options->{get_freq_combo}
		);
	}


	## building regular expressions for tokenizer

	# initialise regular expression string for matching tokens
	my $tokenizerRegex = "";

	# define array for single regular expression tokens
	my @regexTokens;

	# check if token file has been supplied. if so, try to open it and extract
	# the regular expressions, otherwise only use default expressions
	if (defined $options->{token}) {
		@regexTokens =
			@{$supportFunctionLibrary->getRegularExpressionTokens($options->{token})};
	} else {
		@regexTokens =
			@{$supportFunctionLibrary->getRegularExpressionTokens()};
	}

	# create the complete regular expression for token matching
	foreach my $token (@regexTokens) {
		if (length($tokenizerRegex) > 0) {
			$tokenizerRegex .= "|";
		}
		$tokenizerRegex .= "(" . $token . ")";
	}

	# if we don't have any tokens to work with, quit and show 'ask for help' message
	unless (@regexTokens > 0) {
		print STDERR "No token definitions to work with.\n";
		showAskHelp();
		exit(1);
	}


	## building 'non-token' regular expressions

	# initialise regular expression string for matching non-tokens
	my $nonTokenRegex = "";

	# define array for single regular expression tokens
	my @regexNonTokens;

	# check if non-token file has been supplied. if so, try to open it and extract
	# the regular expressions
	# non-tokens are user-defined regular expressions specifying which characters or
	# character sequences to omit
	if (defined $options->{nontoken}) {
		@regexNonTokens =
			@{$supportFunctionLibrary->getRegularExpressionTokens($options->{nontoken})};
	}

	# create the complete regular expression for token matching
	foreach my $nonToken (@regexNonTokens) {
		if (length($nonTokenRegex) > 0) {
			$nonTokenRegex .= "|";
		}
		$nonTokenRegex .= "(" . $nonToken . ")";
	}


	## building stop word regular expressions

	# initialise regular expression string for matching stop words
	my $stopWordRegex = "";

	# define array for single regular expression tokens
	my @regexStopWords;

	# check if stop word file has been supplied. if so, try to open it and extract
	# the regular expressions
	# stop words are user-defined regular expressions specifying which tokens to omit
	if (defined $options->{stop}) {
		@regexStopWords =
			@{$supportFunctionLibrary->getRegularExpressionTokens($options->{stop})};
	}

	# create the complete regular expression for token matching
	foreach my $stopWord (@regexStopWords) {
		if (length($stopWordRegex) > 0) {
			$stopWordRegex .= "|";
		}
		$stopWordRegex .= "(" . $stopWord . ")";
	}


	## XML/HTML parser

	# define some boolean variables
	my $lwpExists          = 0;
	my $htmlParserExists   = 0;
	my $xmlParserExists    = 0;
	my $htmlEntitiesExists = 0;

	# define array for URL source files;
	my @urlSourceFiles;

	# if one of the URL options is set
	if (defined $options->{url} || defined $options->{urlfile}) {

		# Check, if LWP module exists. If not, do not use parser
		eval {
			require LWP::UserAgent;
		};
		unless ($@ eq "") {
			# reset options
			$options->{url}     = "";
			$options->{urlfile} = "";
			$options->{parser}  = "";

			# print error message
			print STDERR "Module LWP::UserAgent does not exist. Cannot use parser.\n";
		} else {
			$lwpExists = 1;
		}

		# if default value, use optional HTML::Parser module
		if ($lwpExists && $options->{parser} eq "HTML") {

		  	# Check, if HTML::Parser module exists. If not, do not use HTML parser
			eval {
				require HTML::Parser;
			};
			unless ($@ eq "") {
				# reset options
				$options->{url}     = "";
				$options->{urlfile} = "";
				$options->{parser}  = "";

				# print error message
				print STDERR "Module HTML::Parser does not exist. Cannot use parser.\n";
			} else {
				$htmlParserExists = 1;
			}
		}

		# if "XML" value, use optional XML::Parser module
		if ($lwpExists && $options->{parser} eq "XML") {

			# Check, if XML::Parser module exists. If not, do not use XML parser
			eval {
				require XML::Parser;
			};
			unless ($@ eq "" ) {
				# reset options
				$options->{url}     = "";
				$options->{urlDile} = "";
				$options->{parser}  = "";

				# print error message
				print STDERR
				  "Module XML::Parser does not exist. Cannot use parser.\n";
			} else {
				$xmlParserExists = 1;
			}
		}

		# check, if HTML::Entities module exists
		eval {
			require HTML::Entities;
		};
		if ($@ eq "") {
			$htmlEntitiesExists = 1;
		}

		# if required modules are available
		if ($lwpExists && ($htmlParserExists || $xmlParserExists)) {
			# define URL array
			my @urls;

			# create HTML/XML parser
			my $parser;
			my @urlContent;
			my @urlTags;

			# if HTML parser
			if ($htmlParserExists) {
				# initialise HTML parser
				$parser = HTML::Parser->new(
					api_version => 3,
					handlers    => {
						start => [\@urlTags,    "tagname"],
						text  => [\@urlContent, "text"]
					}
				);
			}

			# if XML parser
			if ($xmlParserExists) {

				# use XML parser wrapper
				use Text::NSP::Environment::XMLParser;

				# initialise XML parser
				$parser = new Text::NSP::Environment::XMLParser(\@urlTags, \@urlContent);
			}

			# check, if URL option has been set
			if (defined $options->{url}) {

				# push URL given via 'url' option to array
				push(@urls, $options->{url});
			}

			# check, if 'urlfile' option has been set
			if (defined $options->{urlfile}) {

				# open file containing URLs
				open(URLFILE, $options->{urlfile})
				  || die("Can't open URL file: $options->{urlfile}");

				# push each URL to array
				while (<URLFILE>) {
					chomp($_);
					push(@urls, $_);
				}

				# close URL file
				close(URLFILE);
			}

			# create temporary directory for URL files
			mkdir("tempTextNSP/", 0755);

			# create user agent
			my $userAgent = LWP::UserAgent->new();
			$userAgent->agent(
				"'Mozilla/5.0 (compatible; Text-NSP/www.textnsp.org)'"
			);

			# define some variables
			my $urlCounter = 0;
			my $tempFile;

			# turn on 'bytes' behaviour for printing content to file (avoids 'wide character' error)
			use bytes;

			# iterate over URLs
			foreach my $url (@urls) {

				# open file for storing response
				$tempFile = "tempTextNSP/" . $urlCounter . ".txt";
				open(RESPONSE, ">$tempFile")
				  	|| die("Can't open URL output file: ./tempTextNSP/" . $urlCounter . ".txt");

				# request
				my $request = HTTP::Request->new(GET => $url);

				# pass request to the user agent
				my $response = $userAgent->request($request);

				# check the response
				if ($response->is_success) {

					# if HTML::Entities is available
					if ($htmlEntitiesExists) {

						# parse using HTML entity decoder
						$parser->parse(
							HTML::Entities::decode_entities(
								$response->content
							)
						);
					} else {
						# parse without decoding HTML entities
						$parser->parse($response->content);
					}

					# define some variables for parsing
					my $parseIndex = 0;
					my $currentTag;

					# if HTML parser
					if ($htmlParserExists) {

						# iterate over content chunks
						foreach my $contentChunk (@urlContent) {

							# if tag for this content is defined
							if (defined $urlTags[$parseIndex]->[0]) {
								$currentTag = $urlTags[$parseIndex]->[0];
							}

							# if content chunk is not empty and corresponding tags are no '<script>' or '<style>' ones
							unless ($contentChunk->[0] =~ /^\s+$/
									|| $currentTag eq "script"
									|| $currentTag eq "style")
							{
								# print to temporary file
								print RESPONSE "$contentChunk->[0]\n";
							}

							# increment parse index (i.e. the position of the current content chunk)
							$parseIndex++;
						}
					}

					# if XML parser
					if ($xmlParserExists) {
						# iterate over content chunks
						foreach my $contentChunk (@urlContent) {
							# if tag for this content is defined
							if (defined $urlTags[$parseIndex]) {
								$currentTag = $urlTags[$parseIndex];
							}

							# if content chunk is not empty and corresponding tags are no '<script>' or '<style>' ones
							unless ($contentChunk =~ /^\s+$/
									|| $currentTag eq "script"
									|| $currentTag eq "style")
							{
								# print to temporary file
								print RESPONSE "$contentChunk\n";
							} else {
								# if content chunk is not empty and corresponding tags are no '<script>' or '<style>' ones
								unless ($contentChunk =~ /^\s+$/) {
									# print to temporary file
									print RESPONSE "$contentChunk\n";
								}
							}

							# increment parse index (i.e. the position of the current content chunk)
							$parseIndex++;
						}
					}

					# push file to source file array
					push(@urlSourceFiles, $tempFile);
				} else {
					# print error message
					print "Error retrieving $url: " . $response->status_line . "\n";
				}

				# close response file
				close(RESPONSE);
			}

			# turn off 'bytes' behaviour for printing
			no bytes;
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


	## source file(s)

	# get source files
	my @sourceFiles;
	if (defined $options->{source}) {
		@sourceFiles =
			@{$supportFunctionLibrary->getSourceFiles($options->{source}, $options)};
	}

	# push URL source files to general source file array
	push(@sourceFiles, @urlSourceFiles);

	# quit if source file array is empty
	if (@sourceFiles < 1) {
		die("No sources have been specified, quitting.\n");
	}

	# unless a file is found, complain and quit!
	unless (@sourceFiles > 0) {
		print STDERR "No input file (SOURCE) supplied!\n";
		showAskHelp();
		exit(1);
	}


	## preliminaries done, main program starts here!

	# if 'verbose' option is set, be verbose and print all source files!
	if (defined $options->{verbose}) {
		print "\nThe following " . scalar(@sourceFiles) . " file(s) to read from were found: \n";
		foreach my $file (@sourceFiles) {
			print "$file\n";
		}
		print "\n";
	}

 	# get all the combinations for this ngram / window size combination. This tells
 	# us which words to pick from a window to form the various ngrams.
	my @tokenCombinations;
	@tokenCombinations =
		@{$supportFunctionLibrary->getTokenCombinations($options->{window} - 1, $options->{ngram} - 1)};


	## tokenization

	# define ngram hash
	my %ngrams;

	# define frequency hash
	my %frequencies;

  	# initialise $ngramTotal, which will contain the total number of ngrams found!
	my $ngramTotal = 0;
	
	# define data structures for alternative counting algorithm
	my %windowHash;
	my @tokenArray;

	# initialise tokenizer
	my $tokenizer = new Text::NSP::Environment::Tokenizer(
						\%ngrams,
						$ngramTotal,
						\%frequencies,
						$frequencyCombinations,
						$options->{ngram},
						$options->{window},
						\@tokenCombinations
					);

	# define token window
	my @tokenWindow;

	# DEBUG: define time variable
	my $time3;
	my $time4;

	# DEBUG: start watch
	$stopWatch3->startTime();

	# now get the source files one by one from @sourceFiles, and process them in
	# a loop!
	my $source;
	foreach $source (@sourceFiles) {
		# open source file
		open(SRC, $source) || die("Can't open SOURCE file: $source");

		# if option 'verbose' is set, be verbose
		if (defined $options->{verbose}) {
			print "Accessing file: $source .\n";
		}

		# read in the file, tokenize and process each token
		while (<SRC>) {
			# if we don''t want n-grams to span across the new line, then every
			# time we process a new line, we need to reset the window array
			if (defined $options->{newline}) {
				@tokenWindow = ();
			}

		 	# Removing sequences of characters which are declared as non-tokens.
		 	# These are detected and removed before checking for tokens because
		 	# those sequences which include valid tokens in them should be removed
		 	# since the whole sequence is declared as a non-token
			if (defined $nonTokenRegex) {
				s/$nonTokenRegex//g;
			}

			# Removing stop words before processing line
			if (defined $stopWordRegex) {
				s/$stopWordRegex//g;
			}

			# tokenize the line
			while (/$tokenizerRegex/g) {
				# process tokens at this point, if algorithm == 1
				if ($options->{algorithm} == 1) {
					# DEBUG: start watch
					$stopWatch2->startTime();
	
					# process token
					$tokenizer->processTokens($&);
	
					# DEBUG: stop watch
					$stopWatch2->stopTime();
	
					# DEBUG: get time
					$time3 += $stopWatch2->getTime();
				} else {
					# add token to window
					push(@tokenWindow, $&);

					# if window is large enough
					if (@tokenWindow >= $options->{window}) {
						# update string representing current window in
						# hash of windows
						$windowHash{"@tokenWindow"}++;

						# shift from token window
						shift(@tokenWindow);
					}
				}
			}
		}

		# close source file
		close(SRC);
	}
	
	# process tokens at this point, if algorithm == 2
	if ($options->{algorithm} == 2) {
		foreach my $tokenWindow (keys(%windowHash)) {
			# DEBUG: start watch
			$stopWatch2->startTime();

			# process tokens in current window
			@tokenArray = split(/ /, $tokenWindow);
			$tokenizer->processTokens2(\@tokenArray, $windowHash{$tokenWindow});

			# DEBUG: stop watch
			$stopWatch2->stopTime();
	
			# DEBUG: get time
			$time3 += $stopWatch2->getTime();
		}
	}

	# if remove n-grams option has been set,
	# remove n-grams below given frequency
	if ($options->{remove} != 0) {
	    foreach my $ngram (keys(%ngrams)) {
    		if ($ngrams{$ngram} < $options->{remove}) {
    			$tokenizer->removeNgram($ngram);
    		}
    	}
	}

	# DEBUG: stop watch
	$stopWatch3->stopTime();

	# DEBUG: get time
	$time4 += $stopWatch3->getTime();

	# if one of the URL options is set, delete temporary directory
	if (defined $options->{url} || defined $options->{urlfile}) {

		# use File::Path for recursively deleting temporary directory
		use File::Path;

		# delete temporary directory
		File::Path::rmtree("tempTextNSP/", 1, 1);
	}


	## output

	# DEBUG: stop watch
	$stopWatch->stopTime();

	# DEBUG: get time
	my $time1 = $stopWatch->getTime();

	# DEBUG: start watch
	$stopWatch->startTime();

	# if verbose, tell user what we are doing right now
	if (defined($options->{verbose})) {
		print "Writing to $options->{destination} .\n";
	}

	# try to open destination file
	open(DST, ">$options->{destination}")
		|| die("Couldn't open output file: $options->{destination}");

	# if extended reporting was requested
	if (defined($options->{extended})) {

		# print out the n-gram size
		print DST "\@count.Ngram=$options->{ngram}\n";

		# print out the window size used
		print DST "\@count.WindowSize=$options->{window}\n";

		# print out the frequency cut off used
		print DST "\@count.FrequencyCut=$options->{frequency}\n";

		# print out the remove cut off used
		print DST "\@count.RemoveCut=$options->{remove}\n";

		# print out the path/file name of the input files
		print DST "\@count.InputFilePath=";
		foreach $source (@sourceFiles) {
			print DST "$source ";
		}
		print DST "\n";
	}

	# finally print out the total ngrams
	print DST "$tokenizer->{ngramTotal}\n";

	# close destination file
	close(DST);

	# print the sorted n-gram frequencies
	$tokenizer->printTokens($options);

	# create histogram if requested
	if (defined($options->{histogram})) {
		$tokenizer->createHistogram($options);
	}

	# DEBUG: stop watch
	$stopWatch->stopTime();

	# DEBUG: get time
	my $time2 = $stopWatch->getTime();

	# if debugging is enabled
	if (defined $options->{debug}) {
		# DEBUG: display time
		print "Time: " . $time1 . ";" . $time2 . "\n";
		print "Sum: " . ( $time1 + $time2 ) . "\n";
		print "Time While: " . $time3 . "\n";
		print "Time Foreach: " . $time4 . "\n";
	}
}


## help displayer functions

# function for printing a minimal usage note when the user has not provided any
# command line options
sub showMinimalUsageNotes {
	print STDERR "Usage: count.pl [OPTIONS] --destination DESTINATION --source SOURCE\n";
	showAskHelp();
}

# function for printing help messages for this program
sub showHelp {
	print "Usage: count.pl [OPTIONS] --destination DESTINATION --source SOURCE\n\n";

	print "Counts up the frequency of all n-grams occurring in SOURCE.\n";
	print "Sends to DESTINATION the list of n-grams found, along with the\n";
	print "frequencies of combinations of the n tokens that the n-gram is\n";
	print "composed of. If SOURCE is a directory, all text files in it are\n";
	print "counted.\n\n";

	print "OPTIONS:\n\n";

	print "  --ngram N          Creates n-grams of N tokens each. N = 2 by\n";
	print "                     default.\n\n";

	print "  --window N         Sets window size to N. Defaults to n-gram\n";
	print "                     size above.\n\n";

	print "  --token FILE       Uses regular expressions in FILE to create\n";
	print "                     tokens. By default two regular expressions\n";
	print "                     are provided (see README).\n\n";

	print "  --nontoken FILE    Removes all characters sequences that match\n";
	print "                     Perl regular expressions specified in FILE.\n\n";

	print "  --set_freq_combo FILE \n";
	print "                     Uses the frequency combinations in FILE to\n";
	print "                     decide which combinations of tokens to\n";
	print "                     count in a given n-gram. By default, all\n";
	print "                     combinations are counted.\n\n";

	print "  --get_freq_combo FILE \n";
	print "                     Prints out the frequency combinations used\n";
	print "                     to FILE. If frequency combinations have been\n";
	print "                     provided through --set_freq_combo switch above\n";
	print "                     these are output; otherwise the default\n";
	print "                     combinations being used are output.\n\n";

	print "  --stop FILE        Removes n-grams containing at least one (in\n";
	print "                     OR mode) or all stop words (in AND mode).\n";
	print "                     Stop words should be declared as Perl Regular\n";
	print "                     expressions in FILE.\n\n";

	print "  --frequency N      Does not display n-grams that occur less\n";
	print "                     than N times.\n\n";

	print "  --remove N         Ignores n-grams that occur less than N\n";
	print "                     times. Ignored n-grams are not counted and\n";
	print "                     so do not affect counts and frequencies.\n\n";

	print "  --newline          Prevents n-grams from spanning across the\n";
	print "                     new-line character.\n\n";

	print "  --histogram FILE   Outputs histogram to FILE. Tabulates how\n";
	print "                     many times n-grams of a given frequency\n";
	print "                     have occurred.\n\n";

	print "  --recurse          If SOURCE is a directory, uses all files\n";
	print "                     in SOURCE as well as all subdirectories of\n";
	print "                     SOURCE recursively as input.\n\n";

	print "  --extended         Outputs values of the above switches, if\n";
	print "                     default values are not used.\n\n";

	print "  --url              Supply input text via URL.\n\n";

	print "  --urlfile          Supply input URLs via text file with\n";
	print "                     one line for each URL.\n\n";

	print "  --parser           Defines which parser to use for URLs, default\n";
	print "                     is HTML, other option is XML.\n\n";
	
	print "  --algorithm (1|2)	Switch between two algorithms for n-gram counting.\n";
	print "						1 is better for smaller N (<= 3), while 2 should perform\n";
	print "						better for larger N. However, 2 is still experimental.\n";
	print "						Defaults to 1\n\n";

	print "  --verbose          Prints information about\n";
	print "                     current program status to STDERR.\n\n";

	print "  --version          Prints the version number.\n\n";

	print "  --help             Prints this help message.\n\n";

	print "  --debug			Use debug mode.\n\n";
}

# function for printing the version number
sub showVersion {
	print "count.pl      -        version 0.58\n";
	print "Copyright (C) 2006, Bjoern Wilmsmann\n";
	print "Copyright (C) 2000-2003, Ted Pedersen & Satanjeev Banerjee\n";
	print "Date of Last Update 13/11/06\n";
}

# function for printing an 'ask for help' message
sub showAskHelp {
	print STDERR "Type count.pl --help for help.\n";
}

1;

__END__

