#!/usr/bin/perl
# @created 2013-12-15
# @date 2016-07-23
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016

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

    my $userWanted = $CLI->getUserWanted($bot);
    return if !defined $userWanted;

    my ( $failCount, $totalCount ) = ( 0, 0 );
    my %fails = ();
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );
        eval {
            $bot->requestAuthentication();
            $bot->searchChatRooms();
            $bot->actuam();
            $bot->display();
            my $user     = $bot->user();
            my $response = $bot->requestToBeAFriend($userWanted);
            if ( $response->beenDisconnected() ) {
                die error("you have been disconnected from the server!");
            }
            $totalCount++;
            if ( $response->profileTooNew() ) {
                $failCount++;
                $fails{ $user->myavatar() } = $user->mypass();
            }
            debug(    'Delays the program execution for '
                    . $CLI->delay()
                    . ' second(s)' );
            sleep $CLI->delay();
        };
        $bot = $CLI->getBot( 'generateRandom' => 1 );
    }
    info("$failCount fails / $totalCount");
    info("The $Bin script was completed successfully.");
    foreach my $myavatar ( keys %fails ) {
        print $myavatar . $fails{$myavatar} . "\n";
    }
}

##@method void init()
#@brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts(
        'enableLoop'          => 1,
        'searchEnable'        => 1,
        'myavatarsListEnable' => 1
    );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', Request loop be a friend.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    print <<ENDTXT;

Example:
    ./loop-requests-to-be-a-friend.pl -v -d -M -z 00000 -i 124527 -x 200
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-07-23');
}

