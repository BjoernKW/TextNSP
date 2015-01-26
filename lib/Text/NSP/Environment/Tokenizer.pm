=head1 NAME

Text::NSP::Environment::Tokenizer - 	A tokenizer for use in Text-NSP

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Environment::Tokenizer

=head1 DESCRIPTION

=head1 AUTHOR

Bjoern Wilmsmann, bjoern@wilmsmann.de

=head1 COPYRIGHT

Copyright (C) 2006, Bjoern Wilmsmann

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


package Text::NSP::Environment::Tokenizer;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use locale for localised tokenization
use locale;

our($VERSION);

$VERSION = '0.0.1';

# constructor
sub new {
	my ($class,
		$ngrams,
		$ngramTotal,
		$frequencies,
		$frequencyCombinations,
		$ngramSize,
		$windowSize,
		$tokenCombinations) = @_;
	my $self = {
		ngrams => $ngrams,
		ngramTotal => $ngramTotal,
		frequencies => $frequencies,
		frequencyCombinations => $frequencyCombinations,
		ngramSize => $ngramSize,
		windowSize => $windowSize,
		tokenCombinations => $tokenCombinations
	};
	bless($self, $class);
	return $self;
}


## tokenizer functions

# function for token processing
sub processTokens {
    my ($self, $token) = @_;
    my $i;
    my $j;
    my $k;
	my @ngram;
	my $ngramBuffer;
	my $frequencyBuffer;
	
	# push to token window
	push(@{$self->{tokenWindow}}, $token);

	# unless window has reached n-gram size: skip token
	unless (@{$self->{tokenWindow}} >= $self->{ngramSize}) {
		return 1;
	}

	# if n-gram size > 1
	# The algorithm for processing n-grams > 1 works like this:
	# 1) 	Token combinations are created for window size -1 and n-gram - 1 as additional combinations
	# 		can be derived from these values.
	# 2) 	The window starts at minimum n-gram size and grows until it has reached maximum window size.
	# 3) 	Get token combinations.
	# 4) 	Process combinations in n-gram-sized packages.
	# 5) 	If token combination value does not exceed limits of the current window, add to n-gram,
	#		otherwise mark this combination as not applicable for the current window size.
	# 6)	Add final token of the current window to n-gram, this allows us to have all possible
	#		token combinations for the actual window and n-gram size although the combination matrix
	#		has been calculated for window size - 1 and n-gram size - 1 for both speed reasons and avoiding
	#		double counts (e.g., combination 1 2 is essentially the same as 0 1 for window = 3 and n-gram = 2,
	#		because it will be reached anyway once the window is shifted).
	# 7)	Calculate frequencies.
	if ($self->{ngramSize} > 1) {
	    # get relevant token combinations
	    $i = 0;
        while ($i <= @{$self->{tokenCombinations}} - 1) {
			# reset values
	        $ngramBuffer = "";
    	    my $allowed = 1;

			# get token combinations in n-gram-sized packages
        	for ($j = 0; $j < $self->{ngramSize} - 1; $j++) {
				# if combination value does not exceed window size, add corresponding token to n-gram,
				# otherwise mark as not allowed
				if ($self->{tokenCombinations}->[$i] < @{$self->{tokenWindow}} - 1) {
                	$ngramBuffer .= $self->{tokenWindow}->[$self->{tokenCombinations}->[$i]] . "<>";
                } else {
                	$allowed = 0;
                }

				# increment combination index
                $i++;
            }
	       
	       	# if combination is allowed (i.e. does not range beyond window)
            if ($allowed) {
            	# append final token to n-gram
				$ngramBuffer .= $self->{tokenWindow}->[@{$self->{tokenWindow}} - 1] . "<>";

				# increment value at n-gram hash
	    		$self->{ngrams}->{$ngramBuffer}++;

	    		# split n-gram into single words
	        	@ngram = split(/<>/, $ngramBuffer);

	    		# now increment the various frequencies according to $frequencyCombinations
    	    	for ($j = 0; $j < @{$self->{frequencyCombinations}}; $j++) {
	    	    	# reset frequency buffer
    	    		$frequencyBuffer = "";

					# go through frequency combinations
    				for ($k = 0; $k < @{$self->{frequencyCombinations}->[$j]}; $k++) {
        				$frequencyBuffer .= "$ngram[$self->{frequencyCombinations}->[$j]->[$k]]<>";
            		}
            		$frequencyBuffer .= $j;

					# increment value in frequency hash
    				$self->{frequencies}->{$frequencyBuffer}++;
        		}

	   			# increment total n-gram count
    			$self->{ngramTotal}++;
    			$ngramBuffer = "";
            }
   		}
	} else {
		# if n-gram size = 1,
		# first increment value at n-gram hash,
		# then increment value in frequency hash,
		# finally increment total n-gram count... that's all
	    $self->{ngrams}->{"@{$self->{tokenWindow}}<>"}++;
    	$self->{frequencies}->{"@{$self->{tokenWindow}}<>0"}++;
		$self->{ngramTotal}++;
	}

	# if window has reached maximum: shift from window
	if (@{$self->{tokenWindow}} == $self->{windowSize}) {
		shift(@{$self->{tokenWindow}});
	}
}

# alternative function for token processing
sub processTokens2 {
    my ($self, $tokenWindow, $tokenWindowCount) = @_;
    my $i;
    my $j;
    my $k;
	my @ngram;
	my $ngramBuffer;
	my $frequencyBuffer;

	# if n-gram size > 1
	# The algorithm for processing n-grams > 1 works like this:
	# 1) 	Token combinations are created for window size -1 and n-gram - 1 as additional combinations
	# 		can be derived from these values.
	# 2) 	The window starts at minimum n-gram size and grows until it has reached maximum window size.
	# 3) 	Get token combinations.
	# 4) 	Process combinations in n-gram-sized packages.
	# 5) 	If token combination value does not exceed limits of the current window, add to n-gram,
	#		otherwise mark this combination as not applicable for the current window size.
	# 6)	Add final token of the current window to n-gram, this allows us to have all possible
	#		token combinations for the actual window and n-gram size although the combination matrix
	#		has been calculated for window size - 1 and n-gram size - 1 for both speed reasons and avoiding
	#		double counts (e.g., combination 1 2 is essentially the same as 0 1 for window = 3 and n-gram = 2,
	#		because it will be reached anyway once the window is shifted).
	# 7)	Calculate frequencies.
	if ($self->{ngramSize} > 1) {
	    # get relevant token combinations
	    $i = 0;
        while ($i <= @{$self->{tokenCombinations}} - 1) {
			# reset values
	        $ngramBuffer = "";
    	    my $allowed = 1;

			# get token combinations in n-gram-sized packages
        	for ($j = 0; $j < $self->{ngramSize} - 1; $j++) {
				# if combination value does not exceed window size, add corresponding token to n-gram,
				# otherwise mark as not allowed
				if ($self->{tokenCombinations}->[$i] < @{$tokenWindow} - 1) {
                	$ngramBuffer .= $tokenWindow->[$self->{tokenCombinations}->[$i]] . "<>";
                } else {
                	$allowed = 0;
                }

				# increment combination index
                $i++;
            }
	       
	       	# if combination is allowed (i.e. does not range beyond window)
            if ($allowed) {
            	# append final token to n-gram
				$ngramBuffer .= $tokenWindow->[@{$tokenWindow} - 1] . "<>";

				# increment value at n-gram hash
	    		$self->{ngrams}->{$ngramBuffer} += $tokenWindowCount;

	    		# split n-gram into single words
	        	@ngram = split(/<>/, $ngramBuffer);

	    		# now increment the various frequencies according to $frequencyCombinations
    	    	for ($j = 0; $j < @{$self->{frequencyCombinations}}; $j++) {
	    	    	# reset frequency buffer
    	    		$frequencyBuffer = "";

					# go through frequency combinations
    				for ($k = 0; $k < @{$self->{frequencyCombinations}->[$j]}; $k++) {
        				$frequencyBuffer .= "$ngram[$self->{frequencyCombinations}->[$j]->[$k]]<>";
            		}
            		$frequencyBuffer .= $j;

					# increment value in frequency hash
    				$self->{frequencies}->{$frequencyBuffer} += $tokenWindowCount;
        		}

	   			# increment total n-gram count
    			$self->{ngramTotal} += $tokenWindowCount;
    			$ngramBuffer = "";
            }
   		}
	} else {
		# if n-gram size = 1,
		# first increment value at n-gram hash,
		# then increment value in frequency hash,
		# finally increment total n-gram count... that's all
	    $self->{ngrams}->{"@{$tokenWindow}<>"} += $tokenWindowCount;
    	$self->{frequencies}->{"@{$tokenWindow}<>0"} += $tokenWindowCount;
		$self->{ngramTotal} += $tokenWindowCount;
	}
}

# function to remove an ngram and adjust the various frequency counts
# appropriately
sub removeNgram {
    my ($self, $ngramString) = @_;
   	my @ngram;
   	my $i;
   	my $j;
	my $frequencyValue;
	my $frequencyBuffer;

    # first reduce the n-gram total by the frequency of this n-gram
    $self->{ngramTotal} -= $self->{ngrams}->{$ngramString};

	# split n-gram into single words
	@ngram = split(/<>/, $ngramString);

	# now iterate over $frequencyCombinations
    for ($i = 0; $i < @{$self->{frequencyCombinations}}; $i++) {
		# reset frequency buffer
		$frequencyBuffer = "";

		# go through frequency combinations
    	for ($j = 0; $j < @{$self->{frequencyCombinations}->[$i]}; $j++) {
        	$frequencyBuffer .= "$ngram[$self->{frequencyCombinations}->[$i]->[$j]]<>";
        }
        $frequencyBuffer .= $i;

		# decrease value for this freqeuncy combination
		$self->{frequencies}->{$frequencyBuffer} -= $self->{ngrams}->{$ngramString};
        if ($self->{frequencies}->{$frequencyBuffer} <= 0) {
        	# if new value for this freqeuncy combination
        	# is below 0, delete it altogether
            delete($self->{frequencies}->{$frequencyBuffer});
        }
    }

	# delete n-gram
	delete($self->{ngrams}->{$ngramString});
}

# function for adding information in an n-gram file entry to queue
# for merge process
sub addNgramEntry {
	my ($self, $ngramString, $scores, $file) = @_;
	my $i;
	my $j;
	my $frequencyValue;
	my $frequencyBuffer;
	my @ngram;

	# split n-gram into single words
	@ngram = split(/<>/, $ngramString);

	# now increment the various frequencies according to $frequencyCombinations
    for ($i = 0; $i < @{$self->{frequencyCombinations}}; $i++) {
		# reset frequency buffer
		$frequencyBuffer = "";

		# go through frequency combinations
    	for ($j = 0; $j < @{$self->{frequencyCombinations}->[$i]}; $j++) {
        	$frequencyBuffer .= "$ngram[$self->{frequencyCombinations}->[$i]->[$j]]<>";
        }
        $frequencyBuffer .= $i;
        
        # get frequency value
        $frequencyValue = $scores->[$i];

		# write frequency value to frequency hash
		# if value for this frequency does not yet exist
		# in this file
		unless(defined $self->{merge}->{$file}->{frequencies}->{$frequencyBuffer}) {
	    	$self->{merge}->{$file}->{frequencies}->{$frequencyBuffer} = $frequencyValue;
		}
		
		# write frequency for n-gram to n-gram hash
		# for this file
		if ($i == 0) {
			$self->{merge}->{$file}->{ngrams}->{$ngramString} = $frequencyValue;
		}
	}
}

# function for merging n-gram models
sub merge {
	my ($self) = @_;

	# iterate over frequency models to be merged
	foreach my $file (keys(%{$self->{merge}})) {
		# iterate over frequencies in this model
		foreach my $frequencyBuffer (keys(%{$self->{merge}->{$file}->{frequencies}})) {
			# write entry to global frequency hash
			$self->{frequencies}->{$frequencyBuffer} += $self->{merge}->{$file}->{frequencies}->{$frequencyBuffer};
		}
		
		# iterate over n-grams in this model
		foreach my $ngramBuffer (keys(%{$self->{merge}->{$file}->{ngrams}})) {
			# write entry to global n-gram hash
			$self->{ngrams}->{$ngramBuffer} = $self->{merge}->{$file}->{ngrams}->{$ngramBuffer};
		}
	}
}

# function for printing tokens
sub printTokens {
	my ($self, $options) = @_;
	my $i;
	my $j;
	my @ngram;
	my $ngramBuffer;

	# try to open destination file
	open(DST, ">>$options->{destination}") || die("Couldn't open output file: $options->{destination}");

	# if n-gram size > 1
	if ($options->{ngram} > 1) {
		# sort token frequencies
		foreach (sort {$self->{ngrams}->{$b} <=> $self->{ngrams}->{$a}} keys (%{$self->{ngrams}})) {
   			# check if this is below the cut-off frequency to be displayed
    		# as set by switch --frequency. if so, quit the loop
    		if ($self->{ngrams}->{$_} < $options->{frequency}) {
    			last;
    		}

        	# split n-gram into single words
        	@ngram = split(/<>/, $_);

	    	# if a line starts with a single @, its a command (extended output).
    		# if it starts with two consequtive @'s, then its a single 'literal' @.
    		if ($_ =~ /^@/) {
    			print DST "@";
    		}
    	
    		# print n-gram
    		print DST "$_";

			# go through frequency combinations
        	for ($i = 0; $i < @{$self->{frequencyCombinations}}; $i++) {		
   				# reset n-gram buffer
        		$ngramBuffer = "";

				# go through frequency combinations
    		    for ($j = 0; $j < @{$self->{frequencyCombinations}->[$i]}; $j++) {
        	    	$ngramBuffer .= "$ngram[$self->{frequencyCombinations}->[$i]->[$j]]<>";
            	}
            	$ngramBuffer .= $i;

				# print this frequency combination
    	    	print DST "$self->{frequencies}->{$ngramBuffer} ";
        	}

			# new line
    		print DST "\n";
		}
	} else {
		# sort token frequencies
		foreach (sort {$self->{ngrams}->{$b} <=> $self->{ngrams}->{$a}} keys (%{$self->{ngrams}})) {
   			# check if this is below the cut-off frequency to be displayed
    		# as set by switch --frequency. if so, quit the loop
    		if ($self->{ngrams}->{$_} < $options->{frequency}) {
    			last;
    		}

			# if n-gram size = 1, just print this unigram and its frequency and that's it!
			print DST $_ . $self->{frequencies}->{$_ . "0"} . "\n";
		}
	}
	
	# close destination file
	close(DST);
}


# function to create a histogram given a hash of frequencies
sub createHistogram {
	my ($self, $options) = @_;
	
    # check if output histogram file already exists
    if (-e $options->{histogram}) {
        print "File $options->{histogram} exists! Overwrite (Y/N)? ";
        my $reply = <STDIN>;
        chomp($reply);
        $reply = uc($reply);
        return if ($reply ne "Y");
    }

    # if we are allowed to open file, do so
    open(HST, ">$options->{histogram}") || die("Couldn't open $options->{histogram}");

    # construct the histogram hash
    my %histogram = ();
    foreach (keys(%{$self->{ngrams}})) {
    	$histogram{$self->{ngrams}->{$_}}++;
    }

    # print total number of n-grams
    print HST "Total n-grams = $self->{ngramTotal}\n";

	# print number of n-grams that occurred x times
    foreach (sort {$a <=> $b} keys(%histogram)) {
	    printf HST "Number of n-grams that occurred %3d time(s) = %5d (%.2f percent)\n", $_, $histogram{$_}, ($histogram{$_} * $_ * 100) / $self->{ngramTotal};
    }

    close(HST);
}

1;

__END__

