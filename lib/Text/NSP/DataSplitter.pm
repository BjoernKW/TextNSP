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

package Text::NSP::DataSplitter;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use option reader module for getting command line options
use Text::NSP::Environment::OptionReader;

# use tokenizer module
use Text::NSP::Environment::Tokenizer;

# use optional LWP module
eval {
	require LWP::UserAgent;
};

our ($VERSION);

$VERSION = '0.0.2';

# constructor
sub new {
	my ($class) = @_;
	my $self = {};
	bless($self, $class);
	return $self;
}

# function that starts the data splitting process
sub start {
	my ($self, $argv) = @_;
	
	## initialise some support classes and methods

	# initialise option reader
	my $optionReader = new Text::NSP::Environment::OptionReader();

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
		my @defaults = ("--parts", 10);
		$options = $optionReader->getCommandLineArgs(\@defaults, $argv);
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
	
	# error for missing --data
	unless (defined $options->{data}) {
		print STDERR "ERROR: No data file has been supplied.\n";
		exit(1);
	}
	
	# error for non-existent data file
	unless (-e $options->{data}) {
		print STDERR "ERROR: Data file $options->{data} does not exist.\n";
		exit(1);
	}

	# open data file
	open(IN, $options->{data})
	  	|| die("Can't open data file $options->{data}.\n");
	

	## preliminaries done, main program starts here!

	# get total number of lines in data file
	my $total = 0;
	while (<IN>) {
		$total++;
	}
	
	# move line pointer back to the beginning
	seek(IN, 0, 0);

	# if desired parts > total number of lines
	if($options->{parts} > $total) {
		print STDERR "ERROR: Can't divide data file $options->{data} with $total lines into $options->{parts} parts.\n";
		exit(1);
	}


	# set part and lines variables
	my $part = 1;
	my $lineNumber= 0;

	# define name for file for first part
	my @fileNameComponents = split("/", $options->{data});
	my $partFile = $fileNameComponents[@fileNameComponents - 1] . $part;

	# if file does exist, print a warning
	if(-e $partFile) {
		print "Output file $partFile already exists! Overwrite (Y/N)?";
		$reply = <STDIN>;
		chomp($reply);
		$reply = uc($reply);
		if ($reply ne "Y") {
			exit(0);
		}
	}
	
	# try to open file for part
	open(PART, ">$partFile")
		|| die("Couldn't open output file: $partFile");

	# iterate over input file
	while(<IN>) {
		# if the number of lines processed for this part is smaller than each part
		# is supposed to be or if this part is the last part
		if ($lineNumber < int($total / $options->{parts}) || $part == $options->{parts}) {
			# simply print input and increment line number
			print PART $_;
			$lineNumber++;
		} else {
			# we are supposed to switch to the next part, so increment index
			$part++;

			# reset line number
			$lineNumber = 0;

			# define file name for file for this part
			@fileNameComponents = split("/", $options->{data});
			$partFile = $fileNameComponents[@fileNameComponents - 1] . $part;

			# if this file does exist, print a warning
            if(-e $partFile) {
				print "Output file $partFile already exists! Overwrite (Y/N)?";
				$reply = <STDIN>;
				chomp($reply);
				$reply = uc($reply);
				if ($reply ne "Y") {
					exit(0);
				}
            }

			# close file for former part
			close(PART);

            # try to open file for next part
			open(PART, ">$partFile")
				|| die("Couldn't open output file: $partFile");
				
			# now print the first line to the next part and increment line number
			print PART $_;
			$lineNumber++;
		}
	}
	
	# close last part
	close(PART);
	
	# close input file
	close(IN);
}

# function for printing a minimal usage note when the user has not provided any
# command line options
sub showMinimalUsageNotes {
	print STDERR "Usage: split-data.pl [OPTIONS] --data DATA\n";
	showAskHelp();
}

# function for printing help messages for this program
sub showHelp {
	print "Usage: split-data.pl [OPTIONS] --data DATA";
	print "Splits a given DATA file into N parts, each containing approximately same\n";
	print "number of lines.\n\n";

	print "Options:\n\n";

	print "  --parts N          Splits the DATA file into N parts. Default is 10.\n\n";
    print "  --help             Displays this message.\n\n";
    print "  --version          Displays the version information.\n\n";
   	print "Type 'perldoc split-data.pl' for a detailed documentation of this program.\n";
}

# function for printing the version number
sub showVersion {
	print "count.pl      -        version 0.02\n";
	print "Copyright (C) 2006, Bjoern Wilmsmann\n";
	print "Copyright (C) 2004, Amruta Parundare & Ted Pedersen\n";
	print "Date of Last Update 30/11/06\n";
}

# function for printing an 'ask for help' message
sub showAskHelp {
	print STDERR "Type split-data.pl --help for help.\n";
	print STDERR "Type 'perldoc split-data.pl' for detailed description of this program.\n"
}

1;

__END__

