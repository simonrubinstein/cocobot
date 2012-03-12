# @created 2012-02-17
# @date 2012-03-12
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
use Data::Dumper;
use Carp;
use IO::File;
use POSIX;
use File::stat;
use Cocoweb::Logger;

our $VERSION   = '0.2001';
our $AUTHORITY = 'TEST';
our $isVerbose = 0;
our $isDebug   = 0;
my $logger;

use base 'Exporter';
our @EXPORT = qw(
  debug
  dumpToFile
  error
  fileToVars
  info
  message
  parseInt
  randum
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

##@method int parseInt($str, $radix)
#@brief Parses a string and returns an integer
#       Emulates the JavaScript function parseInt
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

##@method dumpToFile($vars, $filename)
sub dumpToFile {
    my ( $vars, $filename ) = @_;
    $Data::Dumper::Purity = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse  = 1;
    my $fh;
    die error("open($filename) was failed: $!") if !open( $fh, '>', $filename );
    print $fh Dumper $vars;
    die error("open($filename) was failed: $!") if !close($fh);
}

##@method fileToVars($filename)
sub fileToVars {
    my ($filename) = @_;
    my $stat = stat($filename);
    die error("stat($filename) was failed: $!") if !defined $stat;
    my $fh;
    die error("open($filename) was failed: $!") if !open( $fh, '<', $filename );
    my ( $contentSize, $content ) = ( 0, '' );
    sysread( $fh, $content, $stat->size(), $contentSize );
    close $fh;
    my $vars = eval($content);
    die error($@) if $@;
    return $vars;
}

##@method void BEGIN()
sub BEGIN {
    $logger = Cocoweb::Logger->instance();
}
1;
