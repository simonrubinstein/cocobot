#!/usr/bin/env perl
# @created 2017-07-30 
# @date 2017-07-31
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
use FindBin qw($Script $Bin);
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::Config;
my $CLI;
my $usersList;
my $bot;
my %nickid2process   = ();
my %nicknames2filter = ();
my @sentences = ();

init();
run();

#** @function public run()
sub run {
    $bot = $CLI->getBot( 'generateRandom' => 1 );
    if ( $bot->isRiveScriptEnable() ) {
        $bot->setAddNewWriterUserIntoList();
    }
    $bot->requestAuthentication();
    $bot->show();
    # Return an empty  'Cocoweb::User::List' object
    $usersList = $bot->getUsersList();
    for ( my $count = 1; $count <= $CLI->maxOfLoop(); $count++ ) {
        message( "Loop $count / " . $CLI->maxOfLoop() );
        $bot->setTimz1($count);
        if ( $count % 160 == 39 ) {
            $bot->requestCheckIfUsersNotSeenAreOffline();
        }
        if ( $count % 28 == 9 ) {
            #This request is necessary to activate the server side time counter.
            $bot->searchChatRooms();
            checkBadNicknames();
        }
        $bot->requestMessagesFromUsers();
        $bot->riveScriptLoop();
        sleep $CLI->delay();
    }
    info("The $Bin script was completed successfully.");
}


# $bot->requestWriteMessage( $userWanted, $message );

sub checkBadNicknames {
    $usersList = $bot->requestUsersList();
    return if !defined $usersList;
    my $user_ref = $usersList->all();
    foreach my $nickid ( keys %$user_ref ) {
        next if exists $nickid2process{$nickid};
        my $name = $user_ref->{$nickid}->{'mynickname'};
        $user_ref->{$nickid}->{'mynickname'} = 1;
        next if !exists $nicknames2filter{$name};
        print "$name\n";
    }
}

sub getSentence {
    my @res = ();
    my @message = ();
    my $words = '';
    for my $i (0 .. scalar( @sentences ) -1 ) {
        my $words_ref = $sentences[$i];
        my $j = randum( scalar @$words_ref -1 );
        if ( length($words) < 1 ) {
            $words = $words_ref->[$j];
        } else {
            my $p = getPunctuation();
            $words = $words . $p . ' ' . $words_ref->[$j];
        }
        my $r = randum(10);
        next if $r > 2; 
        push @message, $words;
        $words = '';
    }
    push @message, $words if length($words) > 0;
    print Dumper \@message;
}

sub getPunctuation {
    my $r = randum(4);
    my $p;
    if ($r == 0 ) {
        $p = '.';
    } elsif ( $r == 1 ) {
        $p = ' ;'
    } elsif ( $r == 2 ) {
        $p = ',';
    } else {
        $p = '!';
    }
    print "$r: $p\n";
    return $p;
}


#** function public init ()
# @brief Perform some initializations
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getOpts( 'enableLoop' => 1 );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    my $filename = 'plain-text/nicknames-to-filter.txt';
    my $file = Cocoweb::Config->instance()->getConfigFile( $filename, 'Plaintext' );
    my $lines_ref = $file->getAll();
    foreach my $nickname (@$lines_ref) {
        $nicknames2filter{$nickname} = 1;
    }

    $filename = 'plain-text/checks-womens-with-man-names.txt';
    $file = Cocoweb::Config->instance()->getConfigFile( $filename, 'Plaintext' );
    my $lines_ref = $file->getAll();
    my $index = 0;
    foreach my $line ( @$lines_ref ) {
        chomp($line);
        if ( $line =~m{^-+$} ) {
            $index++;
            next;
        }
        push @{$sentences[$index]}, $line;

    }
    #print Dumper \@sentences;
    getSentence();

    exit;
}

#** function public HELP_MESSAGE ()
# @brief Display help message
sub HELP_MESSAGE {
    print STDOUT $Script . ', just create a bot.' . "\n";
    $CLI->printLineOfArgs();
    $CLI->HELP();
    print <<END;

Examples:
$Script -v -x 1000 -s W -V rivescript/woman-replies
END
    exit 0;
}

#** function public VERSION_MESSAGE ()
# @brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2017-07-30');
}

