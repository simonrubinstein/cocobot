# @brief Handle character encoding specific to Coco.fr chat
# @created 2012-03-10
# @date 2018-08-06 
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2018
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

my @tabsmil            = ();
my %dememeMatch        = ();
my %shiftuMatch        = ();
my %demeleMatch        = ();
my $hasBeenInitialized = 0;
my @doc                = ();
#FIXME: to move into configuration file
my $base               = 'http://www.coco.fr/';
my $urlphoto           = 'http://pix1.coco.fr/';
my $soundip            = '149.202.31.184';

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
        32   => "_",
        33   => '*x',
        34   => "*8",
        36   => "*7",
        37   => "*g",
        39   => "*8",
        40   => "(",
        41   => ")",
        42   => "*s",
        61   => "*h",
        63   => "=",
        64   => "*m",
        94   => "*l",
        95   => "*0",
        164  => "*0",
        8364 => "*d",
        224  => "*a",    # à
        226  => "*k",    # â
        231  => "*c",    # ç
        232  => "*e",    # è
        233  => "*r",    # é
        234  => "*b",    # ê
        238  => "*i",    # î
        239  => "*j",    # ï
        244  => "*o",    # ô
        249  => "*f",    # ù
        251  => "*u",    # û
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
        109 => '@',
        111 => 'ô',
        117 => 'û',
        102 => 'ù',
        103 => '%',
        104 => '=',
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
        61  => '?',
        63  => '?',
        96  => '',
        95  => ' ',
        126 => ' ',
        124 => 'y'
    );

    @tabsmil = (
        '{RIGOLE}',   '{TRISTE}',   '{CLIN}',    '{ECLAT}',
        '{ETONNE}',   '{CONFUS}',   '{ROUGI}',   '{DUBITATIF}',
        '{FATIGUE}',  '{PERPLEXE}', '{LANGUE}',  '{COEUR}',
        '{AMOUR}',    '{CRY}',      '{CLASSE}',  '{ROSE}',
        '{ENERVE}',   '{UP}',       '{DOWN}',    '{KISS}',
        '{ANGRY}',    '{ANGE}',     '{DIABLE}',  '{CROSS}',
        '{ILL}',      '{NA}',       '{OH}',      '{MAL}',
        '{EMU}',      '{SHIT}',     '{FUCK}',    '{NOWORD}',
        '{DROOL}',    '{AOH}',      '{DIABLO}',  '{SIFFLE}',
        '{SONGE}',    '{CONTENT}',  '{ENBIAIS}', '{CIRCON}',
        '{VICTOIRE}', '{MOUAIS}',   '{AA}',      '{CLOPE}',
        '{TOUCHE}',   '{BAFFE}',    '{SLEEP}',   '{ANNIF}',
        '{DECU}',     '{MMH}',      '{QUOI}',    '{ARGH}',
        '{EUH}',      '{OUF}',      '{OUPS}',    '{SECRET}'
    );

    my $rku = 0;
    for ( my $i = 0; $i < 62; $i++ ) {
        if ( $i > 51 ) {
            $rku = -69;
        }
        elsif ( $i > 25 ) {
            $rku = 6;
        }
        $doc[$i] = 65 + $i + $rku;
    }
    my @coul3 = ( 43, 47, 61 );
    push @doc, @coul3;
    $self->applye( \@doc );
    $hasBeenInitialized = 1;
}

sub applye {
    my ( $self, $rgr_ref ) = @_;
    for ( my $i = 0; $i < 10; $i++ ) {
        my $fjz = $rgr_ref->[ $i + 20 ];
        $rgr_ref->[ $i + 20 ] = $rgr_ref->[ $i + 30 ];
        $rgr_ref->[ $i + 30 ] = $fjz;
    }
}

sub enxo {
    my ( $self, $n, $y, $z ) = @_;
    debug("$n, $y, $z");
    my $o = '';
    my ( $chr1, $chr2, $chr3 ) = ( '', '', '' );
    my @enc  = [];
    my @revo = [];
    for ( my $i = 0; $i < 65; $i++ ) {
        $revo[ $doc[$i] ] = $i;
    }
    my $i = 0;
    if ( $z == 1 ) {
        do {
            for ( my $j = 0; $j < 4; $j++ ) {
                $enc[$j] = $revo[ charCodeAt( $n, $i++ ) ];
            }
            $chr1 = ( $enc[0] << 2 ) | ( $enc[1] >> 4 );
            $chr2 = ( ( $enc[1] & 15 ) << 4 ) | ( $enc[2] >> 2 );
            $chr3 = ( ( $enc[2] & 3 ) << 6 ) | $enc[3];
            $o = $o . chr($chr1);
            $o = $o . chr($chr2) if $enc[2] ne 64;
            $o = $o . chr($chr3) if $enc[3] ne 64;
        } while ( $i < length($n) );
        $n = $o;
    }
    my $result = '';
    for ( my $i = 0; $i < length($n); ++$i ) {
        $result
            .= chr(
            ord( substr( $y, $i % length($y), 1 ) ) ^
                ord( substr( $n, $i, 1 ) ) );
    }
    if ( $z == 1 ) {
        $o = $result;
    }

    $i = 0;
    if ( $z == 0 ) {
        $n = $result;
        do {
            my $chr1 = charCodeAt( $n, $i++ );
            my $chr2 = charCodeAt( $n, $i++ );
            my $chr3 = charCodeAt( $n, $i++ );
            $chr2 = 0 if !defined $chr2;
            $enc[0] = $chr1 >> 2;
            $enc[1] = ( ( $chr1 & 3 ) << 4 ) | ( $chr2 >> 4 );
            $enc[2] = ( ( $chr2 & 15 ) << 2 );
            if ( defined $chr3 ) {
                $enc[2] = $enc[2] | ( $chr3 >> 6 );
                $enc[3] = $chr3 & 63;
            }
            if ( !isNumeric($chr2) ) {
                $enc[2] = $enc[3] = 64;
            }
            elsif ( !isNumeric($chr3) ) {
                $enc[3] = 64;
            }
            for ( my $j = 0; $j < 4; $j++ ) {
                $o .= chr( $doc[ $enc[$j] ] );
            }
        } while ( $i < length($n) );
    }
    return $o;
}

##@method string writo($s1)
#@param string $s1
#@return string
sub writo {
    my ( $self, $s1 ) = @_;
    utf8::decode($s1);
    my $s2     = '';
    my $toulon = 0;
    for ( my $i = 0; $i < length($s1); $i++ ) {
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

#@method string transformix($sx, $tyb, $syx, $stt)
#@param string $sx A string to convert
#@param integer $tyb -1 or -23
#@param integer $syx
#@param integer $stt
#@return string The string of characters converted
sub transformix {
    my ( $self, $sx, $tyb, $syx, $stt ) = @_;
    debug("sx: $sx");
    $tyb = -1 if !defined $tyb;
    $syx = 0  if !defined $syx;
    $stt = 0  if !defined $stt;
    my $s1 = $sx;
    my ( $numerox, $shifto, $s2, $toolong, $unefoi ) = ( 0, 0, '', 0, 0 );
    $s1 =~ s{http://}{}g;
    my $mmj = index( $s1, 'www' );
    $toolong = -90 if $stt > 5 and $mmj > -1;

    for ( my $i = 0; $i < length($s1); $i++ ) {
        my $c = substr( $s1, $i, 1 );
        $numerox = ord($c);
        $toolong++ if $tyb != 23;
        $toolong = 0 if $numerox == 95 or $numerox == 32 or $tyb == 117;
        next if $toolong >= 27;
        if ( $shifto != 0 ) {
            $s2 .= $self->shiftu($numerox);
            $shifto = 0;
            next;
        }

        # The asterisk character announces a no ASCII char
        if ( $numerox == 42 ) {
            $shifto = 1;
            next;
        }
        if (   ( $numerox < 43 )
            or ( ( $numerox > 58 ) and ( $numerox < 64 ) )
            or ( ( $numerox > 90 ) and ( $numerox < 97 ) )
            or ( $numerox > 122 ) )
        {

            # 59 = ';' : emoticon
            if ( $numerox == 59 ) {
                my $resiz = ';';
                my $numoz = parseInt( substring( $s1, $i + 1, $i + 3 ), 10 );
                if ( $numoz < scalar(@tabsmil) and $numoz > -1 ) {
                    $s2 .= $tabsmil[$numoz];
                    $i += 2;
                }
                else {
                    $s2 .= $resiz;
                }
            }
            else {
                $s2 .= $self->demele( $numerox, $tyb );
            }
        }
        else {
            $s2 .= $c;
        }

    }

    #$s2 = transmiley($s2) if $tyb != 117;
    if ( $mmj > -1 ) {
    }
    else {
        my $hwo = indexOf( $s1, '!' );
        if ( $hwo > -1 ) {
            my $tr8 = substring( $s2, $hwo + 1, $hwo + 2 );
            my $tr9 = substring( $s1, $hwo + 2 );
            for ( my $i = 0; $i < length($tr9); $i++ ) {
                my $c = substr( $tr9, $i, 1 );
                $numerox = ord($c);
                $tr8     = 'FALSE'
                    if $numerox < 45
                    or ( $numerox > 57 and $numerox < 65 )
                    or ( $numerox > 90 and $numerox < 95 )
                    or $numerox > 122
                    or $numerox == 96;
            }
            if ( indexOf( $tr9, '*' ) == -1 ) {
                my $tt3 = $tr9;
                my $sqm;
                if ( $tr8 eq '1' ) {
                    if ( $tyb > 199 and $tyb < 999 ) {
                        $sqm = 1;
                    }
                    else {
                        $sqm = 0;
                    }
                    #$sqm = "2" if $contor > 2;
                    $s2 = $base . 'pub/photo' . $sqm . '.htm?' . $tr9;
                } elsif ( $tr8 eq '2' ) {
                    $s2 = 'mp3.html?' . $tr9;
                }
                elsif ( $tr8 eq '3' ) {
                    if ( $tyb > 1000 ) {
                        $s2 = $urlphoto + 'photo/' . $tr9 if $tyb > 1000;
                    } else {
                        $s2 = 'err-bmp';
                    }
                }
                elsif ( $tr8 eq '5' ) {
                    $s2 = 'mic.html?' . $tr9 . $soundip
                        if $tyb > 1000 and $syx > 3;
                }
                elsif ( $tr8 eq '7' ) {
                    if ( $tyb > 1000 ) {
                        if ( ord( substr( $tr9, 0, 1 ) ) > 60 ) {
                            $s2 = 'webcam:' . $tr9;
                        }
                        else {
                            $s2 = 'arnaque';
                        }
                    }
                }
                elsif ( $tr8 eq 'a' ) {
                    $s2 = 'video.html?daily' . $tr9;
                }
                elsif ( $tr8 eq 'b' ) {
                    $s2 = 'video.html?yout' . $tr9;
                }
            }
        }
    }

    return $s2;
}

1;
