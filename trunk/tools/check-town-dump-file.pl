#!/usr/bin/perl
# @brief This script checks that the town codes froms '_townCount.pl'
#        file exist in the file 'towns.txt'.
# @created 2012-03-11
# @date 2012-03-15
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
use strict;
use warnings;
use FindBin qw($Script $Bin);
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::DB;
my $CLI;
my $DB;

init();
run();

##@method void run()
sub run {
    my ( $town_ref, $townConf ) = $DB->getInitTowns();
    my $townCount_ref = fileToVars('_townCount.pl');
    my ( $count, $found, $notFound ) = ( 0, 0, 0 );
    foreach my $town ( sort keys %$townCount_ref ) {
        $count++;
        if ( exists $town_ref->{$town} ) {
            $found++;
            next;
        }
        message( $town . ' => ' . $townCount_ref->{$town} );
        $notFound++;
    }
    message( 'Number of town code(s) found: ' . $found );
    message( 'Number of town code(s) not found: ' . $notFound );
    info("The $Bin script was completed successfully.");
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    $DB  = Cocoweb::DB->instance();
    my $opt_ref = $CLI->getMinimumOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
This script checks that the town codes froms '_townCount.pl' file
exist in the file 'towns.txt'.
Usage: 
 $Script [-v -d]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2012-03-15) 
     Copyright (C) 2010-2012 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

