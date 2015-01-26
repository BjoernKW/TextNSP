#!/usr/bin/env perl

=head1 NAME

split-data.pl

=head1 SYNOPSIS

Splits a given data file into N parts such that each part has approximately 
same number of lines.

=head1 USAGE

split-data.pl [Options] DATA

Type 'split-data.pl --help' for a quick summary of the Options.

=head1 INPUT

=head2 Required Arguments:

=head3 DATA

DATA should be a file in plain text format such that each line in the DATA 
file shows a single training example.

=head2 Optional Arguments:

=head4 --parts N

Splits the DATA file into N equal parts. If the DATA file has M lines, 
each part except the last part will have int(M/N) lines while the 
last part will have all the remaining lines, M - (N-1 * (int(M/N))).

Default N is 10.

=head3 Other Options :

=head4 --help

Displays the quick summary of options.

=head4 --version

Displays the version information.

=head1  OUTPUT

split-data.pl creates exactly N files in the current directory. If the name
of the DATA file is say DATA-file, then the N files will have names as 
DATA-file1, DATA-file2, DATA-file3,... DATA-fileN. e.g. If the DATA filename 
is ANC, then the N files created by split-data.pl will have names like 
ANC1, ANC2, ..., ANCN. 

A DATA file containing total M lines is split into N parts such that 
each part/file contains approximately M/N lines.

Thus, if N = 1, the output file will be exactly same as the given DATA file.
If N = M where N = value of --parts and M = #lines in DATA then,
each part will have a single line.

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

# use module containing data splitter functionality
use Text::NSP::DataSplitter;


## initialise

# initialise data splitter
my $dataSplitter = new Text::NSP::DataSplitter();


## start

# start data splitter
$dataSplitter->start(\@ARGV);


#-----------------------------------------------------------------------------
#                              end of program
#-----------------------------------------------------------------------------
