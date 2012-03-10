# @brief Handle character encoding specific to Coco.fr chat
# @created 2012-03-10
# @date 2012-03-10
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2012
# Id: $Id$
# Revision: $Revision$
# Date: $Date$
# Author: $Author$
# HeadURL: $HeadURL$
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
package Cocoweb::Encode;
use Cocoweb;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use Data::Dumper;
use Term::ANSIColor;
use strict;
use warnings;

#__PACKAGE__->attributes('pathnames');

my %dememeMatch        = ();
my %shiftuMatch        = ();
my %demeleMatch        = ();
my $hasBeenInitialized = 0;

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->initializeTables()
      if !$hasBeenInitialized;
    return $instance;
}

##@method string dememe($numix)
#@param integer $numix
#@return string
sub dememe {
    my ( $self, $numix ) = @_;
    return '' if !exists $dememeMatch{$numix};
    return $dememeMatch{$numix};
}

##@method string demele($numix)
#@param integer $numix
#@param integer $wyb
#@return string
sub demele {
    my ( $self, $numix, $wyb ) = @_;
    return "\n" if $numix == 96 and $wyb < 0;
    return '' if !exists $demeleMatch{$numix};
    return $demeleMatch{$numix};
}

##@method string shiftu($numix)
#@param integer $numix
#@return string
sub shiftu {
    my ( $self, $numix ) = @_;
    return '' if !exists $shiftuMatch{$numix};
    return $shiftuMatch{$numix};
}

##@method void initializeTables()
#@brief Initializes hashed tables
sub initializeTables {
    my ($self) = @_;
    %dememeMatch = (
        32   => "~",
        33   => '!',
        36   => "*7",
        37   => "%",
        39   => "*8",
        40   => "(",
        41   => ")",
        42   => "*s",
        61   => "=",
        63   => "?",
        94   => "*l",
        95   => "*0",
        8364 => "*d",
        224  => "*a",    # à
        226  => "*k",    # â
        231  => "*c",    # ç
        232  => "*e",    # è
        233  => "*r",    # é
        234  => "*b",    # ê
        238  => "*i",    # î
        239  => "*k",    # ï
        244  => "*o",    # ô
        249  => "*f",    # ù
        251  => "*u"     # û
    );
    %shiftuMatch = (
        108 => '^',
        100 => '€',
        107 => 'â',
        97  => 'à',
        98  => 'ê',
        99  => 'ç',
        101 => 'è',
        114 => 'é',
        106 => 'ï',
        105 => 'î',
        111 => 'ô',
        117 => 'û',
        102 => 'ù',
        115 => '*',
        48  => '_',
        56  => "'",
        55  => '$'
    );

    %demeleMatch = (
        32  => ' ',
        33  => '!',
        36  => '$',
        37  => '%',
        38  => '{',
        40  => '(',
        41  => ')',
        42  => '*',
        61  => '=',
        63  => '?',
        96  => '',
        95  => '_',
        126 => ' '
    );
    $hasBeenInitialized = 1;
}

##@method string writo($s1)
#@param string $s1
#@return string
sub writo {
    my ( $self, $s1 ) = @_;
    utf8::decode($s1);
    my $s2     = '';
    my $toulon = 0;
    for ( my $i = 0 ; $i < length($s1) ; $i++ ) {
        my $c = substr( $s1, $i, 1 );
        my $numerox = ord($c);
        if ( $numerox != 32 ) {
            $toulon++;
        }
        else {
            $toulon = 0;
        }
        if ( $toulon < 24 ) {
            if (   $numerox < 43
                or ( $numerox > 59 and $numerox < 64 )
                or ( $numerox > 90 and $numerox < 96 )
                or $numerox > 122 )
            {
                $s2 .= $self->dememe($numerox);
            }
            else {
                $s2 .= $c;
            }
        }
    }
    return $s2;
}

#@method string transformix($sx, $tyb, $syx)
#@param string $sx A string to convert
#@param integer $tyb -1 or -23
#@param integer $syx
#@return string The string of characters converted
sub transformix {
    my ( $self, $sx, $tyb, $syx ) = @_;
    $tyb = -1 if !defined $tyb;
    $syx = 0  if !defined $syx;
    my $s1 = $sx;
    my ( $numerox, $shifto, $s2, $toolong, $unefoi ) = ( 0, 0, '', 0, 0 );
    $s1 =~ s{http://}{}g;
    my $mmj = index( $s1, 'www' );
    $toolong = -70 if $syx > 7 and $mmj > -1;

    for ( my $i = 0 ; $i < length($s1) ; $i++ ) {
        my $c = substr( $s1, $i, 1 );
        $numerox = ord($c);
        $toolong++ if $tyb != 23;
        $toolong = 0 if $numerox == 126 or $numerox == 32 or $tyb == 117;
        next if $toolong >= 27;
        if ( $shifto != 0 ) {
            $s2 .= $self->shiftu($numerox);
            $shifto = 0;
            next;
        }

        # The asterisk character announces an accented character
        if ( $numerox == 42 ) {
            $shifto = 1;
            next;
        }
        if (   ( $numerox < 43 )
            or ( ( $numerox > 58 ) and ( $numerox < 64 ) )
            or ( ( $numerox > 90 ) and ( $numerox < 97 ) )
            or ( $numerox > 122 ) )
        {

            # 59 = ';'
            if ( $numerox == 59 ) {
                my $resiz = ';';
                my $numoz = parseInt( substr( $i + 1, 2 ), 10 );

                #TODO: emoticons suppport
                warning("The support of smileys is not implemented");
                $s2 .= $resiz;
            }
            else {
                $s2 .= $self->demele( $numerox, $tyb );
            }

        }
        else {
            $s2 .= $c;
        }

    }
    return $s2;
}

1;
