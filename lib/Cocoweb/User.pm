# @created 2012-01-26
# @date 2012-02-19
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

use base 'Cocoweb::Object';

__PACKAGE__->attributes(
    'pseudonym',
    'year',
    'sex',
    'zip',
    'cookav',
    'referenz',
    'speco',
    'nickId',
    'password',
    'roulix',
    'sauvy',
    'inform',
    'cookies',
    'townzz',
    'citydio'

);

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;

    $args{'generateRandom'} = 0 if !exists $args{'generateRandom'};

    if ( $args{'generateRandom'} ) {
        $args{'year'} = randum(35) + 15 if !exists $args{'year'};
        $args{'sex'}  = randum(2) + 1   if !exists $args{'sex'};
    }

    $args{'pseudonym'} = 'nobody' if !exists $args{'pseudonym'};
    $args{'year'}      = 89       if !exists $args{'year'};
    $args{'sex'}       = 1        if !exists $args{'sex'};
    $args{'zip'}       = 75001    if !exists $args{'zip'};

    $self->attributes_defaults(
        'pseudonym' => $args{'pseudonym'},
        'year'      => $args{'year'},
        'sex'       => $args{'sex'},
        'zip'       => $args{'zip'},
        'cookav'    => floor( rand(890000000) + 100000000 ),
        'referenz'  => 0,
        'speco'     => 0,
        'nickId'    => 99999,
        'password'  => 0,
        'roulix'    => 0,
        'sauvy'     => '',
        'inform'    => '',
        'cookies'   => {},
        'citydio'   => 0
    );
}

## @method void validatio($user_ref)
sub validatio {
    my ($self)   = @_;
    my $nickidol = $self->pseudonym();
    my $ageuq    = $self->year();
    my $typum    = $self->sex();
    my $citydio  = $self->zip();
    croak error("bad nickidol value") if length($nickidol) < 3;
    croak error("bad ageuq! ageuq = $ageuq") if $ageuq < 15;
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
        $self->pseudonym($nickidol);
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

    #$user_ref->{'cookies'}->{'coda'} = $inform;

    $self->sauvy() = $self->cookav()
      if length( $self->sauvy() ) < 2;

    #my $location =
    #    $coco_ref->{'urlprinc'} . "#"
    #  . $nickidol . '#'
    #  . $typum . '#'
    #  . $ageuq . '#'
    #  . $citygood . '#0#'
    #  . $user_ref->{'sauvy'} . '#'
    #  . $user_ref->{'referenz'} . '#';
    #debug("location: $location");
}

sub show {
    my $self = shift;
    print STDOUT 'pseudonym: ' . $self->pseudonym . "\n";
    print STDOUT 'year:      ' . $self->year . "\n";
    print STDOUT 'sexe:      ' . $self->sex . "\n";
    print STDOUT 'zip:       ' . $self->zip . "\n";
    print STDOUT 'nickId:    ' . $self->nickId . "\n";
    print STDOUT 'password:  ' . $self->password . "\n";

}

1;
