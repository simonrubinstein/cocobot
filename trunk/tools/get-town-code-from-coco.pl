#!/usr/bin/perl
#@brief
#@created 2012-03-09
#@date 2012-03-17
#@author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
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
use FindBin qw($Script $Bin);
use Data::Dumper;
use Term::ANSIColor;
use Time::HiRes;
$Term::ANSIColor::AUTORESET = 1;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::DB;
my $DB;
my $CLI;
my $ISPCount_ref      = {};
my $townCount_ref     = {};
my $premiumCount      = 0;
my $isLoop            = 0;
my $isReconnect       = 0;
my $dumpTownsFilename = '_townCount.pl';
my $dumpISPsFilename  = '_ISPCount.pl';

init(); 
run();

my %user = ();
my $bot;

##@method void run()
sub run {
    if ( !$isLoop ) {
        process();
    }
    else {
        while (1) {
            my $timeStartLoop = [Time::HiRes::gettimeofday];
            process();
            my $timeEndProcess = [Time::HiRes::gettimeofday];
            my $elapsed        = Time::HiRes::tv_interval($timeEndProcess);
            my @e              = split( /\./, $elapsed );
            my $sleepVal       = Time::HiRes::tv_interval( \@e, [ 4, 0 ] );
            message("process interval: $elapsed; sleep: $sleepVal");

            #Time::HiRes::sleep($sleepVal);
            sleep 5;
            $elapsed = Time::HiRes::tv_interval($timeStartLoop);
            message("time looop interval: $elapsed");
        }
    }
    info("The $Bin script was completed successfully.");
}

##@method void process()
sub process {
    if ($isReconnect or !defined $bot) {
        $bot = $CLI->getBot( 'generateRandom' => 1 );
        $bot->process();
        $bot->display();
        if ( !$bot->isPremiumSubscription() ) {
            die error( 'The script is reserved for users with a'
                    . ' Premium subscription.' );
        }
    }
    $bot->lancetimer();
    my $userFound_ref = $bot->getUsersList();
    getTownsFromInfuz($userFound_ref);
}

##@method void getTownsFromInfuz()
sub getTownsFromInfuz {
    my ($userFound_ref) = @_;
    my ( $count, $found, $notFound ) = ( 0, 0, 0 );
    my ( $town_ref, $townConf ) = $DB->getInitTowns();
    my ( $ISP_ref,  $ISPConf )  = $DB->getInitISPs();
    $townCount_ref = fileToVars($dumpTownsFilename) if -f $dumpTownsFilename;
    $ISPCount_ref  = fileToVars($dumpISPsFilename)  if -f $dumpISPsFilename;

    foreach my $id ( keys %$userFound_ref ) {
        next if exists $user{$id};
        my $login_ref = $userFound_ref->{$id};
        foreach my $name ( keys %$login_ref ) {
            $user{$id}->{$name} = $login_ref->{$name};
        }
        my $infuz_ref = $bot->getInfuz($id);
        $count++;
        $ISPCount_ref->{ $infuz_ref->{'ISP'} }++;
        $townCount_ref->{ $infuz_ref->{'town'} }++;
        $premiumCount++ if $infuz_ref->{'premium'};
    }
    message( 'Number of checked users: : ' . $count );
    message(
        'The number of users with a Premium subscription: ' . $premiumCount );
    dumpToFile( $townCount_ref, $dumpTownsFilename );
    dumpToFile( $ISPCount_ref,  $dumpISPsFilename );
    $count = 0;
    foreach my $town ( sort keys %$townCount_ref ) {
        $count++;
        if ( exists $town_ref->{$town} ) {
            $found++;
            next;
        }

        #message( $town . ' => ' . $townCount_ref->{$town} );
        $notFound++;
    }
    message( 'Number total of town code(s)    : ' . $count );
    message( 'Number of town code(s) found    : ' . $found );
    message( 'Number of town code(s) not found: ' . $notFound );

    ( $count, $found, $notFound ) = ( 0, 0, 0 );
    foreach my $isp ( sort keys %$ISPCount_ref ) {
        $count++;
        if ( exists $ISP_ref->{$isp} ) {
            $found++;
            next;
        }

        #message( $town . ' => ' . $townCount_ref->{$town} );
        $notFound++;
    }
    message( 'Number total of IPS code(s)    : ' . $count );
    message( 'Number of ISP code(s) found    : ' . $found );
    message( 'Number of ISP code(s) not found: ' . $notFound );

}

## @method void init()
sub init {
    $DB  = Cocoweb::DB->instance();
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'argumentative' => 'lr' );
    $isLoop      = 1 if exists $opt_ref->{'l'};
    $isReconnect = 1 if exists $opt_ref->{'r'};
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
 $Script -a myavatar -p mypass
         [-u mynickname -y myage -s mysex -v -d]
         [-l -r]
  -a myavatar        A unique identifier for your account 
  -p mypass          The password for your account
  -l                 The script is running in loop mode constantly
  -r                 Reconnect with each new loop
  -u mynickname      An username
  -y myage           Year old
  -s mysex           M for man or W for women
  -v                 Verbose mode
  -d                 Debug mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2012-03-17) 
     Copyright (C) 2010-2012 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

