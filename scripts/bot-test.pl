#!/usr/bin/env perl
# @created 2012-02-25
# @date 2016-08-18
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
#
# copyright (c) Simon Rubinstein 2010-2016
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

init();
run();

##@method void run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    if ( $bot->isRiveScriptEnable() ) {
        $bot->setAddNewWriterUserIntoList();
    }
    $bot->requestAuthentication();
    $bot->show();
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );
        $bot->setTimz1($count);
        my $usersList;
        if ( $count % 160 == 39 ) {
            $bot->requestCheckIfUsersNotSeenAreOffline();
        }
        if ( $count % 28 == 9 ) {
            #This request is necessary to activate the server side time counter.
            $bot->searchChatRooms();
            $usersList = $bot->requestUsersList();
        }
        $bot->requestMessagesFromUsers();
        $bot->riveScriptLoop();
        sleep $CLI->delay();
    }
    info("The $Bin script was completed successfully.");
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', just create a bot.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    print <<END;

Examples:
bot-test.pl -v -x 1000 -s W -V rivescript/woman-replies
END
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-08-18');
}

