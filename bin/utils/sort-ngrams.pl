#!/usr/bin/env perl

=head1 NAME

sort-ngrams.pl

=head1 SYNOPSIS

Sorts a given n-gram file in the descending order of the n-gram scores.

=head1 USAGE

sort-ngrams.pl [OPTIONS] --model NGRAM

=head1 INPUT

=head2 Required Arguments:

=head3 NGRAM

Should be an n-gram input file to be sorted. An NGRAM file created by 
count.pl or statistic.pl is already sorted in the descending order of the 
bigram scores. An NGRAM output of combig.pl or huge-combine.pl is 
however un-sorted and could be sorted using this program.

All lines in NGRAM file should be formatted as -

 word1<>word2<>n11 n1p np1

Or as -

 word1<>word2<>rank score n11 n1p np1

=head2 Optional Arguments:

=head4 --frequency F

N-grams with counts/scores less than F will not be displayed. The ignored 
n-grams are however not removed from the sample and their counts are
still counted in the total ngrams and in the marginal word frequencies.
In other words, the behavior of this option is like count.pl's --frequency 
option.

=head4 --remove L

N-grams with counts/scores less than L are completely removed from the sample.
Their counts do not affect any marginal totals. In other words, this option
has the same effect as count.pl's --remove option.

=head3 Other Options :

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

sort-ngrams.pl shows given NGRAMs in the descending order of their counts/
scores.

=head1 AUTHOR

Bjoern Wilmsmann.
Ruhr-University Bochum.

=head1 COPYRIGHT

Copyright (c) 2006,

Bjoern Wilmsmann, Ruhr-University, Bochum.
bjoern@wilmsmann.de

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

#-----------------------------------------------------------------------------
#                              start of program
#-----------------------------------------------------------------------------


## include external libraries

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use module containing n-gram sorter functionality
use Text::NSP::NgramSorter;


## initialise

# initialise n-gram sorter
my $ngramSorter = new Text::NSP::NgramSorter();


## start

# start n-gram sorter
$ngramSorter->start(\@ARGV);


#-----------------------------------------------------------------------------
#                              end of program
#-----------------------------------------------------------------------------
