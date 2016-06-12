#!/usr/bin/perl
# @brief This script checks that the town codes froms '_townCount.pl'
#        file exist in the file 'towns.txt'.
# @created 2012-03-11
# @date 2012-12-08
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
use FindBin qw($Script $Bin);
use Data::Dumper;
use IO::File;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::File;
use Cocoweb::CLI;
use Cocoweb::DB::Base;
my $CLI;
my $DB;
my $dumpTownsFilename = '_townCount.pl';
my $dumpISPsFilename  = '_ISPCount.pl';

init();
run();

##@method void run()
sub run {
    importFromDatabase();
    #return;
    my ( $town_ref, $townConf ) = $DB->getInitTowns();
    my $townCount_ref;
    eval { 
        $townCount_ref = fileToVars($dumpTownsFilename);
    };
    if ($@) {
        $DB->connect() if !defined $DB->dbh();
        $DB->getAllTowns();
        $townCount_ref = $DB->town2id();
        dumpToFile( $townCount_ref, $dumpTownsFilename );
    }

    my ( $count, $found, $notFound ) = ( 0, 0, 0 );
    foreach my $town ( sort keys %$townCount_ref ) {
        $count++;
        if ( exists $town_ref->{$town} ) {
            $found++;
            next;
        }
        message( $town . ' => ' . $townCount_ref->{$town} );
        $notFound++;
    }
    message( 'Number total of town code(s)    : ' . $count );
    message( 'Number of town code(s) found    : ' . $found );
    message( 'Number of town code(s) not found: ' . $notFound );

    my ( $ISP_ref, $ISPConf ) = $DB->getInitISPs();
    my $ISPCount_ref = fileToVars($dumpISPsFilename) if -f $dumpISPsFilename;
    if (!defined $ISPCount_ref) {
        $DB->connect() if !defined $DB->dbh();
        $DB->getAllIPSs();
        $ISPCount_ref = $DB->ISP2id();
    }
    ( $count, $found, $notFound ) = ( 0, 0, 0 );
    foreach my $isp ( sort keys %$ISPCount_ref ) {
        $count++;

        #message( $isp . ' => ' . $ISPCount_ref->{$isp} );
        if ( exists $ISP_ref->{$isp} ) {
            $found++;
            next;
        }
        $ISP_ref->{$isp} = 1;
        message($isp);
        $notFound++;
    }
    message( 'Number total of IPS code(s)    : ' . $count );
    message( 'Number of ISP code(s) found    : ' . $found );
    message( 'Number of ISP code(s) not found: ' . $notFound );

    if ( $notFound > 0 ) {
        my $filename = '/tmp/ISPs.txt';
        my $fh = IO::File->new( $filename, 'w' );
        die error("open($filename) was failed: $!") if !defined $fh;
        foreach my $isp ( sort { lc($a) cmp lc($b) } keys %$ISP_ref ) {
            print $fh $isp . "\n";
        }
        die error("close($filename) was failed: $!") if !$fh->close();
    }

    info("The $Bin script was completed successfully.");
}

sub importFromDatabase {

}
sub xximportFromDatabase {
    my $config = Cocoweb::Config->instance()->getConfigFile('zip-codes.txt', 'ZipCodes');
    my $c = $config->getCityco(75005);
    print "$c\n";
    print " - " . $config->getZipAndTownFromCitydio(30932) . "\n";
    print " - " . $config->getZipAndTownFromCitydio(36450) . "\n";
    print " - " . $config->getZipAndTownFromCitydio(30919) . "\n";
    print " - " . $config->getZipAndTownFromCitydio(30932) . "\n";



}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    $DB = Cocoweb::DB::Base->getInstance();
    my $opt_ref = $CLI->getMinimumOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
}

##@method void HELP_MESSAGE()
#@brief Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
This script checks that the town codes froms '_townCount.pl' file
exist in the file 'towns.txt'.
Usage: 
 $Script [-v -d]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-12-08');
}

