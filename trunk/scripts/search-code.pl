#!/usr/bin/perl
# @created 2012-03-18
# @date 2012-03-18
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
my $CLI;
my $code;

init();
run();

##@method void run
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->process();
    $bot->display();
    my $user_ref = $bot->searchCode($code);
    print Dumper $user_ref;
    info("The $Bin script was completed successfully.");
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts('argumentative' => 'c:');
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $code = $opt_ref->{'c'} if exists $opt_ref->{'c'};
    if ( !defined $code ) {
        die error("You must specify a nickname code (-c option)");
    }
 
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Get the number of days left of Premium subscription.
Usage: 
 $Script [-v -d] -a myavatar -p mypass -c
  -c code     The nickname code searched, an alphanumeric code
              of three characters, i.e. WcL
  -a myavatar A unique identifier for your account 
              The first 9 digits of cookie "samedi"
  -p mypass   The password for your account
              The last 20 alphabetic characters of cookie "samedi"
  -v          Verbose mode
  -d          Debug mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2012-03-18) 
     Copyright (C) 2010-2012 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

