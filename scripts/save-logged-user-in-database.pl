#!/usr/bin/perl
# @brief This script saves all users connected to the database
# @created 2012-03-09
# @date 2017-10-30
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2017
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

my %ispCount       = ();
my %townCount      = ();
my $premiumCount   = 0;
my $isAlarmEnabled = 0;

init();
run();

## @function run()
sub run {
    $DB->initialize();
    my $try = 3;
AUTH:
    while (1) {
        $bot = $CLI->getBot( 'generateRandom' => 1, 'logUsersListInDB' => 1 );
        $bot->requestAuthentication();
        if ( !$bot->isPremiumSubscription() ) {
            if ( --$try > 0 ) {
                error(    'The user has no Premium subscription. '
                        . 'Number of trial(s) left: '
                        . $try );
            }
            else {
                croak error( 'The script is reserved for users with a'
                        . ' Premium subscription.' );
            }
        }
        else {
            info('Successful authentication with a Premium subscription');
            last AUTH;
        }
    }
    $bot->getMyInfuz();
    $bot->requestConnectedUserInfo();

    #$bot->request()->isDieIfDisconnected(0);

    # Return an empty  'Cocoweb::User::List' object
    $usersList = $bot->getUsersList();

    # Reads previous list of users from 'var/cocoweb-user-list.data' file
    $usersList->deserialize();

    # Cleans the list of users who have not been seen in the list
    # returned by the sever for several minutes.
    $usersList->purgeUsersUnseen($bot);
    return if $bot->beenDisconnected();
    $usersList->addOrUpdateInDB(0);

    checkUsers();
    my $count = 0;
BOOTLOOP:
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        $bot->setTimz1($count);
        last BOOTLOOP if $bot->beenDisconnected();
        my $mynickname = $bot->user()->mynickname();
        message(
            'Iteration number: ' . $count . '; mynickname: ' . $mynickname );
        if ( $count % 28 == 9 ) {
            checkUsers();
            last BOOTLOOP if $bot->beenDisconnected();
        }
        $bot->requestMessagesFromUsers();
        last BOOTLOOP if $bot->beenDisconnected();
        sleep 1 if $count < $CLI->maxOfLoop();
    }
    $usersList->serialize();
    info("The $Bin script was completed successfully.");
}

##@method void checkUsers()
sub checkUsers {

    # Reset at zero 'isNew', 'isView', 'hasChange' and 'updateDbRecord'
    # data members of each current user.
    # Request and returns the list of connected users
    debug('[checkUsers] $bot->requestUsersList();');
    $usersList = $bot->requestUsersList();
    return if $bot->beenDisconnected();

    # Makes an request to retrieve the 'infuz' value for all new users.
    debug('[checkUsers] $bot->requestInfuzForNewUsers');
    $bot->requestInfuzForNewUsers();
    return if $bot->beenDisconnected();

    #
    debug('[checkUsers] $usersList->addOrUpdateInDB(1)');
    $usersList->addOrUpdateInDB(1);
    debug('[checkUsers] $usersList->serialize');
    $usersList->serialize();

    # Requests on Coco.fr to determine if users are disconnected.
    debug('[checkUsers] $bot->requestCheckIfUsersNotSeenAreOffline();');
    $bot->requestCheckIfUsersNotSeenAreOffline();
    debug('[checkUsers] $usersList->purgeUsersUnseen($bot)');
    $usersList->purgeUsersUnseen($bot);
    debug('[checkUsers] $usersList->addOrUpdateInDB(0);');
    $usersList->addOrUpdateInDB(0);
    debug('[checkUsers]');
    $bot->setUsersOfflineInDB();
    debug('[checkUsers] $usersList->serialize();');
    $usersList->serialize();

    debug('[checkUsers] alarmProcess( $bot, $usersList ); ');
    alarmProcess( $bot, $usersList );
    return if $bot->beenDisconnected();

    # Reset at zero 'recent' data member of each user
    debug('[checkUsers] $usersList->clearRecentFlags();');
    $usersList->clearRecentFlags();
}

## @method void alarmProcess()
# @brief The parameters entered in the "conf/alert.conf" configuration file to:
#        - To send messages XMMP if a specified user is connected.
#        - To write messages to connected users.
sub alarmProcess {
    my ( $bot, $usersList ) = @_;
    return if !$isAlarmEnabled;
    info('Alarms are enabled!');
    eval {
        require 'Cocoweb/Alert.pm';
        my $alert = Cocoweb::Alert->instance();
        $alert->process( $bot, $usersList );
    };
    error($@) if $@;
}

## @method void init()
sub init {
    $DB  = Cocoweb::DB::Base->getInstance();
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts(
        'argumentative'           => 'A',
        'enableLoop'              => 1,
        'avatarAndPasswdRequired' => 1
    );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $isAlarmEnabled = 1 if exists $opt_ref->{'A'};
    info("isAlarmEnabled: $isAlarmEnabled");
    $CLI->lockSingleInstance();
}

## @method void HELP_MESSAGE()
# @brief Display help message
sub HELP_MESSAGE {
    print STDOUT $Script
        . ', This script will log the user in the database.' . "\n";
    $CLI->printLineOfArgs('[-A]');
    $CLI->HELP();
    print <<ENDTXT;
  -A                Enable alert 
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
# @brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2017-01-30');
}

