#!/usr/bin/perl
# @created 2012-02-28
# @date 2012-04-07
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
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

init();
run();

##@method void run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->requestAuthentication();
    $bot->display();
    my $userWanted =
      Cocoweb::User::Wanted->new( 'mynickname' => $CLI->searchNickname() );
    $userWanted = $bot->searchNickname($userWanted);
    if ( !defined $userWanted ) {
        print STDOUT 'The pseudonym "'
          . $CLI->searchNickname()
          . '" was not found.' . "\n";
        return;
    }
    $bot->requestUserInfuz($userWanted);
    $userWanted->show();
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'argumentative' => 'l:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    if ( !defined $CLI->searchNickname() ) {
        error("You must specify an username (-l)");
        HELP_MESSAGE();
        exit;
    }
}

##@method void HELP_MESSAGE()
#Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', Research a nickname connected.' . "\n";
    $CLI->printLineOfArgs('-l nickname');
    print <<ENDTXT;
  -l nickname       The nickname wanted. 
ENDTXT
    $CLI->HELP();
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-04-07');
}

