#!/usr/bin/perl
# @created 2015-01-03
# @date 2015-01-03
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
use Cocoweb::MyAvatar::File;
my $CLI;
my $myavatarFiles;

init();
run();

##@method void run()
sub run {
    my $myAvatarFound = 0;
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );

        eval {
            $bot->requestAuthentication();
            $bot->show();
            my $counter = 0;
            my $starttime = time;
        WAITMYPASS:
            while (1) {
                $counter++;
                $bot->setTimz1($counter);
                my $usersList;
                if ( $counter % 28 == 9 ) {
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
                        . '; number of avatars founds: ' . $myAvatarFound
                        . "\n" );
                $bot->display();
                if ( length( $user->mypass() ) == 20 ) {
                    print "length : " . length( $user->mypass() ) . "\n";
                    $myavatarFiles->createNewFile( $user->myavatar(),
                        $user->mypass() );
                    info("The mypass value has been recovered!");
                    $myAvatarFound++;
                    last WAITMYPASS;
                }
                debug(    'Delays the program execution for '
                        . $CLI->delay()
                        . ' second(s)' );
                sleep $CLI->delay();
            }
        };
        error($@) if $@;

        undef $bot;
        #undef $CLI;
        #$CLI = Cocoweb::CLI->instance();
        #my $opt_ref = $CLI->getOpts( 'enableLoop' => 1 );
        #if ( !defined $opt_ref ) {
        #    HELP_MESSAGE();
        #    exit;
        #}
        $bot = $CLI->getBot( 'generateRandom' => 1 );
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

