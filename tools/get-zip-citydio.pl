#!/usr/bin/perl
# @brief
# @created 2012-11-14
# @date 2016-06-18 
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
#
# copyright (c) Simon Rubinstein 2010-2016
# Id$
# Revision: $Revisio$
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
use IO::File;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::File;
use Cocoweb::CLI;
my $CLI;
my $req;

init();
run();

##@method void run()
sub run {
    my $filename = '/tmp/zip-codes.txt';
    my $fh = IO::File->new( $filename, 'w' );
    die error("open($filename) was failed: $!") if !defined $fh;
    foreach (my $zipCode = 0; $zipCode < 100000 ; $zipCode++) { 
        my $cityco;
        eval { 
            $cityco = $req->getCityco($zipCode);
        };
        next if $@;
        print $fh $zipCode . ' ' . $cityco. "\n";
    }
    die error("close($filename) was failed: $!") if !$fh->close();
    info("The $Bin script was completed successfully.");
    info("$filename file has been generated");
}

 ##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $req = Cocoweb::Request->new();
    
}

##@method void HELP_MESSAGE()
#@brief Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Fetch all 'citydio' codes from the Coco.fr website.
Used to generate "conf/zip-codes.txt" file
i.e.: http://www.coco.fr/cocoland/75015.js URL return "var cityco='30929*PARIS*';" 
Usage: 
 $Script [-v -d]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-06-18');
}

