#!/usr/bin/env perl
# @brief This script runs SQL queries from the database.
# @created 2012-05-18
# @date 2016-11-13
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
use Cocoweb::Config;
use Cocoweb::User::CheckInput;
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
    my $userCheck = Cocoweb::User::CheckInput->instance();
    my $opt_ref
        = $CLI->getMinimumOpts( 'argumentative' => 'l:c:s:t:i:y:OPIf:F:HN' );
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
        if ( $opt eq 'c' ) {
            foreach my $code (@vals) {
                die 'Bad infuz code: ' . $code 
                    if !$userCheck->checkVoteCode($code);
            }
        } elsif ( $opt eq 'y' ) {
            foreach my $age (@vals) {
                die 'Bad age: ' . $age 
                    if !$userCheck->checkAge($age);
            }
        }
        elsif ( $opt eq 's' ) {
            my @tmp = ();
            foreach my $sex (@vals) {
                if ( $sex eq 'M' ) {
                    push @tmp, 1, 6;
                }
                elsif ( $sex eq 'W' ) {
                    push @tmp, 2, 7;
                } else {
                    push @tmp, $sex;
                }
            }
            @vals = @tmp;
            foreach my $sex (@vals) {
                die 'Bad sex: ' . $sex 
                    if !$userCheck->checkSex($sex);
            }
        }
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
    push @args, '__IleDeFrance', 1 if exists $opt_ref->{'I'};
    push @args, '__paris',       1 if exists $opt_ref->{'P'};
    $DB = Cocoweb::DB::Base->getInstance();
    my $filtersStr = $opt_ref->{'f'} if exists $opt_ref->{'f'};

    if ( defined $filtersStr ) {
        my @filters = split( /,/, $filtersStr );
        my %nicknames2filter = ();
        foreach my $f (@filters) {
            my $file = Cocoweb::Config->instance()
                ->getConfigFile( $f, 'Plaintext' );
            my $lines_ref = $file->getAll();
            foreach my $nickname (@$lines_ref) {
                $nicknames2filter{$nickname} = 1;
            }
        }
        push @args, '__nicknames2filter', [ keys %nicknames2filter ];
    }

    my $output = 0;
    if ( exists $opt_ref->{'H'} ) {
        $output = 1;
    }
    unshift @args, $output;

    my $filtersCode = 0;
    if ( exists $opt_ref->{'F'} ) {
        $filtersCode = $opt_ref->{'F'};
    }
    unshift @args, $filtersCode;

    my $isOnlyNicks = 0;
    if ( exists $opt_ref->{'N'} ) {
        $isOnlyNicks = $opt_ref->{'N'};
    }
    unshift @args, $isOnlyNicks;

}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, Search for users in database according to different criteria. 
Usage: 
 $Script [-v -d] [-l logins -c codes -t towns -i ISPs -s sex -y age -O -I -P -F 1 -H -N]
  -l logins   A single nickname or more nicknames separated by commas.
              (i.e. -l RomeoKnight or -l RomeoKnight,Delta,UncleTom 
  -c codes    A single nickname code or more nickame codes separated by commas.
              (i.e. -c cZj or -c cZj,23m,Wcl,PXd) 
  -t towns    A single town or more towns separated by commas.
              (i.e. -t "FR- Paris" or -t "FR- Aulnay-sous-bois","FR- Sevran"
  -i ISPs     A single ISP or more ISPs separated by commas.
              (i.e. -i "Free SAS" or -i "Orange","Free SAS")
  -s sex      Gender. W: woman; M: man;
                      2: woman without an avatar; 7: woman with an avatar
                      1: man without an avatar; 6: man with an avatar
  -y age      An age in years
  -O          Users who are connected.
  -I          Research in the Iles-de-France only.
  -P          Search pseudo who entered a zip code Paris
  -v          Verbose mode
  -d          Debug mode
  -f filters  Filters
  -F 1        Enable custime filter
  -H          Displays the results in HTML
  -N          Displays nicknames only

Examples:
db-search.pl -c WcL,PXd,uyI,0fN,rs6 
db-search.pl -l BetterDays%
db-search.pl -l BlueVelvet,Babycat
db-search.pl -t "FR- Aulnay-sous-bois","FR- Sevran" -s 2 -i "Free SAS"
db-search.pl -c JiC -i "Orange"
db-search.pl -O -I -s 2,7 -f plain-text/nicknames-to-filter.txt
db-search.pl -P -I -s 2 -f plain-text/nicknames-to-filter.txt,plain-text/nicknames-to-filter-2.txt -y 30 -F 1
db-search.pl -f plain-text/nicknames-to-filter.txt -N -s W -l Homme%

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-11-13');
}

