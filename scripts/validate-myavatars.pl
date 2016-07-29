#!/usr/bin/env perl
# @created 2015-01-03
# @date 2016-07-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
#
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
my @botsList                   = ();
my @countersList               = ();
my @startTimeList              = ();
my $myAvatarValided            = 0;
my $restrictedCount            = 0;
my $disconnectedCount          = 0;
my $accountProblemCount        = 0;
my $myavatarCount              = 0;
my $isRestrictedAccountAllowed = 0;
my $isRunFilesUsed             = 0;
my $isSendsMessageAlways       = 0;
my $isSkipTooNewAccounts       = 0;
my $messageSent;
my $myavatars_ref;
my $userWanted;
my $myavatarNumOf;

init();
run();

##@method void run()
sub run {

    if ( defined $CLI->myavatar() and defined $CLI->mypass() ) {
        $myavatars_ref = [ $CLI->myavatar() . $CLI->mypass() ];
    }
    else {
        if ($isRunFilesUsed) {
            $myavatars_ref = $myavatarFiles->getRun();
        }
        else {
            $myavatars_ref = $myavatarFiles->getNew();
        }
    }
    $myavatarNumOf = scalar(@$myavatars_ref);

    my $numConcurrentUsers = $CLI->maxOfLoop();
    for ( my $i = 0; $i < $numConcurrentUsers; $i++ ) {
        my $bot = getNewBot();
        next if !defined $bot;
        push @botsList,      $bot;
        push @countersList,  0;
        push @startTimeList, time;
    }

    $numConcurrentUsers = scalar(@botsList);
    while (1) {
        my $processCount = 0;
        for ( my $i = 0; $i < $numConcurrentUsers; $i++ ) {
            next if !defined $botsList[$i];
            $processCount++;
            $countersList[$i]++;
            if (!process(
                    $botsList[$i], $countersList[$i], $startTimeList[$i]
                )
                )
            {
                #debug( "delay: " . $CLI->delay() . ' second(s)' );
                sleep $CLI->delay() if $numConcurrentUsers < 2;
                next;
            }
            undef $botsList[$i];
            $botsList[$i]      = getNewBot();
            $countersList[$i]  = 0;
            $startTimeList[$i] = time;
        }
        last if $processCount < 1;
    }
    info(     "Number of avatars:$myavatarNumOf; success:$myAvatarValided"
            . "; Restricted: $restrictedCount; disconnected: $disconnectedCount"
    );
    info("The $Bin script was completed successfully.");
}

sub getNewBot {
    return if scalar(@$myavatars_ref) < 1;
    $myavatarCount++;
    my $val = shift @$myavatars_ref;
    croak Cocoweb::error("$val if bad") if $val !~ m{^(\d{9})([A-Z]{20})$};
    my ( $myavatar, $mypass ) = ( $1, $2 );
    my $bot = $CLI->getBot(
        'generateRandom' => 1,
        'myavatar'       => $myavatar,
        'mypass'         => $mypass
    );
    $bot->request()->isDieIfDisconnected(0);
    $bot->display();
    $bot->searchChatRooms();
    $bot->actuam();
    $bot->requestAuthentication();

    if ( !defined($userWanted) ) {
        $userWanted = $CLI->getUserWanted($bot);
        die "User wanted was not found" if !defined $userWanted;
    }
    debug("*** Create new bot $myavatar, $mypass ***");
    return $bot;
}

sub process {
    my ( $bot, $counter, $starttime ) = @_;
    $counter++;
    $bot->setTimz1($counter);
    my $usersList;
    if ( $counter % 160 == 39 ) {
        $bot->requestCheckIfUsersNotSeenAreOffline();
    }
    if ( $counter % 28 == 0 ) {

        #This request is necessary to activate the server side time counter.
        $bot->searchChatRooms();
        $usersList = $bot->requestUsersList();
    }
    $bot->requestMessagesFromUsers();
    my $user = $bot->user();
    my $infoStr
        = $myavatarCount . '/'
        . $myavatarNumOf . ' ' . '('
        . ( time - $starttime )
        . ' sec); ['
        . $counter . ']; '
        . $user->myavatar() . ' '
        . $user->mypass()
        . '; validated: '
        . $myAvatarValided;
    if ( $counter % 28 == 5 ) {
        writeMessage( $bot, $counter ) if $isSendsMessageAlways;
        my $response = $bot->requestToBeAFriend($userWanted);
        info( '**' . $infoStr );
        if ( $response->beenDisconnected() ) {
            error("you have been disconnected from the server!");
            $disconnectedCount++;
            return 1;
        }
        elsif ( $response->isAccountProblem() ) {
            $accountProblemCount++;
            return 1;
        }
        elsif ( $response->profileTooNew() ) {
            debug("The profile is still too recent.");
            return 1 if $isSkipTooNewAccounts;
        }
        else {
            $myAvatarValided++;
            info("The profile is validated.");
            if (    !defined $CLI->myavatar()
                and !defined $CLI->mypass()
                and !$isRestrictedAccountAllowed )
            {
                my ( $myavatar, $mypass )
                    = ( $user->myavatar(), $user->mypass() );
                $myavatarFiles->moveNewToRun( $myavatar, $mypass )
                    if !$isRunFilesUsed;
                $myavatarFiles->updateRun( $myavatar, $mypass );
            }
            return 1;
        }
        return writeMessage( $bot, $counter ) if !$isSendsMessageAlways;
    }
    else {
        info( '--' . $infoStr );
    }
    return 0;
}

sub writeMessage {
    my ( $bot, $counter ) = @_;
    my $message;
    if ( defined $messageSent ) {
        $message = $messageSent;
    }
    else {
        $message = $Script . ' ' . $counter;
    }
    my $response = $bot->requestWriteMessage( $userWanted, $message );
    if ( $response->isRestrictedAccount()
        and !$isRestrictedAccountAllowed )
    {
        debug("The account is restricted. Gives up.");
        $restrictedCount++;
        return 1;
    }
    elsif ( $response->isUserWantToWriteIsdisconnects() ) {
        error("Target user is disconnects!");
    }
    return 0;
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts(
        'enableLoop'    => 1,
        'searchEnable'  => 1,
        'argumentative' => 'RNWKm:'
    );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $isRestrictedAccountAllowed = $opt_ref->{'R'} if exists $opt_ref->{'R'};
    $isRunFilesUsed             = $opt_ref->{'N'} if exists $opt_ref->{'N'};
    $isSendsMessageAlways       = $opt_ref->{'W'} if exists $opt_ref->{'W'};
    $isSkipTooNewAccounts       = $opt_ref->{'K'} if exists $opt_ref->{'K'};
    $messageSent                = $opt_ref->{'m'} if exists $opt_ref->{'m'};
    $myavatarFiles = Cocoweb::MyAvatar::File->instance();

}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', valide MyAvatar accounts.' . "\n";
    $CLI->printLineOfArgs('-R -N -m message');
    print <<ENDTXT;
  -R                Enable the process of restricted accounts. 
  -N                Use the files (containing 'myavatar' and 'mypass')
                    from the '/var/myavatar/run' directory instead
                    from the '/var/myavatar/new' directory
  -W                Sends a message after each request to become a friend         
  -K                Skip 'too recent' accounts 
  -m message        The text message to send. 
ENDTXT
    $CLI->HELP();
    print <<ENDTXT;
 
Examples:
validate-myavatars.pl -v -i 218185 -N -s M

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-07-29');
}

