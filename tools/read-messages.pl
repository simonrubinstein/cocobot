#!/usr/bin/perl
# @created 2013-11-11 
# @date 2013-11-11
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2013
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
use strict;
use warnings;
use FindBin qw($Script $Bin);
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
my $CLI;
my $myTime;
my $messagePath;
my $alertMessagePath;

init();
run();


sub run {
    my $fh = IO::File->new( $messagePath, 'r' );
    die error("open($messagePath) was failed: $!")
      if !defined $fh;
    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        if ($line !~m{^(\d{2}):(\d{2}):(\d{2})
            \s+([A-Za-z0-9]{3})?
            \s+town:\s([A-Z]{2}-\s[A-Za-z-\s]*)?
            \s+ISP:\s([A-Za-z-\s\.]+)
            \s+sex:\s(\d)
            \s+age:\s(\d{2})
            \s+nick:\s([0-9A-Za-z]+)
            \s+:\s(.*)$}xms) {
            die "bad  $line";
        }
        my ($h, $m, $s) = ($1, $2, $3);
        my ($code, $town, $ISP, $mysex, $myage,  $mynickname, $message) = ($4, $5, $6, $7, $8, $9, $10);
        $town  = '' if !defined $town;
        $code  =  '' if !defined $code;
        $ISP   = '' if !defined $code; 
        my $str = sprintf(
          '%3s town: %-26s ISP: %-27s sex: %1s age: %2s nick: %-19s: '
          . $message, $code,  $town,  $ISP, $mysex, $myage, $mynickname);

 
    
        print $line . "\n";
        print "$h:$m:$s $str\n\n";
    }
    close $fh;
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $myTime = time if !defined $myTime;
    (undef, $messagePath) = getLogPathname('messages', 'save-logged-user-in-database.pl', $myTime);
    (undef, $alertMessagePath) = getLogPathname('messages', 'save-logged-user-in-database.pl', $myTime);
    debug("message path: $messagePath; alert message pat: $alertMessagePath\n");
    
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Usage: 
 $Script [-v -d ]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2013-11-11');
}

