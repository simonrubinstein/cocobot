#!/usr/bin/perl
# @brief Displays the list of users logged on the website Coco.fr
# @created 2012-02-22
# @date 2014-03-01
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
#
# copyright (c) Simon Rubinstein 2010-2012
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
use Data::Dumper;
use FindBin qw($Script $Bin);
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
my $CLI;
my %nicknames2filter = ();

init();
run();

##@method void run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->requestAuthentication();
    $bot->display();

    # Get a 'Cocoweb::User::List' object
    my $usersList = $bot->requestUsersList();
    if ( !defined $usersList ) {
        warning("No users found");
    }
    else {
        $usersList->display(
            'mysex'            => $CLI->mysex(),
            'myage'            => $CLI->myage(),
            'mynickame'        => $CLI->searchNickname(),
            'nicknames2filter' => \%nicknames2filter
        );
    }
    info("The $Bin script was completed successfully.");
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'argumentative' => 'l:f:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    my $filtersStr = $opt_ref->{'f'} if exists $opt_ref->{'f'};
    if ( defined $filtersStr ) {
        my @filters = split( /,/, $filtersStr );
        foreach my $f (@filters) {
            my $file = Cocoweb::Config->instance()
                ->getConfigFile( $f, 'Plaintext' );
            my $lines_ref = $file->getAll();
            foreach my $nickname (@$lines_ref) {
                $nicknames2filter{$nickname} = 1;
            }
        }
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script
        . ', displays the list of users logged on the website Coco.fr' . "\n";
    $CLI->printLineOfArgs('-l nickmaneWanted');
    print STDOUT '  -l nickmaneWanted Nickname that will be '
        . "filtered to display the list.\n";
    print STDOUT '  -f filters'
        . '        Filters (i.e. plain-text/nicknames-to-filter.txt)' . "\n";
    $CLI->HELP();
    print STDOUT '  The arguments -s (sex) and -y (age) are also used'
        . ' to filter the display of the list.' . "\n";

    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2014-03-01');
}

