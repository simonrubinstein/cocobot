#!/usr/bin/perl
# @created 2015-01-03
# @date 2015-01-04
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2015
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
use Carp;
use FindBin qw($Script $Bin);
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::MyAvatar::File;
my $CLI;
my $myavatarFiles;

init();
run();

##@method void run()
sub run {
    my $myAvatarValided = 0;
    my $myavatars_ref = $myavatarFiles->getNew();
    my $userWanted;
    foreach my $val (@$myavatars_ref) {
        croak Cocoweb::error("$val if bad") if $val !~m{^(\d{9})([A-Z]{20})$};
        my ($myavatar, $mypass) = ($1, $2); 
        my $bot = $CLI->getBot( 'generateRandom' => 1, 'myavatar' => $myavatar, 'mypass' => $mypass );
        $bot->requestAuthentication();
        if (!defined ($userWanted)) {
            $userWanted = $CLI->getUserWanted($bot);
            return if !defined $userWanted;
        }
        $bot->display();
        $bot->searchChatRooms();
        $bot->actuam();
        my $counter = 0;
        my $starttime = time;
        PROFILEVALIDATED:
        while (1) {
            $counter++;
            $bot->setTimz1($counter);
            my $usersList;
            if ( $counter % 160 == 39 ) {
                $bot->requestCheckIfUsersNotSeenAreOffline();
            }
            if ( $counter % 28 == 9 ) {
                #This request is necessary to activate the server side time counter.
                $bot->searchChatRooms();
                $usersList = $bot->requestUsersList();
            }
            $bot->requestMessagesFromUsers();
            my $user = $bot->user();
            info( '<' . ( time - $starttime )
                    . ' seconds>; counter: ['
                    . $counter
                    . ']; myavatar:'
                    . $user->myavatar()
                    . '; mypass:'
                    . $user->mypass()
                    . '; number of avatars founds: ' . $myAvatarValided
                    . "\n" );
            if ( $counter % 28 == 9 ) { 
                $bot->requestWriteMessage( $userWanted, $Script );
                my $response = $bot->requestToBeAFriend($userWanted);
                if ($response->profileTooNew()) {
                    debug("The profile is still too recent.");
                } else {
                    $myAvatarValided++;
                    info("The profile is validated.");
                    last PROFILEVALIDATED;
                }
            }
            sleep $CLI->delay();
        }
    }
    info("The $Bin script was completed successfully.");
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1, 'searchEnable' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $myavatarFiles = Cocoweb::MyAvatar::File->instance();
    #$myavatarFiles->createNewFile(102229331, 'XYUMDZSARDTFGCHDBVCJ');
    #$myavatarFiles->updateNew(102229331, 'XYUMDZSARDTFGCHDBVCJ');

}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', Create myavatars.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2015-01-03');
}

