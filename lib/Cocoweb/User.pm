# @created 2012-01-26
# @date 2012-02-27
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
package Cocoweb::User;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use base 'Cocoweb::Object';
my $nicknameMan;
my $nicknameWoman;

__PACKAGE__->attributes(
    'mynickname',
    'myage',
    'mysex',
    'zip',
    'cookav',
    'referenz',
    'speco',
    'mynickID',
    'mypass',

    #
    'monpass',
    'mycrypt',
    'roulix',
    'sauvy',
    'inform',
    'cookies',
    'townzz',
    'citydio',
    'myavatar',
    'ifravatar'

);

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    if ( !defined $nicknameMan ) {
        $nicknameMan =
          Cocoweb::Config->instance()->getConfigFile( 'nickname-man.txt', 1 );
        $nicknameWoman =
          Cocoweb::Config->instance()->getConfigFile( 'nickname-woman.txt', 1 );
    }
    $args{'generateRandom'} = 0 if !exists $args{'generateRandom'};

    if ( $args{'generateRandom'} ) {
        $args{'myage'} = randum(35) + 15 if !exists $args{'myage'};
        $args{'mysex'} = randum(2) + 1   if !exists $args{'mysex'};
        $args{'mynickname'} = $self->getRandomPseudonym( $args{'mysex'} );
    }

    $args{'mynickname'} = 'nobody' if !exists $args{'mynickname'};
    $args{'myage'}      = 89       if !exists $args{'myage'};
    $args{'mysex'}      = 1        if !exists $args{'mysex'};
    $args{'zip'}        = 75001    if !exists $args{'zip'};
    $args{'myavatar'}   = 0        if !exists $args{'myavatar'};
    $args{'mypass'}     = 0        if !exists $args{'mypass'};

    $self->attributes_defaults(
        'mynickname' => $args{'mynickname'},
        'myage'      => $args{'myage'},
        'mysex'      => $args{'mysex'},
        'zip'        => $args{'zip'},
        'cookav'     => floor( rand(890000000) + 100000000 ),
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
        'citydio'    => 0,
        'myavatar'   => $args{'myavatar'},
        'ifravatar'  => 0
    );
    info(   'mynickname: '
          . $self->mynickname()
          . '; mysex: '
          . $args{'mysex'}
          . '; myage: '
          . $args{'myage'} );
}

sub getRandomPseudonym {
    my ( $self, $sex ) = @_;
    my $nickname;
    if ( $sex == 2 ) {
        $nickname = $nicknameWoman;
    }
    else {
        $nickname = $nicknameMan;
    }
    my $pseudonym = $nickname->getRandomLine();

    return $pseudonym;
}

## @method void validatio($user_ref)
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
        $sume++ if $ujm < 95 && $ujm > 59;
    }
    if ( $sume > 4 ) {
        $nickidol = lc($nickidol);
        $self->mynickname($nickidol);
    }
    my $cookav;
    my $inform =
        $nickidol . '#' 
      . $typum . '#' 
      . $ageuq . '#'
      . $self->townzz() . '#'
      . $citygood . '#0#'
      . $self->cookav() . '#';
    debug("$inform");
    $self->inform($inform);

    $self->setCookie( 'coda', $inform );

    $self->sauvy( $self->cookav() )
      if length( $self->sauvy() ) < 2;

    my $location =
        $url . "#"
      . $nickidol . '#'
      . $typum . '#'
      . $ageuq . '#'
      . $citygood . '#0#'
      . $self->sauvy() . '#'
      . $self->referenz() . '#';
    debug("location: $location");
}

## @method void initial()
sub initial {
    my ( $self, $url ) = @_;
    my ( $infor, $myavatar, $mypass ) =
      ( '', $self->myavatar(), $self->mypass() );
    debug("1> myavatar:$myavatar; mypass: $mypass");
    my $cookie_ref = $self->getCookie('samedi');
    if ( defined $cookie_ref ) {
        $infor    = $cookie_ref->{'samedi'};
        $myavatar = substr( $infor, 0, 9 );
        $mypass   = substr( $infor, 9, 29 );
    }
    debug("2> myavatar:$myavatar; mypass: $mypass");
    $myavatar = randum(890000000) + 100000000
      if ( !defined $myavatar
        or $myavatar !~ m{^\d+$}
        or $myavatar < 100000000
        or $myavatar > 1000000000 );

    debug("3> myavatar:$myavatar; mypass: $mypass");
    $self->myavatar($myavatar);
    $self->mypass($mypass);
    $infor = $myavatar . $mypass;
    $self->setCookie( 'samedi', $infor );
    $self->ifravatar( $url . $myavatar );
    info( 'ifravatar: ' . $self->ifravatar() );
}

## @method void setCookie($name, $value)
#@brief
#@value string $name Cookie name
#@value string $value
sub setCookie {
    my ( $self, $name, $value ) = @_;
    croak error('Error: Required parameter "name" is missing!')
      if !defined $name;
    croak error('Error: Required parameter "value" is missing!')
      if !defined $value;
    my $cookies_ref = $self->cookies();
    $cookies_ref->{$name} = $value;
}

##@method void getCookie($name)
#@value string $name Cookie name
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

sub show {
    my $self = shift;
    print STDOUT 'mynickname:' . $self->mynickname . "\n";
    print STDOUT 'myage:     ' . $self->myage . "\n";
    print STDOUT 'mysex:     ' . $self->mysex . "\n";
    print STDOUT 'zip:       ' . $self->zip . "\n";
    print STDOUT 'mynickID:  ' . $self->mynickID . "\n";
    print STDOUT 'mypass:    ' . $self->mypass . "\n";
    print STDOUT 'townzz:    ' . $self->townzz . "\n";
    print STDOUT 'citydio:   ' . $self->citydio . "\n";
    print Dumper $self->cookies();
}

1;
