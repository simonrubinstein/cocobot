#!/usr/bin/perl
# @brief Search a user from its nickname code
# @created 2012-03-18
# @date 2015-01-05
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
my $code;

init();
run();

##@method void run()
sub run {
    my $bot = $CLI->getBot( 'generateRandom' => 1 );
    $bot->requestAuthentication();
    $bot->display();
    my $response = $bot->requestCodeSearch($code);
    my $user = $response->userFound(); 
    $bot->requestUserInfuz($user);
    $user->show();
    info("The $Bin script was completed successfully.");
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'argumentative' => 'c:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $code = $opt_ref->{'c'} if exists $opt_ref->{'c'};
    if ( !defined $code ) {
        die error("You must specify a nickname code (-c option)");
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', search a user from its code.' . "\n";
    $CLI->printLineOfArgs('-l code');
    print <<ENDTXT;
  -c code           The nickname code searched, an alphanumeric code
                    of three characters, i.e. WcL
ENDTXT
    $CLI->HELP();
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2015-01-05');
}
