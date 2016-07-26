# @created 2012-02-18
# @date 2016-07-26
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
package Cocoweb::Config::Base;
use strict;
use warnings;
use Cocoweb;
use Carp;
use Data::Dumper;
use base 'Cocoweb::Object';

## @method hashref getHash($key)
sub getHash {
    my ( $self, $key ) = @_;
    $self->isHash($key);
    return $self->all()->{$key};
}

## @method void isHash($key)
sub isHash {
    my ( $self, $key ) = @_;
    my $hash = $self->all();
    croak error("$key hash not found or wrong")
        if ( !exists $hash->{$key} or ref $hash->{$key} ne 'HASH' );
}

## @method string getString($key)
sub getString {
    my ( $self, $key ) = @_;
    $self->isString($key);
    return $self->all()->{$key};
}

## @method void isString($key)
sub isString {
    my ( $self, $key ) = @_;
    my $hash = $self->all();
    croak error("$key string not found or wrong")
        if ( !exists $hash->{$key} or $hash->{$key} !~ m{^.+$}m );
}

## @method string getRegex($key)
sub getRegex {
    my ( $self, $key ) = @_;
    my $str = $self->getString($key);
    return qr/$str/;
}

## @method interger getInt($key)
sub getInt {
    my ( $self, $key ) = @_;
    $self->isInt($key);
    return $self->all()->{$key};
}

## @method void isInt($key)
sub isInt {
    my ( $self, $key ) = @_;
    my $hash = $self->all();
    croak error("$key integer not found or wrong")
        if ( !exists $hash->{$key} or $hash->{$key} !~ m{^\d+$} );
    return $hash->{$key};
}

##@method bool getBool($key)
sub getBool {
    my ( $self, $key ) = @_;
    my $hash = $self->all();
    croak error("$key boolean not found or wrong")
        if ( !exists $hash->{$key} );
    if ( $hash->{$key} =~ m{^(1|true)$}i ) {
        return 1;
    }
    elsif ( $hash->{$key} =~ m{^(0|false)$}i ) {
        return 0;
    }
    else {
        croak error("$key boolean value is wrong");
    }
}

## @method arrayref getArray($key)
sub getArray {
    my ( $self, $key ) = @_;
    my $hash = $self->all();
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
        $array_ref = [ $hash->{$key} ];
    }
    return $array_ref;
}

1;
