#!/usr/bin/perl
# @brief
# @created 2012-05-18
# @date 2013-12-10 
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
use Carp;
use Data::Dumper;
use Term::ANSIColor;
use Time::HiRes;
$Term::ANSIColor::AUTORESET = 1;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::DB::Base;
use Cocoweb::File;
my $DB;
my $CLI;
my @args = ();

init();
run();

##@method void run()
sub run {
    $DB->initialize();
    $DB->displaySearchUsers(@args);
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 'l:c:s:t:i:y:OP' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    my $nicknames = $opt_ref->{'l'} if exists $opt_ref->{'l'};

    my %opt2name = (
        'l' => 'nickname',
        'c' => 'code',
        's' => 'mysex',
        't' => 'town',
        'i' => 'ISP',
        'y' => 'myage'
    );

    foreach my $opt ( keys %opt2name ) {
        next if !exists $opt_ref->{$opt};
        my @vals = split( /,/, $opt_ref->{$opt} );
        die "$opt was not found" if !exists $opt2name{$opt};
        my $name = $opt2name{$opt};
        if ( scalar(@vals) == 1 ) {
            push @args, $name, $vals[0];
        }
        else {
            push @args, $name, \@vals;
        }
    }
    if ( scalar @args == 0 ) {
        print STDERR "Please enter search parameters.\n";
        HELP_MESSAGE();
        exit;
    }
    push @args, '__usersOnline', 1 if exists $opt_ref->{'O'};
    push @args, '__IleDeFrance', 1 if exists $opt_ref->{'P'};
    $DB = Cocoweb::DB::Base->getInstance();
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, Search for users in database according to different criteria. 
Usage: 
 $Script [-v -d] [-l logins -c codes -t towns -i ISPs -s sex -y age -O]
  -l logins   A single nickname or more nicknames separated by commas.
              (i.e. -l RomeoKnight or -l RomeoKnight,Delta,UncleTom 
  -c codes    A single nickname code or more nickame codes separated by commas.
              (i.e. -c cZj or -c cZj,23m,Wcl,PXd) 
  -t towns    A single town or more towns separated by commas.
              (i.e. -t "FR- Paris" or -t "FR- Aulnay-sous-bois","FR- Sevran"
  -i ISPs     A single ISP or more ISPs separated by commas.
              (i.e. -i "Free SAS" or -i "Orange","Free SAS")
  -s sex      Gender. 2: woman without an avatar; 7: woman with an avatar
                      1: man without an avatar; 6: man with an avatar
  -y age      An age in years
  -O          Users who are connected.
  -P          Research in the Iles-de-France only.
  -v          Verbose mode
  -d          Debug mode

Examples:
db-search.pl -c WcL,PXd,uyI,0fN,rs6 
db-search.pl -l BetterDays%
db-search.pl -l BlueVelvet,Babycat
db-search.pl -t "FR- Aulnay-sous-bois","FR- Sevran" -s 2 -i "Free SAS"
db-search.pl -c JiC -i "Orange"

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2013-12-10');
}

