#!/usr/bin/env perl

=head1 NAME

huge-combine.pl

=head1 SYNOPSIS

Combines two n-gram files created by count.pl into a single n-gram file.

=head1 USGAE

huge-combine.pl [OPTIONS] --count1 COUNT1 --count2 COUNT2

=head1 INPUT

=head2 Required Arguments:

=head3 COUNT1 and COUNT2

huge-combine.pl takes two n-gram files created by count.pl as input.
If COUNT1 and COUNT2 are of unequal sizes, it is strongly recommended 
that COUNT1 should be the smaller file and COUNT2 should be the larger 
n-gram file.

Each line in files COUNT1, COUNT2 should be formatted as -

word1<>word2<>n11 n1p np1

where word1<>word2 is a n-gram, n11 is the joint frequency score of this
n-gram, n1p is the number of n-grams in which word1 is the first word,
while np1 is the number of n-grams having word2 as the second word.

=head2 Optional Arguments:

=head4 --help

Displays this message.

=head4 --version

Displays the version information.

=head1 OUTPUT

Output displays all n-grams that appear either in COUNT1 (inclusive) or
in COUNT2 along with their updated scores. Scores are updated such that -

=over

=item 1: 

If a n-gram appears in both COUNT1 and COUNT2, their n11 scores are added.

e.g. If COUNT1 contains a n-gram 
	word1<>word2<>n11 n1p np1
and COUNT2 has a n-gram
	word1<>word2<>m11 m1p mp1

Then, the new n11 score of n-gram word1<>word2 is n11+m11

=item 2:

If the two n-grams belonging to COUNT1 and COUNT2 share a commom first word, 
their n1p scores are added.

e.g. If COUNT1 contains a n-gram
	word1<>word2<>n11 n1p np1
and if COUNT2 contains a n-gram
	word1<>word3<>m11 m1p mp1

Then, the n1p marginal score of word1 is updated to n1p+m1p

=item 3:

If the two n-grams belonging to COUNT1 and COUNT2 share a commom second word,
their np1 scores are added.

e.g. If COUNT1 contains a n-gram
        word1<>word2<>n11 n1p np1
and if COUNT2 contains a n-gram
        word3<>word2<>m11 m1p mp1

Then, the np1 marginal score of word2 is updated to np1+mp1

=back

=head1 AUTHOR

Bjoern Wilmsmann, Ruhr-University, Bochum.

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

# use locale for localised tokenization
use locale;

# use module containing combiner functionality
use Text::NSP::Combiner;


## initialise

# initialise combiner
my $combiner = new Text::NSP::Combiner();


## start

# start combiner
$combiner->start(\@ARGV);


#-----------------------------------------------------------------------------
#                              end of program
#-----------------------------------------------------------------------------

