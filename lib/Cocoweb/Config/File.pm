# @created 2012-02-17
# @date 2012-02-17
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# $Id$
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
package Cocoweb::Config::File;
use strict;
use warnings;
use Cocoweb;
use Carp;
use Data::Dumper;
use Config::General;

use base 'Cocoweb::Object';

__PACKAGE__->attributes( 'all', 'pathname' );

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults( 'pathname' => $args{'pathname'} );
    my %config = Config::General->new(
        -ConfigFile => $self->pathname,
        -CComments  => 'off'
    )->getall();
    croak error("'conf' section was not found!") if !exists $config{'conf'};
    $self->all( $config{'conf'} );

    #print Dumper \%config;
}

## @method hashref getHash($hashref, $key)
sub getHash {
    my ( $self, $key, $hash ) = @_;
    $hash = $self->all() if !defined $hash;
    croak error("$key hash not found or wrong")
      if ( !exists $hash->{$key} or ref $hash->{$key} ne 'HASH' );
    return $hash->{$key};
}

## @method string getString($hashref, $key)
sub getString {
    my ( $self, $key, $hash ) = @_;
    $hash = $self->all() if !defined $hash;
    print Dumper $hash;
    croak error("$key string not found or wrong")
      if ( !exists $hash->{$key} or $hash->{$key} !~ m{^.+$}m );
    return $hash->{$key};
}

## @method interger getInt($hashref, $key)
sub getInt {
    my ( $self, $key, $hash ) = @_;
    $hash = $self->all() if !defined $hash;
    croak error("$key integer not found or wrong")
      if ( !exists $hash->{$key} or $hash->{$key} !~ m{^\d+$} );
    return $hash->{$key};
}

## @method arrayref getArray($hashref, $key)
sub getArray {
    my ( $self, $key, $hash ) = @_;
    $hash = $self->all() if !defined $hash;
    croak error("$key was not found")
      if !exists $hash->{$key};
    my $r = ref $hash->{$key};
    my $array_ref;
    if ( $r eq 'ARRAY' ) {
        $array_ref = $hash->{$key};
    }
    elsif ( $r eq '' ) {
        $array_ref = [ $hash->{$key} ];
    }
    else {
        croak error("$key is wrong");
    }
    return $array_ref;
}

1;
