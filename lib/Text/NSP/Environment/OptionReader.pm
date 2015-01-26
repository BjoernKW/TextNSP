=head1 NAME

Text::NSP::Environment::OptionReader - 	A reader for command line options

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Environment::OptionReader

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


package Text::NSP::Environment::OptionReader;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

our($VERSION);

$VERSION = '0.0.1';

# constructor
sub new {
	my %options;
	my ($class) = @_;
	my $self = {
		options => \%options
	};
	bless($self, $class);
	return $self;
}

# function for getting command line arguments
sub getCommandLineArgs {
	my $key;
	my $isValue = 0;
	my @values;
	my %splitThese;
	my ($self, $defaults, $argv) = @_;

	# go through default arguments
	foreach my $arg (@{$defaults}) {
		if ($arg =~ /^-+(.*)$/) {
			$key = $1;
			$self->{options}->{$key} = 1;
			
			# this is an option name, no value
			$isValue = 0;
		} else {
			$self->{options}->{$key} = $arg;
			
			# this is an option value, however a default one, so cardinality cannot be > 1
			$isValue = 2;
		}
	}

	# go through command line arguments
	foreach my $arg (@{$argv}) {
		if ($arg =~ /^-+(.*)$/) {
			$key = $1;
			$self->{options}->{$key} = 1;
			$isValue = 0;
		} else {
			# check if several values for one argument have been sent.
			# if yes ($isValue == 1), append them and mark them for later
			# processing 
			if ($isValue == 0) {
				$self->{options}->{$key} = $arg;
			}
			if ($isValue == 1) {
				$self->{options}->{$key} .= " " . $arg;
				$splitThese{$key} = 1;
			}

			# this is an option value, so cardinality can be > 1
			$isValue = 1;
		}
	}
	
	# go through arguments with several values
	foreach my $splitThis (keys(%splitThese)) {
		@values = split(/ /, $self->{options}->{$splitThis});
		$self->{options}->{$splitThis} = \@values;
	}

	# return options
	return $self->{options};
}

1;

__END__

