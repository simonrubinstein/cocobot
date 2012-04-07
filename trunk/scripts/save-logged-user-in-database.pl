#!/usr/bin/perl
#@ brief 
# @created 2012-03-09
# @date 2012-04-07
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# Id: $Id
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
use Time::HiRes;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::DB::Base;
my $bot;
my $DB;
my $CLI;
my $usersList;

my %ispCount = ();
my %townCount = ();
my $premiumCount = 0;


init();
run();


##@method void run()
sub run {
    $DB->initialize();
    $bot = $CLI->getBot( 'generateRandom' => 1, 'logUsersListInDB' => 1 );
    $bot->requestAuthentication();
    $usersList = $bot->getUsersList();
    $usersList->deserialize();
    checkUsers();
    if ( !$bot->isPremiumSubscription() ) {
        die error( 'The script is reserved for users with a'.  ' Premium subscription.' );
    }
    my $count = 0;
    for ( my $count = 1 ; $count <= $CLI->maxOfLoop() ; $count++ ) {
        message('Iteration number: ' . $count);
        if ( $count % 28 == 9) {
            checkUsers();
        }
        $bot->requestMessagesFromUsers();
        sleep 1 if $count < $CLI->maxOfLoop();
    }
    info("The $Bin script was completed successfully.");
}

sub checkUsers {
    $usersList = $bot->requestUsersList();
    $bot->requestInformzForNewUsers();
    $usersList->addOrUpdateInDB();
    $bot->requestDisconnectedUsers();
    $bot->setUserOfflineInDB();
    $usersList->serialize();
}

## @method void init()
sub init {
    $DB = Cocoweb::DB::Base->getInstance();
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1, 'avatarAndPasswdRequired' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script
      . ', This script will log the user in the database.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-04-03');
}

