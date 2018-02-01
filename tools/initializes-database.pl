#!/usr/bin/env perl
# @created 2012-03-11
# @date 2018-02-01
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2018
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
use Cocoweb::DB::Base;
my $CLI;

init();
run();

sub run {
    my $res = confirmation( 'Are you sure you want to drop all the tables'
            . ' from the database and recreate it' );
    if ( $res eq 'no' ) {
        print STDOUT "The operation was aborted.\n";
        return;
    }
    my $DB = Cocoweb::DB::Base->getInstance();
    $DB->connect();
    $DB->dropTables();
    $DB->createTables();

    # initializes 'towns' table
    my ( $town_ref, $towns ) = $DB->getInitTowns();
    undef $town_ref;
    $town_ref = $towns->all();
    foreach my $name (@$town_ref) {
        $DB->insertTown($name);
    }
    undef $town_ref;

    # initializes 'ISPs' table
    my ( $ISP_ref, $ISPConf ) = $DB->getInitISPs();
    undef $ISP_ref;
    $ISP_ref = $ISPConf->all();
    foreach my $name (@$ISP_ref) {
        $DB->insertISP($name);
    }
    undef $ISP_ref;

    # initializes 'citydios' table
    my $allZipCodes = Cocoweb::Config->instance()
        ->getConfigFile( 'zip-codes.txt', 'ZipCodes' );
    $allZipCodes->extract();
    my $citydio2zip_ref = $allZipCodes->citydio2zip();
    foreach my $citydio ( keys %$citydio2zip_ref ) {
        my $townzz = $citydio2zip_ref->{$citydio};
        $DB->insertCitydio( $citydio, $townzz );
    }

    info("The $Bin script was completed successfully.");
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts();
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
 $Script [-v -d -a myavatar -p mypass]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $Cocoweb::VERSION (2018-02-01) 
     Copyright (C) 2010-2018 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

