=head1 NAME

Text::NSP::Time::StopWatch - 	A time measurement instrument for the purpose of
								measuring the efficiency of Text-NSP

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

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Time::StopWatch

=head1 DESCRIPTION

=head2 Error Codes

=head2 Methods

=over

=cut


package Text::NSP::Time::StopWatch;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use high time resolution for getting microtime() instead of just time()
use Time::HiRes;

our ($VERSION);

$VERSION = '0.0.1';

# constructor
sub new {
	my ($class) = @_;
	my $self = {
		startTime => 0,
		endTime => 0,
		timeConsumed => 0
	};
	bless($self, $class);
	return $self;
}

# start time
sub startTime {
	my ($self) = @_;
	$self->{startTime} = Time::HiRes::time();
}

# stop time
sub stopTime {
	my ($self) = @_;
	$self->{endTime} = Time::HiRes::time();
}

# get time
sub getTime {
	my ($self) = @_;
	$self->{timeConsumed} = $self->{endTime} - $self->{startTime};
	return $self->{timeConsumed};
}

1;

__END__

