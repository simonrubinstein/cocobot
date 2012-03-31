# @created 2012-02-17
# @date 2012-03-30
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
package Cocoweb;
use strict;
use warnings;
use Carp;
use FindBin qw($Script $Bin);
use Data::Dumper;
use POSIX;
use Storable;
use Cocoweb::Logger;
our $VERSION   = '0.2001';
our $AUTHORITY = 'TEST';
our $isVerbose = 0;
our $isDebug   = 0;
my $logger;
my $startTime;

use base 'Exporter';
our @EXPORT = qw(
  debug
  error
  indexOf
  info
  message
  parseInt
  substring
  randum
  trim
  warning
);

##@method void info(@_)
sub info {
    return if !$isVerbose;
    $logger->info(@_);
}

##@method void message(@_)
sub message {
    $logger->message(@_);
}

##@method void error(@_)
sub error {
    $logger->error(@_);
}

##@method void warning(@_)
sub warning {
    $logger->warning(@_);
}

##@method void debug(@_)
sub debug {
    return if !$isDebug;
    $logger->debug(@_);
}

##@method integer randum($qxq)
#@brief Generates a random integer
#@param integer $qxq
#@return integer An integer randomly generated.
sub randum {
    my ($qxq) = @_;
    return floor( rand($qxq) );
}

##@method string trim($str)
#@brief Strip whitespace from the beginning and end of a string
#@param string $str The string that will be trimmed
#@return string The trimmed string
sub trim {
    my ($str) = @_;
    $str =~ s{^\s+}{};
    $str =~ s{\s+$}{};
    return $str;
}

##@method int parseInt($str, $radix)
#@brief Parses a string and returns an integer
#       Emulates the JavaScript function parseInt()
#@param string $str Required. The string to be parsed
#@param $radix Optional. A number (from 2 to 36) that represents the
#              numeral system to be used
# @author Father Chrysostomo
sub parseInt {
    my ( $str, $radix ) = @_;
    $str   = 'undefined' if !defined $str;
    $radix = 10          if !defined $radix;
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

##@method string indexOf($string, $searchString, $start)
#@brief Returns the position of the first occurrence
#       of a specified value in a string
#       Emulates the JavaScript function indexOf()
#@param string $searchstring Required. The string to search for
#@param strint $start       Optional. The start position in the string
#                           to start the search. If omitted, the search
#                           starts from position 0
#@return integer the position of the first occurrence
#                or -1 if the value to search for never occurs.
sub indexOf {
    my ( $string, $searchString, $start ) = @_;
    $start = 0 if !defined $start;
    return index( $string, $searchString ) if $start == 0;
    my $substing = substr( $string, $start );
    return
      index( $substing, $searchString ) + length($string) - length($substing);
}

##@method string substring($string, $from, $to)
#@brief Extracts the characters in a string between $from and $to,
#       not including $to itself
#       Emulates the JavaScript function substring()
#@return string The characters extracted
sub substring {
    my ( $string, $from, $to ) = @_;
    $to = 0 if !defined $to;
    return substr( $string, $from ) if $to == 0;
    if ( $to < $from ) {

        # swap variables
        $from += $to;
        $to   = $from - $to;
        $from = $from - $to;
    }
    return substr( $string, $from, $to - $from );
}

##@method void BEGIN()
sub BEGIN {
    $startTime = time;
    my $include = $Bin;
    $include =~ s{/[^/]+$}{/lib};
    push @INC, $include if -d $include;
    $logger = Cocoweb::Logger->instance();
}

sub END {
    message("execution time: " . (time - $startTime) . ' seconds');

}




1;
