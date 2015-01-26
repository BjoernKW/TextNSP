=head1 NAME

Text::NSP::Environment::XMLParser - 	A wrapper for XML::Parser

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Environment::XMLParser

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


package Text::NSP::Environment::XMLParser;

# use strict, as we do not our variables to go haywire
use strict;

# use this for debugging purposes
use warnings;

# use XML::Parser (at the point of calling this class, we know XML::Parser does exist)
use XML::Parser;

our($VERSION);

$VERSION = '0.0.1';

# define class variable
my $self;

# constructor
sub new {
	my %options;
	my ($class, $urlTags, $urlContent) = @_;
	$self = {
		urlTags => $urlTags,
		urlContent => $urlContent
	};
	bless($self, $class);
	return $self;
}

# function for parsing XML files
sub parse {
	my ($self, $content) = @_;
	
	# initialise new parser object
	my $parser = new XML::Parser(ErrorContext => 2);
	
	# set handlers
	$parser->setHandlers(Start => \&handleStartTag,
						Char => \&handleChar);

	# parse
	$parser->parse($content);
}

# function for handling start tags
sub handleStartTag {
	my ($parser, $element, %attributes) = @_;

	# push start tag to array
	push(@{$self->{urlTags}}, $element);
}

# function for handling characters between tags
sub handleChar {
	my ($parser, $data) = @_;

	# push character data to array
	push(@{$self->{urlContent}}, $data);
}

1;

__END__
