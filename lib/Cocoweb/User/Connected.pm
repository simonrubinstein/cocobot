# @created 2012-01-26
# @date 2012-03-24
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
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
package Cocoweb::User::Connected;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use Cocoweb::User::Friend;
use base 'Cocoweb::User::Base';
my $nicknameMan;
my $nicknameWoman;

__PACKAGE__->attributes(
    #A zip code
    'zip',
    'speco',
    ## A unique account identifier, the first 9 digits of cookie "samedi"
    'myavatar',
    ## A account password: the last 20 alphabetic characters of cookie "samedi"
    'mypass',
    ## A password for current session associated with nikname ID (mynickID)
    'monpass',
    'mycrypt',
    'roulix',
    'sauvy',
    'inform',
    'cookav',
    'referenz',
    'cookies',
    ## The name of the city
    'townzz',
    'ifravatar',
    'amiz',
    'camon',
    'typcam'
);

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    if ( !defined $nicknameMan ) {
        $nicknameMan =
          Cocoweb::Config->instance()->getConfigFile( 'nickname-man.txt', 1 );
        $nicknameWoman =
          Cocoweb::Config->instance()->getConfigFile( 'nickname-woman.txt', 1 );
    }
    $args{'generateRandom'} = 0 if !exists $args{'generateRandom'};

    $args{'zip'} = 75001 if !exists $args{'zip'};
    if ( $args{'generateRandom'} ) {
        $args{'myage'} = randum(35) + 15 if !exists $args{'myage'};
        $args{'mysex'} = randum(2) + 1   if !exists $args{'mysex'};
        $args{'mynickname'} =
          $self->getRandomPseudonym( $args{'mysex'}, $args{'myage'},
            $args{'zip'} );
    }

    $args{'mynickname'} = 'nobody' if !exists $args{'mynickname'};
    $args{'myage'}      = 89       if !exists $args{'myage'};
    $args{'mysex'}      = 1        if !exists $args{'mysex'};
    $args{'myavatar'}   = 0        if !exists $args{'myavatar'};
    $args{'mypass'}     = 0        if !exists $args{'mypass'};
    $args{'cookav'} = floor( rand(890000000) + 100000000 )
      if !exists $args{'cookav'};

    $self->attributes_defaults(
        'mynickname' => $args{'mynickname'},
        'myage'      => $args{'myage'},
        'mysex'      => $args{'mysex'},
        'zip'        => $args{'zip'},
        'cookav'     => $args{'cookav'},
        'referenz'   => 0,
        'speco'      => 0,
        'mynickID'   => 99999,
        'mypass'     => $args{'mypass'},
        'monpass'    => 0,
        'mycrypt'    => 0,
        'roulix'     => 0,
        'sauvy'      => '',
        'inform'     => '',
        'cookies'    => {},
        'townzz'     => '',
        'citydio'    => 0,
        'myavatar'   => $args{'myavatar'},
        'ifravatar'  => 0,
        'mystat'     => 0,
        'myXP'       => 0,
        'myver'      => 0,
        'amiz'       => Cocoweb::User::Friend->new(),
        'camon'      => 95,
        'typcam'     => '',
        'infuzSting' => '',
        'infuz'      => {}

    );
    info(   'mynickname: '
          . $self->mynickname()
          . '; mysex: '
          . $args{'mysex'}
          . '; myage: '
          . $args{'myage'} );
}

##@method string getRandomPseudonym($sex)
#@brief Returns a random pseudonym
#@param integer $sex Pseudonym of sex: 1 if male or 2 if it is a woman
#@param integer $old
#@param integer $zip
#@return string A pseudonym
sub getRandomPseudonym {
    my ( $self, $sex, $old, $zip ) = @_;
    my $nickname;
    if ( $sex == 2 ) {
        $nickname = $nicknameWoman;
    }
    else {
        $nickname = $nicknameMan;
    }
    my $pseudonym = $nickname->getRandomLine();

    my $r = randum(11);
    if ( $r >= 0 and $r < 5 ) {
        $pseudonym = lc($pseudonym);
    }
    elsif ( $r == 6 and length($pseudonym) < 5 ) {
        $pseudonym = uc($pseudonym);
    }

    $r = randum(12);
    if ( $r == 0 ) {
        $r = randum(2);
        if ( $r == 1 ) {
            $pseudonym .= $old . 'ans';
        }
        else {
            $pseudonym .= $old . 'a';
        }
    }
    elsif ( $r == 1 ) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
          localtime(time);
        my $birthYear = $year - $old;
        $r = randum(2);
        if ( $r == 1 ) {
            $pseudonym .= $birthYear;
        }
        else {
            $pseudonym .= substr( $birthYear, 2, 2 );
        }
    }
    elsif ( $r == 2 ) {
        $r = randum(2);
        if ( $r == 1 ) {
            $pseudonym .= $zip;
        }
        else {
            $pseudonym .= substr( $zip, 0, 2 );
        }
    }
    return $pseudonym;
}

##@method void validatio($url)
#@brief
#@param string $url
sub validatio {
    my ( $self, $url ) = @_;
    my $nickidol = $self->mynickname();
    my $ageuq    = $self->myage();
    my $typum    = $self->mysex();
    my $citydio  = $self->zip();
    croak error("Error: bad nickidol value") if length($nickidol) < 3;
    croak error("Error: bad ageuq! ageuq = $ageuq") if $ageuq < 15;
    my $citygood = $citydio;
    $citygood = "0" x ( 5 - length($citygood) ) . $citygood
      if length($citygood) < 5;

    # Check if the login name does not contain too many capital letters
    my $sume = 0;
    for ( my $i = 0 ; $i < length($nickidol) ; $i++ ) {
        my $c = substr( $nickidol, $i, 1 );
        my $ujm = ord($c);
        $sume++ if $ujm < 95 and $ujm > 59;
    }
    if ( $sume > 4 ) {
        $nickidol = lc($nickidol);
        $self->mynickname($nickidol);
    }

    #    my $inform =
    #        $nickidol . '#'
    #      . $typum . '#'
    #      . $ageuq . '#'
    #      . $self->townzz() . '#'
    #      . $citygood . '#0#'
    #      . $self->cookav() . '#';
    #    $self->inform($inform);
    #
    #    $self->setCookie( 'coda', $inform );
    #
    #    $self->sauvy( $self->cookav() )
    #      if length( $self->sauvy() ) < 2;
    #
    #    my $location =
    #        $url . "#"
    #      . $nickidol . '#'
    #      . $typum . '#'
    #      . $ageuq . '#'
    #      . $citygood . '#0#'
    #      . $self->sauvy() . '#'
    #      . $self->referenz() . '#';
}

##@method void initial($url)
#@param string $url
sub initial {
    my ( $self, $url ) = @_;
    my ( $infor, $myavatar, $mypass ) =
      ( '', $self->myavatar(), $self->mypass() );

    #    my $cookie_ref = $self->getCookie('samedi');
    #    if ( defined $cookie_ref ) {
    #        $infor    = $cookie_ref->{'samedi'};
    #        $myavatar = substr( $infor, 0, 9 );
    #        $mypass   = substr( $infor, 9, 29 );
    #    }
    if (   !defined $myavatar
        or $myavatar !~ m{^\d+$}
        or $myavatar < 100000000
        or $myavatar > 1000000000 )
    {
        warning('The value of myavatar is not valid');
        $myavatar = randum(890000000) + 100000000;
    }

    debug("myavatar:$myavatar; mypass: $mypass");
    $self->myavatar($myavatar);
    $self->mypass($mypass);

    #    $infor = $myavatar . $mypass;
    #    $self->setCookie( 'samedi', $infor );
    $self->ifravatar( $url . $myavatar );
    info( 'ifravatar: ' . $self->ifravatar() );
}

##@method void setCookie($name, $value)
#@brief Initializes the value of a cookie.
#@value string $name cookie name
#@value string $value A value for the cookie
sub setCookie {
    my ( $self, $name, $value ) = @_;
    croak error('Error: Required parameter "name" is missing!')
      if !defined $name;
    croak error('Error: Required parameter "value" is missing!')
      if !defined $value;
    my $cookies_ref = $self->cookies();
    $cookies_ref->{$name} = $value;
}

##@method string getCookie($name)
#@brief Get the value of a cookie
#@param string $name cookie name
#@return string The string that matches the name of the cookie
#        or an undefined value if the cookie does not exist.
sub getCookie {
    my ( $self, $name ) = @_;
    croak error('Error: Required parameter "name" is missing!')
      if !defined $name;
    my $cookies_ref = $self->cookies();
    if ( exists $cookies_ref->{$name} ) {
        return $cookies_ref->{$name};
    }
    else {
        return;
    }
}

##@method void show()
#@brief Prints some member variables to the console of the user object
sub show {
    my $self  = shift;
    my @names = (
        'mynickname', 'myage',   'mysex',    'zip',
        'mynickID',   'monpass', 'myavatar', 'mypass',
        'townzz',     'citydio', 'mystat',   'myXP',
        'myver'
    );
    my $max = 1;
    foreach my $name (@names) {
        $max = length($name) if length($name) > $max;
    }
    $max++;
    foreach my $name (@names) {
        print STDOUT sprintf( '%-' . $max . 's ' . $self->$name(), $name . ':' )
          . "\n";
    }
    $self->showInfuz();
}

##@method void display()
#@brief Prints on one line some member variables to the console of the user object
sub display {
    my $self  = shift;
    my @names = (
        'mynickname', 'myage',   'mysex',    'zip',
        'mynickID',   'monpass', 'myavatar', 'mypass',
        'townzz',     'myver'
    );
    foreach my $name (@names) {
        print STDOUT $name . ':' . $self->$name() . '; ';
    }
    print STDOUT "\n";

}

1;
