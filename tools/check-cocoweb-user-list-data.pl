#!/usr/bin/perl
# @brief
# @created 2016-06-25
# @date 2016-06-25
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
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
use Time::HiRes;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
my $bot;
my $CLI;
my $usersList;
my $mynickname;

my %ispCount       = ();
my %townCount      = ();
my $premiumCount   = 0;
my $isAlarmEnabled = 0;

init();
run();

##@method void run()
sub run {
    my $bot = Cocoweb::Bot->new();

    # return an empty  'Cocoweb::User::List' object
    $usersList = $bot->getUsersList();

    # reads users from 'var/cocoweb-user-list.data' file
    $usersList->deserialize();
    my $viewMessages;
    if ( defined $mynickname ) {
        $viewMessages = 0;
    }
    else {
        $viewMessages = 1;
    }

    my $user_ref = $usersList->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};

        if ($viewMessages) {
            my $messageLast = $user->messageLast();
            if ( defined $messageLast and length($messageLast) > 0 ) {
                my $sentTime = timeToDate( $user->messageSentTime() );
                printf( "$sentTime %-16s: $messageLast\n",
                    $user->mynickname() );
            }
            next;
        }

        if ( defined $mynickname and $mynickname eq $user->{'mynickname'} ) {
            my $dateLastSeen = timeToDate( $user->dateLastSeen() );
            $user->dateLastSeen($dateLastSeen);
            $user->dump();
        }
    }
    info("The $Bin script was completed successfully.");
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();

    #my $opt_ref = $CLI->getMinimumOpts();
    my $opt_ref = $CLI->getOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $mynickname = $CLI->mynickname() if defined $CLI->mynickname();
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print STDOUT <<ENDTXT;
$Script, Checks the 'cocoweb-user-list.data' file.
$Script [-v -d ]
  -u mynickname   A nickname to search in 'cocoweb-user-list.data' 
  -v              Verbose mode
  -d              Debug mode
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-06-25');
}

