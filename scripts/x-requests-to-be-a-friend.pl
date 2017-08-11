#!/usr/bin/perl
# @created 2014-03-01
# @date 2015-01-09
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
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
use FindBin qw($Script $Bin);
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
my $CLI;
my %nicknames2process = ();
my %nickid2process    = ();
my $sexTargeted;
my $bot;
my $botList;
my $zipList;
my $usersList;
my $counterDisconnectedUsers = 0;

init();
run();

##@method void run()
sub run {
    $bot = $CLI->getBot( 'generateRandom' => 1 );
    if (defined $zipList) {
        $botList = $CLI->getBot( 'generateRandom' => 1, 'zip' => $zipList );
        $botList->requestAuthentication();
        $bot->display();
    } else {
        $botList = $bot;
    }

    # Return an empty  'Cocoweb::User::List' object
    $usersList = $botList->getUsersList();
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );
        eval {
            $bot->requestAuthentication();
            $bot->display();
            searchNickID();
            requestToBeAFriend();
            if ( $count % 160 == 39 ) {
                $botList->requestCheckIfUsersNotSeenAreOffline();
            }
            debug(    'Delays the program execution for '
                    . $CLI->delay()
                    . ' second(s)' );
            $bot->requestMessagesFromUsers();
            sleep $CLI->delay();
        };
        error($@) if $@;
        $bot = $CLI->getBot( 'generateRandom' => 1 );
        $botList->setUsersList($usersList);

    }
    info("The $Bin script was completed successfully.");
}

##@method void requestToBeAFriend()
sub requestToBeAFriend {
    my $nicknamesStr  = '';
    my $requestsCount = 0;
    foreach my $nickid ( keys %nickid2process ) {
        my $userWanted = $nickid2process{$nickid};
        if ( defined $sexTargeted ) {
            if ( $userWanted->mysex() !~ $sexTargeted ) {
                info(     'sex of '
                        . $userWanted->{'mynickname'} . ': '
                        . $userWanted->mysex() );
                next;
            }
        }
        $requestsCount++;
        $bot->requestToBeAFriend($userWanted);
        $nicknamesStr .= $userWanted->{'mynickname'} . ', ';
    }
    $nicknamesStr = substr($nicknamesStr, 0, -2); 
    info(     'A request was sent to '
            . $requestsCount
            . ' users: '
            . $nicknamesStr );
}

##@method searchNickID()
sub searchNickID {
    $usersList = $botList->requestUsersList();
    return if !defined $usersList;
    my $user_ref = $usersList->all();

    foreach my $nickid ( keys %nickid2process ) {
        next if exists $user_ref->{$nickid};
        info(     '(!!!!!!!!!!!!) The '
                . $nickid2process{$nickid}->{'mynickname'}
                . ' user has been disconnected' );
        delete $nickid2process{$nickid};
        $counterDisconnectedUsers++;
    }

    foreach my $nickid ( keys %$user_ref ) {
        my $name = $user_ref->{$nickid}->{'mynickname'};
        next if exists $nickid2process{$nickid};
        if ( !exists $nicknames2process{$name} ) {
            delete $user_ref->{$nickid};
            next;
        }
        $nickid2process{$nickid} = $user_ref->{$nickid};
        info("$name / $nickid was found");
    }
    info(     '(*) Number of users in the list: '
            . scalar( keys %$user_ref )
            . '; Counter disconnected users: '
            . $counterDisconnectedUsers );
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref
        = $CLI->getOpts( 'enableLoop' => 1, 'myavatarsListEnable' => 1, 'argumentative' => 'f:X:Z:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    if ( !exists $opt_ref->{'f'} ) {
        error("You must specify filename of nicknames (-f)");
        HELP_MESSAGE();
        exit;
    }
    my $filtersStr = $opt_ref->{'f'};
    my @filters = split( /,/, $filtersStr );
    foreach my $f (@filters) {
        my $file
            = Cocoweb::Config->instance()->getConfigFile( $f, 'Plaintext' );
        my $lines_ref = $file->getAll();
        foreach my $nickname (@$lines_ref) {
            $nicknames2process{$nickname} = 1;
        }
    }
    $sexTargeted = $opt_ref->{'X'} if exists $opt_ref->{'X'};
    if ( defined $sexTargeted ) {
        if ( $sexTargeted eq 'W' ) {
            $sexTargeted = qr/^(2|7)$/;
        }
        elsif ( $sexTargeted eq 'M' ) {
            $sexTargeted = qr/^(1|6)$/;
        }
        else {
            error(    'The sex argument value must be either M or W.'
                    . ' (-s option)' );
        }
    }
    $zipList = $opt_ref->{'Z'} if exists $opt_ref->{'Z'};
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', Request loop be a friend.' . "\n";
    $CLI->printLineOfArgs('-f nicklist -X targetetSex -Z zipList');
    $CLI->HELP();
    print <<ENDTXT;
  -f nicklist       Nicklist that are targeted. (i.e. plain-text/nicknames-to-filter.txt)  
  -X targetetSex    Sex that is targeted  M for man or W for women
  -Z zipList
  
Example:
./x-requests-to-be-a-friend.pl -M -v -s W -f plain-text/nicknames-to-filter.txt -x 1000 -X W
./x-requests-to-be-a-friend.pl -M -v -s W -f plain-text/nicknames-to-filter.txt -x 1000 -X W -z 00000 -Z 75001

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2015-01-09');
}

