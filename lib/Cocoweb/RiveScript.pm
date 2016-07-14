# @created 2016-07-04
# @date 2016-07-14
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
#
# cocobot is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# cocobot is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA  02110-1301, USA.
package Cocoweb::RiveScript;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Encode;
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use RiveScript;
use utf8;
no utf8;

my $unaccentMap = {

    #LATIN SMALL LETTER E WITH GRAVE
    "\xE8" => "e",

    # LATIN SMALL LETTER E WITH ACUTE
    "\xE9" => "e",

    # 00EA LATIN SMALL LETTER E WITH CIRCUMFLEX
    "\xEA" => "e",

    # 00EE LATIN SMALL LETTER I WITH CIRCUMFLEX
    "\xEE" => "i",

    # 00EF LATIN SMALL LETTER I WITH DIAERESIS
    "\xEF" => "i",

    # LATIN SMALL LETTER O WITH CIRCUMFLEX
    "\xF4" => "o",

    # LATIN SMALL LETTER A WITH GRAVE
    "\xE0" => "a",

    # 00E2 LATIN SMALL LETTER A WITH CIRCUMFLEX
    "\xE2" => "a",

    # 00E7 LATIN SMALL LETTER C WITH CEDILLA
    "\xE7" => "c",
};

__PACKAGE__->attributes('rs');

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    my $rs = RiveScript->new( 'utf8' => 0, 'debug' => 0 );
    $self->attributes_defaults(
        'rs'      => $rs,
        'convert' => Cocoweb::Encode->instance(),
    );
}

sub loadDirectory {
    my ( $self, $pathname ) = @_;
    $pathname = Cocoweb::Config->instance()->getDirPath($pathname);
    $self->{'rs'}->loadDirectory($pathname);
}

sub sortReplies {
    my $self = shift;
    $self->{'rs'}->sortReplies();

}

sub reply {
    my ( $self, $user, $message ) = @_;
    if ( $message =~ m{^http://www\.coco.fr/pub/photo0?\.htm.*} ) {
        $message = "http www coco fr pub photo0";
    }
    elsif ( $message =~ m{^[\?]+$} ) {
        $message = "point d interrogation";
    }
    else {
        $message =~ s{'}{ }g;
        $message = $self->unacString($message);
    }

    my $reply = $self->{'rs'}->reply( $user, $message );
    utf8::encode($reply);
    return $reply;
}

##@method string unacString()
#@brief Return the unaccented equivalent to the input string.
#@author Peter John Acklam
#@param string
#@return string
sub unacString {
    my ( $self, $string ) = @_;
    $string = Encode::decode( 'UTF-8', $string );

    #replace euro sign
    $string =~ s{\x{20AC}}{E}g;
    my $offsetMax = length($string) - 1;
    my $strOut    = '';
    for my $offset ( 0 .. $offsetMax ) {
        my $chr = substr( $string, $offset, 1 );
        $strOut .= exists $unaccentMap->{$chr} ? $unaccentMap->{$chr} : $chr;
    }
    return $strOut;
}

1;
