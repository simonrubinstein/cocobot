#!/usr/bin/perl
# @created 2012-03-23
# @date 2012-03-23
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
use Data::Dumper;
use FindBin qw($Script $Bin);
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
my $CLI;
my $maxOfLoop = 1;

init();
run();

##@method void run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->process();
    $bot->display();
    for ( my $i = 0 ; $i < $maxOfLoop ; $i++ ) {
        $bot->lancetimer();
        $bot->isDead( $CLI->searchId() );
        sleep 4;
    }
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'argumentative' => 'i:x:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    if ( !defined $CLI->searchId() or $CLI->searchId() !~ m{^\d{6}$} ) {
        error("You must specify an nickname ID (-i)");
        HELP_MESSAGE();
        exit;
    }
    $maxOfLoop = $opt_ref->{'x'} if exists $opt_ref->{'x'};
    if ( defined $maxOfLoop and $maxOfLoop !~ m{^\d+$} ) {
        sayError("The max of loop  should be an integer. (-x option)");
        HELP_MESSAGE();
        exit;
    }

}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Usage: 
 $Script [-u mynickname -y myage -s mysex -a myavatar -p mypass -v -d]
  -u mynickname  An username
  -y myage       Year old
  -s mysex       M for man or W for women
  -a myavatar    Code 
  -p mypass
  -v             Verbose mode
  -d             Debug mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2012-03-23) 
     Copyright (C) 2010-2012 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

