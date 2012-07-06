#!/usr/bin/perl
#@brief This script saves all users connected to the database
#@created 2012-03-09
#@date 2012-06-01
#@author Simon Rubinstein <ssimonrubinstein1@gmail.com>
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

my %ispCount     = ();
my %townCount    = ();
my $premiumCount = 0;

init();
run();

##@method void run()
sub run {
    $DB->initialize();
    my $try = 3;
  AUTH:
    while (1) {
        $bot = $CLI->getBot( 'generateRandom' => 1, 'logUsersListInDB' => 1 );
        $bot->requestAuthentication();
        if ( !$bot->isPremiumSubscription() ) {
            if ( --$try > 0 ) {
                error(  'The user has no Premium subscription. '
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
    $usersList = $bot->getUsersList();
    $usersList->deserialize();
    $usersList->purgeUsersUnseen();
    checkUsers();
    my $count = 0;
    for ( my $count = 1 ; $count <= $CLI->maxOfLoop() ; $count++ ) {
        my $mynickname = $bot->user()->mynickname();
        message(
            'Iteration number: ' . $count . '; mynickname: ' . $mynickname );
        if ( $count % 28 == 9 ) {
            checkUsers();
        }
        $bot->requestMessagesFromUsers();
        sleep 1 if $count < $CLI->maxOfLoop();
    }
    info("The $Bin script was completed successfully.");
}

##@method void checkUsers()
sub checkUsers {
    $usersList = $bot->requestUsersList();
    $bot->requestInfuzForNewUsers();
    $usersList->addOrUpdateInDB();
    $bot->requestCheckIfUsersNotSeenAreOffline();
    $usersList->purgeUsersUnseen();
    $bot->setUsersOfflineInDB();
    $usersList->serialize();

    return;
    my $user_ref = $usersList->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        next if !$user->isNew() and !$user->hasChange() and !$user->messageSentTime();
        $user->messageSentTime(0);
        #next if $user->mysex() != 2;
        my $code = $user->code();
        if ( $code eq 'Wsw' ) {
            $bot->requestWriteMessage( $user, ';02' );
            $bot->requestWriteMessage( $user, "Pourquoi c'est craignos ?" );
        }
        if ( $code eq 'WcL' or $code eq 'PXd' or $code eq 'cZj' or $code eq 'uyI' or $code eq '0fN' ) {
            $bot->requestWriteMessage( $user, ';02' ) if $user->isNew()  or $user->hasChange();
            my @citate = (
'Viata este prea scurta ca sa avem timp si pentru tristete.',
'Tot ce exista, exista pentru ca iubesti.',
'Toate lucrurile bune se intampla celor ce asteapta.',
'Pentru ca am credinta... de aceea inca traisec.',
'Daca iti place viata nu astepta...',
'Nu te ingrijora, fii fericit',
'Orice lucru are frumusetea lui,dar nu oricine o vede.',
'Daca vrei sa fii iubit, iubeste.',
'Iubirea este o prietenie care a luat foc.',
'Omul are nevoie de dragoste. Viata fara duiosie si fara iubire nu e decat un mecanism uscat, scartaitor si sfasietor.',
'O viata fara dragoste este asemenea unui an fara primavara.'
);
            my $i   = randum( scalar @citate ) - 1;
            my $str = $citate[$i];
            $bot->requestWriteMessage( $user, $str );
            $bot->user()->hasSentMessage($str);
            my $myage      = $bot->user()->myage();
            my $mynickname = $bot->user()->mynickname();
            $mynickname =~s{\d+.*$}{};
            $str = "Je m'appelle $mynickname et j'ai $myage ans." . ' Et toi qui es-tu ?';
            $bot->requestWriteMessage( $user, $str );
            $bot->user()->hasSentMessage($str);
        }
    }
}

##@method void init()
sub init {
    $DB  = Cocoweb::DB::Base->getInstance();
    $CLI = Cocoweb::CLI->instance();
    $CLI->lockSingleInstance();
    my $opt_ref =
      $CLI->getOpts( 'enableLoop' => 1, 'avatarAndPasswdRequired' => 1 );
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
    $CLI->VERSION_MESSAGE('2012-06-01');
}

