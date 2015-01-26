=head1 NAME

Text::NSP::Environment::SupportFunctionLibrary - 	A collection of support functions for
													use in Text-NSP

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Environment::SupportFunctionLibrary

=head1 DESCRIPTION

=head1 AUTHORS

Bjoern Wilmsmann, bjoern@wilmsmann.de

=head1 COPYRIGHT

Copyright (C) 2006,
Bjoern Wilmsmann, Ruhr-University, Bochum.
bjoern@wilmsmann.de


Copyright (c) 2000-2004,

Satanjeev Banerjee
Satanjeev Banerjee, bane0025@d.umn.edu

Ted Pedersen, University of Minnesota, Duluth.
tpederse@umn.edu

Amruta Purandare, University of Minnesota, Duluth.
pura0010@umn.edu

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

=head2 Error Codes

=head2 Methods

=over

=cut


package Text::NSP::Environment::SupportFunctionLibrary;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

our($VERSION);

$VERSION = '0.0.1';

# constructor
sub new {
	my ($class, $ngrams) = @_;
	my $self = {
	};
	bless($self, $class);
	return $self;
}


## functions regarding frequency combinations

# function for getting frequency combinations
sub getFrequencyCombinations {
	my ($self, $ngram, $file, $cache) = @_;
	my $frequencyCombinations;
	my $i;
	my $j;
	my $k;
	my @stack;
	my $todo;
	my $stackPosition;
	my $position;

	# if no file with frequency combinations has been specified, construct the array,
	# otherwise read it from file
	unless (defined $file) {
		# combinations containing only respective single words
		for $i (0 .. $ngram - 1) {
			$frequencyCombinations->[0]->[$i] = $i;
		}
		$position = 1;

		# all other permitted ngram combinations
		for $i (1 .. $ngram - 1) {
			# get binomial coefficient in order to determine number of combinations to add to
			# frequency combinations array
			$todo = $self->binomialCoefficient($ngram, $i, $cache);

			# build initial stack
			@stack = ();
			for $j (0 .. $i - 1) {
				push(@stack, $j);
			}
			$stackPosition = @stack - 1;

			# process stack
			for $j (0 .. $todo - 1) {
				for $k (0 .. @stack - 1) {
					$frequencyCombinations->[$position]->[$k] = $stack[$k];
				}
				$stack[$stackPosition]++;
				
				# loop is interrupted, if stack position is > 0 and value > largest ngram
				while (1 == 1) {
					if ($stack[$stackPosition] > $ngram - 1 && $stackPosition > 0) {
						$stack[$stackPosition] = $ngram - 1;
						$stackPosition--;
						$stack[$stackPosition]++;
					} else {
						last;
					}
				}
				$position++;
			}
		}
	} else {
		# define array for buffering combinations
		my @combinations;
		
		# define variable for buffering single combination
		my $singleCombination;

		# initialise counter variable
		$i = 0;
		
		# open file for getting frequency combinations
    	open(FREQ_COMBO_IN, "$file") || die ("Couldnt open file for frequency combination input: $file");    

		# get frequency combinations
		while (<FREQ_COMBO_IN>) {
			$j = 0;
			chomp();
			@combinations = split(/ /);
			for $singleCombination (0 .. @combinations - 1) {
				$frequencyCombinations->[$i]->[$j] = $combinations[$singleCombination];
				$j++;
			}
			$i++;
		}

		# close file
    	close(FREQ_COMBO_IN);
	}

	# return frequency combinations
	return $frequencyCombinations;
}

# function for writing frequency combinations to file
sub writeFrequencyCombinations {
	my ($self, $frequencyCombinations, $file) = @_;
	my $i;
	my $j;

	# open file for writing frequency combinations
    open(FREQ_COMBO_OUT, ">$file") || die ("Couldnt open file for frequency combination output: $file");    

	# write frequency combinations
    for ($i = 0; $i < @{$frequencyCombinations}; $i++) {
		for ($j = 0; $j < @{$frequencyCombinations->[$i]}; $j++) {
	    	print FREQ_COMBO_OUT "$frequencyCombinations->[$i]->[$j] ";
		}
		print FREQ_COMBO_OUT "\n";
    }

	# close file
    close(FREQ_COMBO_OUT);
}

# function for calculating the binomial coefficient
sub binomialCoefficient {
	my ($self, $n, $k, $cache) = @_;

	# if k is 0 or equals n, binomial coefficient is invariably 1
	return 1 if ($k == 0 || $k == $n);

	# if value has already been processed, just return the cache value
	# and do not calculate again
	if (defined($cache) && defined($cache->{$n}) && defined($cache->{$n}->{$k})) {
		return $cache->{$n}->{$k};
	}

	# calculate
	my $binomialCoefficient = $self->binomialCoefficient($n - 1, $k, $cache) + $self->binomialCoefficient($n - 1, $k - 1, $cache);
	$cache->{$n}->{$k} = $binomialCoefficient;
	
	# return coefficient
	return $binomialCoefficient;
}

# function for getting token combinations
# algorithm based on Combination Generator by Michael Gilleland, Merriam Park Software,
# see http://www.merriampark.com/comb.htm for further information
sub getTokenCombinations {
	my ($self, $window, $ngram, $cache) = @_;
	my @tokenCombinations;
	my $i;
	my $j;
	my $todo;
	my $counter;
	my $stackPosition;

   	# get binomial coefficient in order to determine number of steps to do
	# $todo = $self->binomialCoefficient($window - 1, $ngram - 1, $cache);
	$todo = $self->binomialCoefficient($window, $ngram, $cache);

	# build initial stack
	my @stack = ();
	for $i (0 .. $ngram - 1) {
		push(@stack, $i);
	}

	# initialise counter
	$counter = 1;
	
	# push first stack to token combinations
	push(@tokenCombinations, @stack);

	# first step done, therefore increment counter
	$counter++;
	
	# process counter + 1 stacks
    while ($counter <= $todo) {
    	# set index i = ngram - 1, as arrays begin with 0 index
   	    $i = $ngram - 1;

		# while current stack value equals window size - ngram size + current index i, decrement index i
		# e.g.: window = 5, ngram = 3, current stack = 1 3 4, i = 1
		# => value at stack position = window - ngram + i
	    while ($stack[$i] == $window - $ngram + $i) {
    		$i--;
    	}
    	
    	# increment value at current stack position
    	$stack[$i]++;
    	
    	# re-initialise values of following stack positions ($j) according to incremented value
    	# set to value at current position ($i) + delta($i, $j)
    	for $j ($i + 1 .. $ngram - 1) {;
    		$stack[$j] = $stack[$i] + $j - $i;
    	}
    	
    	# push stack to token combinations
		push(@tokenCombinations, @stack);
		
		# increment counter
		$counter++;
    }

	# return token combinations
	return \@tokenCombinations;
}


## token regular expression functions

# function for getting regular expression tokens
sub getRegularExpressionTokens {
	my ($self, $file) = @_;
	my @regexTokens;
	
	# if file has been supplied, process it, otherwise only use default expressions
	if (defined $file) {
		# open token file
		open(TOKEN, $file) || die("Couldnt open token file: $file\n");   

		# go through each line of token file
    	while(<TOKEN>) {
    		# pre-processing
        	chomp();
        	s/^\s*//;
        	s/\s*$//;
        	if (length($_) <= 0) {
        		next;
        	}
        	
        	# only process regular expressions when placed between proper delimiters
        	if (!(/^\//) || !(/\/$/)) {
            	print STDERR "Ignoring regular expression with no delimiters: $_\n";
            	next;
        	}

			# remove delimiters
        	s/^\///;
        	s/\/$//;

			# push to token array
        	push(@regexTokens, $_);
    	}

		# close token file
    	close(TOKEN);
	} else {
		# push defaults to token array
    	push(@regexTokens, "\\w+");
    	push(@regexTokens, "[\.,;:\?!]");
	}
	
	# return tokens
	return \@regexTokens;
}


## source file functions

# function for getting all source files, cases:
# 1> if the string is a text file and can be opened, add it to the array.
# 2> if the string is a directory name, find all text files in that directory,
#    and append to array.
# 3> if the -r (recursive) option is set, go into all subdirectories of that
#    directory too, to do the above!
sub getSourceFiles {
    my ($self, $fileStrings, $options) = @_;
    my @sourceFiles;
    my @fileStrings;
    my $directoryContents;

	# check, if $fileStrings is an array reference, if so convert it to array,
	# otherwise add it to an array with size 1
	if (ref($fileStrings) eq "ARRAY") {
	    @fileStrings = @{$fileStrings};
	} else {
		@fileStrings = ($fileStrings);
	}

    # go through each supplied source file
    foreach my $nextString (@fileStrings) {
    	# if file does not exist
        unless (-e $nextString) {
        	# if 'verbose' option is set, be verbose!
            if (defined $options->{verbose}) {
            	print "File $nextString doesn't exist!\n";
            }
            next;
        }

		# if file is not readable
    	unless (-r $nextString) {
             # if 'verbose' option is set, be verbose!
            if (defined $options->{verbose}) {
            	print "File $nextString can't be read!\n";
            }
            next;
    	}

        # if file is directory
        if (-d $nextString) {
        		# get directory contents
        		$directoryContents = $self->directorySearch($nextString, $options, \@sourceFiles);

            	# check, if result is an array reference, if so push array to array,
            	# otherwise push single entry to array
				if (ref($directoryContents) eq "ARRAY") {
            		push(@sourceFiles, @{$directoryContents});
				} else {
					push(@sourceFiles, $directoryContents);
				}
            	next;
        }

		# if file is no text file
        unless (-T $nextString) {
        	# if 'verbose' option is set, be verbose!
            if (defined $options->{verbose}) {
            	print "$nextString is not a text file!\n";
            }
            next;
        }

		# push to source file array, if all the other conditions above are not met
        push(@sourceFiles, $nextString);
    }

    # return source files
    return \@sourceFiles;
}

# function to (possibly recursively) search inside the given directory for
# text files
sub directorySearch {
    my ($self, $directory, $options, $sourceFiles) = @_;
	my @sourceFiles;

	# check if source files array is alread defined
    if (defined @{$sourceFiles}) {
    	@sourceFiles = @{$sourceFiles};
	}

    # open directory
    opendir(DIR, $directory) || die("Couldn't open directory: $directory!\n");

	# read out files
    my @files = grep (!/^\./, readdir(DIR));
    
    # get complete path names
    @files = map("$directory/$_", @files);

	# close directory
    closedir(DIR);
    
    # go through each file in directory
    foreach my $nextString (@files) {
    	# if encountering another directoy and 'recurse' option set, recurse into
    	# sub-directory
        if ((-d $nextString) && ($options->{recurse})) {
        	push(@sourceFiles, @{$self->directorySearch($nextString, $options, \@sourceFiles)});
        }
        
        # if file is text file, add it to sourceFiles
        if (-T $nextString) {
        	# push to source file array
        	push(@sourceFiles, $nextString);
        }
    }
    
    # return source files
    return \@sourceFiles;
}


## functions for for the statistical dependency part of the program

# function for checking if a value is an integer or not!
sub isInteger {
    my ($self, $num) = @_;
    my $returnFlag;
    
    # check if $num equals int($num), that's it!
    if ($num eq int($num)) {
    	$returnFlag = 1;
    } else {
    	$returnFlag = 0;
    }
    
    # return
    return $returnFlag;
}

# function for printing statistical dependency model
sub printStatistic {
	my ($self, $options, $totalNgrams, $statistic) = @_;
	
	# try to open destination file
	open(DST, ">$options->{destination}")
		|| die("Couldn't open output file: $options->{destination}\n");

    # if unformatted printing, write n-grams now
    unless ($options->{format}) {
	    print DST "$totalNgrams\n";
    }

    # define index variable
    my $i;

	# define variables for formatted printing
    my $spaceBetweenFields = 2;
    my $maxNgramStringLength = length("N-gram");
    my $maxStatStringLength = 0;
    my $maxFreqLength = 0;
    my $maxRankLength = 0;
    my $spacesToAppend = 0;
    my $spacesToAppendForRank = 0;
   	my $spacesToAppendForStat = 0;
   	my $spacesToAppendForFreqValues = 0;

    # we will do the ranking ourselves, whereby all tied ngrams will
    # receive the same rank. moreover ranks will not have holes in them,
    # which means that no matter how many n-grams have rank x, the next
    # lower valued n-gram will have a rank of x + 1!
    my $rank = 1;

	# $currentScore is the score associated with the
  	# current rank.
	my $currentScore;
	
	# iterate over scores
    foreach my $score (sort {$b <=> $a} keys(%{$statistic})) {
  		# the rank is incremented only if the score drops below the current value
  		if (defined $currentScore) {
		    if ($score < $currentScore) {
		    	$rank++;
		    } elsif ($score > $currentScore) {
      			print STDERR "Weird Sorting error.\n";
      			exit(1);
		    }
  		}
  		
  		# write current score
		$currentScore = $score;

  		# if less than score cut-off quit!
		if (defined $options->{score}) {
			if ($score < $options->{score}) {
				last;
			}
		}

  		# if we have exceeded the display limit for the rank quit!
  		if (defined $options->{show}) {
  			if ($options->{show} < $rank) {
  				last;
  			}
  		}

  		# n-grams stored in $statistic are separated by <||>
  		# removing last <||>
  		$statistic->{$score} =~ s/<\|\|>$//;
  		my @ngramStrings = split(/<\|\|>/, $statistic->{$score});
  		
  		# if formatted output has been requested
    	if ($options->{format}) {
  		  	if (length($score) > $maxStatStringLength) {
  		  		$maxStatStringLength = length($score);
  		  	}
    		$maxRankLength = length($rank);

    		# so thats all our max lengths per field.
    		# now create the heading string
    		my $heading = "";

			# get spaces to append to n-gram heading
   			$spacesToAppend = ($maxNgramStringLength + $spaceBetweenFields - length("N-gram")) / 2;
    		for ($i = 0; $i < $spacesToAppend; $i++) {
  				$heading .= " ";
    		}
    		$heading .= "N-gram";
    		for ($i = 0; $i < $spacesToAppend; $i++) {
				$heading .= " ";
    		}

			# get spaces to append to rank heading
		    $spacesToAppend = (length("Rank") > $maxRankLength) ? length("Rank") : $maxRankLength;
    		$spacesToAppend += $spaceBetweenFields;
   			$spacesToAppend = ($spacesToAppend - length("Rank")) / 2;
    		for ($i = 0; $i < $spacesToAppend; $i++) {
				$heading .= " ";
    		}
    		$heading .= "Rank";
    		for ($i = 0; $i < $spacesToAppend; $i++) {
  				$heading .= " ";
    		}

			# get spaces to append to statistics library heading
    		$spacesToAppend =
  				(length("$options->{library} Value") > $maxStatStringLength) ? length("$options->{library} Value") : $maxStatStringLength;
    		$spacesToAppend += $spaceBetweenFields;
    		$spacesToAppend = ($spacesToAppend - length("$options->{library} Value")) / 2;
    		for ($i = 0; $i < $spacesToAppend; $i++) {
  				$heading .= " ";
    		}
    		$heading .= "$options->{library} Value";
    		for ($i = 0; $i < $spacesToAppend; $i++) {
  				$heading .= " ";
    		}

			# get spaces to append to frequency values heading
   			$spacesToAppend = (length("Frequency Values") > $maxFreqLength) ? length("Frequency Values") : $maxFreqLength;
    		$spacesToAppend += $spaceBetweenFields;
    		$spacesToAppend = ($spacesToAppend - length("Frequency Values")) / 2;
    		for ($i = 0; $i < $spacesToAppend; $i++) {
				$heading .= " ";
    		}
		    $heading .= "Frequency Values";
    		for ($i = 0; $i < $spacesToAppend; $i++) {
 				$heading .= " ";
    		}

			# get spaces to append to each field per row
		    $spacesToAppendForRank = (length("Rank") + $spaceBetweenFields - $maxRankLength) / 2;
   			$spacesToAppendForStat = (length("$options->{library} Value") + $spaceBetweenFields - $maxStatStringLength) / 2;
   			$spacesToAppendForFreqValues = (length("Frequency Values") + $spaceBetweenFields - $maxFreqLength) / 2;

			# print totals and heading
    		printf DST "Total sample size = $totalNgrams\n\n";
    		print DST "$heading\n";

    		# now draw an underline
    		for ($i = 0; $i < length($heading); $i++) {
    			print DST "-";
    		}
    		printf DST "\n";
    	}
    	
    	# iterate over n-grams
  		foreach my $ngramString (@ngramStrings) {
  			# get values
    		my @tokens = split(/<>/, $ngramString);
    		my $numberString = pop(@tokens);
    		my $ngram = join("<>", @tokens);

    		# check, if formatted or unformatted output has been requested
    		unless($options->{format}) {
    			# simple print, if unformatted output has been requested
	    		print DST "$ngram<>$rank $score $numberString\n";
    		} else {
    			# check size of string
    			$spacesToAppend = $maxNgramStringLength + $spaceBetweenFields - length($ngram);

				# print n-gram and spaces
	    		print DST $ngram;
    			for ($i = 0; $i < $spacesToAppend; $i++) {
    				print DST " ";
    			}

    			# print rank
    			for ($i = 0; $i < $spacesToAppendForRank; $i++) {
    				print DST " ";
    			}
    			printf(DST "%${maxRankLength}d", $rank);
    			for ($i = 0; $i < $spacesToAppendForRank; $i++) {
    				print DST " ";
    			}

				# print value calculated by statistical measure
	    		for ($i = 0; $i < $spacesToAppendForStat; $i++) {
	    			print DST " ";
	    		}
    			printf(DST "%${maxStatStringLength}.${$options->{precision}}f", $score);
    			for ($i = 0; $i < $spacesToAppendForStat; $i++) {
    				print DST " ";
    			}

				# print frequency value
    			for ($i = 0; $i < $spacesToAppendForFreqValues; $i++) {
    				print DST " ";
    			}
    			printf DST "$numberString\n";
    		}
  		}
    }
    
    # close destination file
    close(DST);
}

# function for running multiple count.pl processes
sub runMultipleCount {
    my ($self, $file, $options) = @_;
    my @arguments;
    
    # use Counter module
    use Text::NSP::Counter;

    # instantiate counter object
    my $counter = new Text::NSP::Counter();

    # --ngram used, push option to argument array
    if(defined $options->{ngram}) {
    	push(@arguments, ("--ngram", $options->{ngram}));
    }

    # --window used, push option to argument array
    if(defined $options->{window}) {
    	push(@arguments, ("--window", $options->{window}));
    }

	# --token used, push option to argument array
	if(defined $options->{token}) {
    	push(@arguments, ("--token", $options->{token}));
	}

    # --nontoken used, push option to argument array
    if(defined $options->{nontoken}) {
    	push(@arguments, ("--nontoken", $options->{nontoken}));
    }

	# --stop used, push option to argument array
	if(defined $options->{stop}) {
    	push(@arguments, ("--stop", $options->{stop}));
	}

	# --newLine used, push option to argument array
    if(defined $options->{newLine}) {
    	push(@arguments, ("--newLine", 1));
    }
    
    # push source and destination to argument array
    push(@arguments, ("--destination", "$file.ngrams", "--source", $file));

	# start counting process
	$counter->start(\@arguments);
}

1;

__END__
