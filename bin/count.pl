#!/usr/bin/env perl

=head1 NAME

count.pl

=head1 SYNOPSIS

count.pl takes one or more text files as input and calculates the ngram  
frequency for the whole corpus.
This is a complete re-write of the original script by Satanjeev Banerjee, bane0025@d.umn.edu
and Ted Pedersen, tpederse@d.umn.edu

=head1 DESCRIPTION

See perldoc README.pod

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

=cut

# count.pl version 0.59
#

###############################################################################
#
#                       -------         CHANGELOG       ---------
#
#version        date            programmer      List of changes     change-id
#
# 0.59			13/11/2006		Bjoern Wilmsmann moved count.pl		 BW.58.1
#											     to Counter class			
#
# 0.58			13/11/2006		Bjoern Wilmsmann rewrite			 BW.58.1
#
# 0.53          01/06/2003      Amruta      (1)	Added Perl Regex     ADP.53.1	
#						support for stop 
#						option 
#
#		01/06/2003	Amruta	    (2) Added AND & OR modes
#						for stop option      ADP.53.2	
#						making AND default	
#
#		01/07/2003	Amruta	    (3) Introduced 
#						--nontoken option    ADP.53.3	
#                   
# 0.57          06/30/2003      Ted         (1) show remove value    TDP.57.1
#                                               in extended output
#             
#               07/01/2003      Ted         (2) if destination file  TDP.57.2
#		                                found, check for 
#                                               source before proceeding
###############################################################################

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

# DEBUG: set locale for testing purposes
# use POSIX qw(locale_h);
# setlocale(LC_CTYPE, "de_DE");

# use module containing counter functionality
use Text::NSP::Counter;


## initialise

# initialise counter
my $counter = new Text::NSP::Counter();


## start

# start counter
$counter->start(\@ARGV);


#-----------------------------------------------------------------------------
#                              end of program
#-----------------------------------------------------------------------------

