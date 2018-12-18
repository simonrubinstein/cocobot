#!/usr/bin/env perl
# @created 2017-07-30
# @date 2018-12-18
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2018
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
use Cocoweb::Config;
use Cocoweb::RiveScript;
my $CLI;
my $usersList;
my $bot;
my $totalSendCount   = 0;
my $gobalCount       = 0;
my %nickid2process   = ();
my %nicknames2filter = ();
my @sentences        = ();
my $rsAlerts;
my $filtersFile;

init();
run();

#** @function public run()
sub run {
    $gobalCount = 0;
    while (1) {
        eval { process(); };
        if ($@) {
            sleep 5;
        }
        else {
            last;
        }
    }
}

sub process {
    $bot = $CLI->getBot( 'generateRandom' => 1 );
    if ( $bot->isRiveScriptEnable() ) {
        $bot->setAddNewWriterUserIntoList();
    }
    $bot->requestAuthentication();
    $bot->show();

    # Return an empty  'Cocoweb::User::List' object
    $usersList = $bot->getUsersList();
    for ( ; $gobalCount <= $CLI->maxOfLoop(); $gobalCount++ ) {
        my $mynickname = $bot->user()->mynickname();
        message(  'Iteration number: '
                . $gobalCount . ' / '
                . $CLI->maxOfLoop()
                . '; mynickname: '
                . $mynickname );
        $bot->setTimz1($gobalCount);
        if ( $gobalCount % 160 == 39 ) {
            $bot->requestCheckIfUsersNotSeenAreOffline();
        }
        if ( $gobalCount % 28 == 9 ) {

          #This request is necessary to activate the server side time counter.
            $bot->searchChatRooms();
            checkBadNicknames();
            sendMessages();
        }
        $bot->requestMessagesFromUsers();
        $bot->riveScriptLoop();
        sleep $CLI->delay();
    }
    info("The $Bin script was completed successfully.");
}

sub checkBadNicknames {
    $usersList = $bot->requestUsersList();
    return if !defined $usersList;
    my $user_ref = $usersList->all();
    my $count    = 0;

    foreach my $nickid ( keys %nickid2process ) {
        next if exists $user_ref->{$nickid};
        debug("Delete $nickid user ID");
        delete $nickid2process{$nickid};
        $count++;
    }
    debug("Number of nicknames deleted: $count");

    # reading or re-reading "plain-text/nicknames-to-filter.txt" file
    readNickmanesToFilter();
    $count = 0;
    foreach my $nickid ( keys %$user_ref ) {

        # $user is an "Cocoweb::User" object
        my $user     = $user_ref->{$nickid};
        my $nickname = $user->{'mynickname'};
        if ( $user->isMan() ) {
            delete $nickid2process{$nickid}
                if exists $nickid2process{$nickid};
            next;
        }
        if ( exists $nickid2process{$nickid} ) {
            my $nick_ref = $nickid2process{$nickid};
            next
                if $nick_ref->{'mynickname'} eq $nickname
                and $nick_ref->{'citydio'} eq $user->{'citydio'}
                and $nick_ref->{'myage'} eq $user->{'myage'};
            delete $nickid2process{$nickid};
        }
        next if !exists $nicknames2filter{$nickname};
        $nickid2process{$nickid}->{'mynickname'} = $nickname;
        $nickid2process{$nickid}->{'myage'}      = $user->{'myage'};
        $nickid2process{$nickid}->{'citydio'}    = $user->{'citydio'};
        $nickid2process{$nickid}->{'processed'}  = 0;
        $nickid2process{$nickid}->{'user'}       = $user;
        $count++;
        debug("Nickname man in a woman profile: $nickname");
    }
    debug("Number of new nicknames of women using a man's name: $count");

}

sub sendMessages {
    my ( $usersCount, $sendCount ) = ( 0, 0 );
    foreach my $nickid ( keys %nickid2process ) {
        $usersCount++;
        my $str;
        if ( $nickid2process{$nickid}->{'processed'} ) {
            next if randum(100) > 1;
            $str = $rsAlerts->reply( "user", 'rappel' );
        }
        else {
            $str
                = $rsAlerts->reply( "user", 'This message will be ignored.' );
        }
        my $user = $nickid2process{$nickid}->{'user'};
        $str = "Sais-tu qu'il existe des pseudos hommes pour les hommes"
            if $str eq 'ERR: No Reply Matched';
        message("$nickid2process{$nickid}->{mynickname} => $str");

        $bot->requestWriteMessage( $user, $str );
        $nickid2process{$nickid}->{'processed'}++;
        $sendCount++;
        $totalSendCount++;
    }
    message(  "$sendCount messages sent to a total of $usersCount users."
            . " Number of total messages sent: $totalSendCount" );
}

#** function public readNickmanesToFiler ()
sub readNickmanesToFilter {
    my $hasBeenRead;
    my $filename = 'plain-text/nicknames-to-filter.txt';
    if ( !defined $filtersFile ) {
        $filtersFile = Cocoweb::Config->instance()
            ->getConfigFile( $filename, 'Plaintext' );
        $hasBeenRead = 1;
    }
    else {
        #If the configuration file has been modified it is read again.
        $hasBeenRead = $filtersFile->readFile();
    }
    return if !$hasBeenRead;
    %nicknames2filter = ();
    my $lines_ref = $filtersFile->getAll();
    my $count     = 0;
    foreach my $nickname (@$lines_ref) {
        $nicknames2filter{$nickname} = 1;
        $count++;
    }
    debug( "The $filename file was been read, number of lines: " . $count );
}

#** function public init ()
# @brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $rsAlerts = new Cocoweb::RiveScript();
    $rsAlerts->loadDirectory(
        "rivescript/checks-womens-with-man-names-alerts");
    $rsAlerts->sortReplies();
}

#** function public HELP_MESSAGE ()
# @brief Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', just create a bot.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    print <<END;

Examples:
$Script -v -x 5000 -s M -V rivescript/checks-womens-with-man-names -G W -w 
END
    exit 0;
}

#** function public VERSION_MESSAGE ()
# @brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2018-12-188');
}

