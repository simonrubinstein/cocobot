#!/usr/bin/perl
# @created 2012-02-22
# @date 2012-02-24
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
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
use Getopt::Std;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::Bot;
my $sex;

init();
run();

sub run {
    my $bot = Cocoweb::Bot->new( 'generateRandom' => 1 );
    $bot->process();
    my $userFound_ref = $bot->getUsersList();

    my @codes = ( 'login', 'sex', 'old', 'city', 'id', 'niv', 'ok', 'stat' );
    my %max = ();
    foreach my $k (@codes) {
        $max{$k} = 0;
    }
    my %sexCount = ();
    foreach my $id ( keys %$userFound_ref ) {
        my $login_ref = $userFound_ref->{$id};
        foreach my $k ( keys %$login_ref ) {
            my $l = length( $login_ref->{$k} );
            if ( $l > $max{$k} ) {
                $max{$k} = $l;
            }
        }
        $sexCount{ $login_ref->{'sex'} }++;
    }

    my $count = 0,;
    foreach my $id ( keys %$userFound_ref ) {
        my $login_ref = $userFound_ref->{$id};
        if ( defined $sex ) {
            if ( $sex == 1 ) {
                next if $login_ref->{'sex'} != 1 and $login_ref->{'sex'} != 6;
            }
            elsif ( $sex == 2 ) {
                next if $login_ref->{'sex'} != 2 and $login_ref->{'sex'} != 7;
            }
            else {
                next;
            }
        }
        my $line = '';
        foreach my $k (@codes) {
            $line .=
              '! ' . sprintf( '%-' . $max{$k} . 's', $login_ref->{$k} ) . ' ';
        }
        $line .= '!';
        print STDOUT $line . "\n";
        $count++;
    }

    my ( $womanCount, $manCount ) = ( 0, 0 );
    foreach my $sex ( keys %sexCount ) {
        my $cnt = $sexCount{$sex};
        if ( $sex == 2 or $sex == 7 ) {
            $womanCount += $cnt;
        }
        elsif ( $sex == 1 or $sex == 6 ) {
            $manCount += $cnt;
        }
        else {
            die error("$sex sex code was not found");
        }
    }
    print STDOUT "- $count users displayed\n";
    print STDOUT "- Number of woman: $womanCount\n";
    print STDOUT "- Number of man:   $manCount\n";
    info("The $Bin script was completed successfully.");
}

## @method void getOptions()
sub init {
    my %opt;
    getopts( 'dvs:', \%opt ) || HELP_MESSAGE();
    $Cocoweb::isVerbose = 1         if exists $opt{'v'};
    $Cocoweb::isDebug   = 1         if exists $opt{'d'};
    $sex                = $opt{'s'} if exists $opt{'s'};
}

