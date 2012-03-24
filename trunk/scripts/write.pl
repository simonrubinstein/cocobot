#!/usr/bin/perl
# @created 2012-02-22
# @date 2012-03-10
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
use Cocoweb::User::Wanted;
my $CLI;
my $message;

init();
run();

##@method ivoid run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->process();
    $bot->display();
    my $userWanted;
    if ( defined $CLI->searchNickname() ) {
        $userWanted =
          Cocoweb::User::Wanted->new( 'mynickname' => $CLI->searchNickname() );
        $userWanted = $bot->searchNickname($userWanted);
        if ( !defined $userWanted ) {
            print STDOUT 'The pseudonym "'
              . $CLI->searchNickname()
              . '" was not found.' . "\n";
            return;
        }
    }
    else {
        $userWanted =
          Cocoweb::User::Wanted->new( 'mynickID' => $CLI->searchId() );
    }
    $bot->writeMessage( $message, $userWanted );
    sleep 2;
    $bot->lancetimer();
    info("The script was completed successfully.");
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'searchEnable' => 1, 'argumentative' => 'm:' );
    $message = $opt_ref->{'m'} if exists $opt_ref->{'m'};
    if ( !defined $message ) {
        die error("You must specify a message string (-m option)");
    }
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Usage: 
 $Script [-l nickmaneWanted -u mynickname -y myage -s mysex -a myavatar -p mypass -v -d]
  -l nickmaneWanted
  -u mynickname      An username
  -y myage           Year old
  -s mysex           M for man or W for women
  -a myavatar        Code 
  -p mypass
  -v                 Verbose mode
  -d                 Debug mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2012-02-28) 
     Copyright (C) 2010-2012 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

