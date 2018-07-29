#!/usr/bin/env perl
# @created 2017-07-30
# @date 2018-07-29
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
my %nickid2process   = ();
my %nicknames2filter = ();
my @sentences        = ();
my $rsAlerts;
my $filtersFile;

init();
run();

#** @function public run()
sub run {
    $bot = $CLI->getBot( 'generateRandom' => 1 );
    if ( $bot->isRiveScriptEnable() ) {
        $bot->setAddNewWriterUserIntoList();
    }
    $bot->requestAuthentication();
    $bot->show();

    # Return an empty  'Cocoweb::User::List' object
    $usersList = $bot->getUsersList();
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );
        $bot->setTimz1($count);
        if ( $count % 160 == 39 ) {
            $bot->requestCheckIfUsersNotSeenAreOffline();
        }
        if ( $count % 28 == 9 ) {

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

    # reading or re-reading "plain-text/nicknames-to-filter.txt" file
    readNickmanesToFilter();
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
            my $lastname = $nickid2process{$nickid}->{'mynickname'};
            next if $lastname eq $nickname;
            delete $nickid2process{$nickid};
        }
        next if !exists $nicknames2filter{$nickname};
        $nickid2process{$nickid}->{'mynickname'} = $nickname;
        $nickid2process{$nickid}->{'processed'}  = 0;
        $nickid2process{$nickid}->{'user'}       = $user;
        $count++;
        debug("Nickname man in a woman profile: $nickname");
    }
    debug("Number of nicknames of women using a man's name: $count");
}

sub sendMessages {
    my ( $totalCount, $sendCount ) = ( 0, 0 );
    foreach my $nickid ( keys %nickid2process ) {
        $totalCount++;
        next if $nickid2process{$nickid}->{'processed'};
        my $user    = $nickid2process{$nickid}->{'user'};
        my $message = $rsAlerts->reply( "user", 'This message will be ignored.' );
        $message  = "Salut, sais-tu qu'il existe des pseudos hommes pour les hommes"
            if $message eq 'ERR: No Reply Matched';
        message("$nickid2process{$nickid}->{mynickname} => $message");
        $bot->requestWriteMessage( $user, $message );
        $nickid2process{$nickid}->{'processed'} = 1;
        $sendCount++;
    }
    message("$sendCount messages sent to a total of $totalCount users");
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
    $rsAlerts->loadDirectory("rivescript/checks-womens-with-man-names-alerts");
    $rsAlerts->sortReplies();
    #for (my $i = 0; $i < 100; $i++) {
    #    my $reply = $rsAlerts->reply( "user", 'This message will be ignored.' );
    #    print "$reply\n";
    #}
}

#** function public HELP_MESSAGE ()
# @brief Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', just create a bot.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    print <<END;

Examples:
$Script -v -x 5000 -s W -V rivescript/checks-womens-with-man-names 
END
    exit 0;
}

#** function public VERSION_MESSAGE ()
# @brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2018-07-29');
}

