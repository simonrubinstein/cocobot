#!/usr/bin/perl
#@ brief 
# @created 2012-03-09
# @date 2012-03-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
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
use Cocoweb::DB;
my $DB;
my $CLI;

my %ispCount = ();
my %townCount = ();
my $premiumCount = 0;


init();
run();

my %user = ();
my $bot;

##@method void run()
sub run {
    $bot = $CLI->getBot( 'generateRandom' => 1, 'logUsersListInDB' => 1 );
    $bot->requestAuthentication();
    my $usersList = $bot->requestUsersList();
    $bot->requestInformzForNewUsers();
    $bot->requestDisconnectedUsers();

    if ( !$bot->isPremiumSubscription() ) {
        die error( 'The script is reserved for users with a'.  ' Premium subscription.' );
    }
    my $count = 0;
    while(1) {
        $count++;
        message('Iteration number: ' . $count);
        if ( $count % 28 == 9) {
            $usersList = $bot->requestUsersList();
            $bot->requestInformzForNewUsers();
            $bot->requestDisconnectedUsers();
        }
        $bot->requestMessagesFromUsers();
        sleep 1;
    }
    info("The $Bin script was completed successfully.");
}

sub checkUsers {
    my ($userFound_ref) = @_;
    my ($count, $found) = (0, 0);
    my $town_ref = $DB->getInitTowns();

    foreach my $id (keys %$userFound_ref) {
        next if exists $user{$id};
        my $login_ref = $userFound_ref->{$id};
        foreach my $name (keys %$login_ref) {
            $user{$id}->{$name} = $login_ref->{$name};
        }
        my $infuz_ref = $bot->getInfuz($id);
        print Dumper $infuz_ref;
        $count++;
        $ispCount{$infuz_ref->{'ISP'}}++;
        $townCount{$infuz_ref->{'town'}}++;
        $premiumCount++ if $infuz_ref->{'premium'};
    }

    debug("$count users checked / $premiumCount premium");
    
    #print Dumper \%ispCount;
    #print Dumper \%townCount;

    dumpToFile(\%townCount, '_townCount.pl');

    ($count, $found) = (0, 0);
    foreach my $town (keys %townCount) {
        if (exists $town_ref->{$town}) {
            $found++;
            next;
        }
        print "$town => $townCount{$town}\n";
        $count++;
    }
    print "------------------ found: $found; not found: $count\n";
    #print Dumper $town_ref;



}





## @method void init()
sub init {
    $DB  = Cocoweb::DB->instance();
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1, 'avatarAndPasswdRequired' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Usage: 
 $Script [-u mynickname -y myage -s mysex -a myavatar -p mypass -v -d]
ENDTXT
    $CLI->HELP();
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-03-24');
}

