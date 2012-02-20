# @created 2012-02-17
# @date 2012-02-20
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
package Cocoweb;

use strict;
use warnings;
use Carp;
use Cocoweb::Logger;
use POSIX;

our $VERSION   = '0.2000';
our $AUTHORITY = 'TEST';
my $logger;

use base 'Exporter';
our @EXPORT = qw(
  error
  debug
  info
  message
  randum
  parseInt
);

sub info {
    $logger->info(@_);
}

sub message {
    $logger->message(@_);
}

sub error {
    $logger->error(@_);
}

sub debug {
    $logger->debug(@_);
}

##@method integer randum($qxq)
sub randum {
    my ($qxq) = @_;
    return floor( rand($qxq) );
}

## @method int parseInt($str, $radix)
# @author Father Chrysostomo
sub parseInt {
    my ( $str, $radix ) = @_;
    $str = 'undefined' if !defined $str;
    my $sign =
      $str =~ s/^([+-])//
      ? ( -1, 1 )[ $1 eq '+' ]
      : 1;
    $radix = ( int $radix ) % 2**32;
    $radix -= 2**32 if $radix >= 2**31;
    $radix ||=
      $str =~ /^0x/i
      ? 16
      : 10;
    $radix == 16
      and $str =~ s/^0x//i;

    return if $radix < 2 || $radix > 36;

    my @digits = ( 0 .. 9, 'a' .. 'z' )[ 0 .. $radix - 1 ];
    my $digits = join '', @digits;
    $str =~ /^([$digits]*)/i;
    $str = $1;

    my $ret;
    if ( !length $str ) {
        $ret = 'nan';
    }
    elsif ( $radix == 10 ) {
        $ret = $sign * $str;
    }
    elsif ( $radix == 16 ) {
        $ret = $sign * hex $str;
    }
    elsif ( $radix == 8 ) {
        $ret = $sign * oct $str;
    }
    elsif ( $radix == 2 ) {
        $ret = $sign * eval "0b$str";
    }
    else {
        my ( $num, $place );
        for ( reverse split //, $str ) {
            $num += (
                  $_ =~ /[0-9]/
                ? $_
                : ord(uc) - 55
            ) * $radix**$place++;
        }
        $ret = $num * $sign;
    }
    return $ret;
}



sub BEGIN {
    $logger = Cocoweb::Logger->instance();
}

1;
