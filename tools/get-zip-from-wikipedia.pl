#!/usr/bin/perl
# @brief This script tries to get a zip code from city name from the
#        website of Wikipedia.
# @created 2012-03-14
# @date 2012-04-02
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

#!/usr/bin/perl
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
use Cocoweb::File;
use Cocoweb::Request;
use HTML::Parser;

my $url = 'http://fr.wikipedia.org/w/index.php?search=';
my $req;
my $CLI;
my $DB;
my $lastTag      = '';
my $zipCodeFound = 0;
my $zipCode      = 0;
my $townFileR;
my $townFileW;
my $htmlFilename = 'wikipedia.html';
my %townFile     = ();
my @townOrder    = ();
my $town_ref     = ();
my $townConf;
my $townCodeSearched;
my $htmlParser;
my $doYouWriteHTMLFile = 0;

init();
run();
info("The $Bin script was completed successfully.");

##@method void run()
#@brief
sub run {
    if ($townCodeSearched) {
        GetZipFromWikipedia($townCodeSearched);
        return;
    }
    my $townCount_ref = fileToVars('_townCount.pl');
    my ( $count, $notFound, $found ) = ( 0, 0, 0 );
    foreach my $town ( sort keys %$townCount_ref ) {
        $count++;
        if ( exists $town_ref->{$town} ) {
            next;
        }
        my $zip = GetZipFromWikipedia($town);
        if ( defined $zip ) {
            $found++;
            die error("$zip code not found in configuration file")
              if !exists $townFile{$zip}->{'town'};
            die error("$town already exists")
              if exists $townFile{$zip}->{'town'}->{$town};
            $townFile{$zip}->{'town'}->{$town} = 1;
        }
        else {
            $notFound++;
        }
    }
    message( 'Number of zip code found: ' . $found );
    message( 'Number of zip code not found: ' . $notFound );
    writeTowns();
}

##@method integer GetZipFromWikipedia($town)
#@brief Get the zip code on Wikipedia.
sub GetZipFromWikipedia {
    my ($town) = @_;
    my $city = $town;
    $city =~ s{^[A-Z]{2}\-\s}{}xms;
    $city =~ s{\-(l|d)\ (a|e|i|o|u|y|h)}{-$1'$2}xms;
    $city =~ s{du-rhne}{du-rhône};
    $city =~ s{sur-sane}{sur-saône};
    $city =~ s{^L a}{L'a}g;
    debug( 'Performs an HTTP request to the URL ' . $url . $city );
    my $response = $req->execute( 'GET', $url . $city );
    my $res = $response->decoded_content();
    if ($doYouWriteHTMLFile) {
        my $fh;
        die error("open($htmlFilename) was failed: $!")
          if !open( $fh, '>', $htmlFilename );
        print $fh $res;
        die error("close($htmlFilename) was failed: $!")
          if !close $fh;

    }
    ( $lastTag, $zipCodeFound, $zipCode ) = ( '', 0, 0 );
    $htmlParser->parse($res);
    $htmlParser->eof();

    if ( $zipCode =~ m{^(\d\d)\d\d\d$} ) {
        my $zip = $1;
        if ( $zip >= 97 ) {
            $zip = substr( $zipCode, 0, 3 );
        }
        message('Zip code that corresponds to the town "' 
              . $town
              . '" code is: '
              . $zip );
        return $zip;
    }
    else {
        warning( 'The postal code of the city ' . $town . ' was not found' );
        return;
    }
}

##@method void start($tagname, $attr)
sub start {
    my ( $tagname, $attr ) = @_;
    $lastTag = $tagname;
    return if $tagname ne 'a';
    return if !exists $attr->{'title'} or $attr->{'title'} ne 'Code postal';
    $zipCodeFound = 1;
    debug("Class zip code was found.");
}

##@method void text($string)
sub text {
    return if !$zipCodeFound or $lastTag ne 'td' or $zipCode != 0;
    my $string = shift;
    debug($string);
    return if $string !~ m{^(\d{5}).*$};
    $zipCode = $1;
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 't:w' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $townCodeSearched = $opt_ref->{'t'} if exists $opt_ref->{'t'};
    $doYouWriteHTMLFile = 1 if exists $opt_ref->{'w'};
    $DB  = Cocoweb::DB::Base->getInstance();
    $req = Cocoweb::Request->new();
    ( $town_ref, $townConf ) = $DB->getInitTowns();
    $townFileR = $townConf->pathname();
    $townFileW = $townFileR;
    $townFileW =~ s{^.*/}{/tmp/};
    info( 'The new file is written in the following path: ' . $townFileW );
    readTowns();
    $htmlParser = HTML::Parser->new(
        'api_version' => 3,
        start_h       => [ \&start, "tagname, attr" ],
        text_h        => [ \&text, 'dtext' ]
    );
}

##@method void readTowns()
#@brief Reads the file 'towns.txt' and insert rows in a hash table.
sub readTowns {
    my $fh;
    info("open $townFileR file");
    die "$!" if !open( $fh, '<', $townFileR );
    my ( $zip, $name );
    foreach my $line (<$fh>) {
        chomp($line);
        $line = trim($line);
        next if $line =~ m{^\s*$};
        if ( $line =~ m{^#} ) {
            error("$line raw is incorrect!")
              if $line !~ m{^\#\s?(\d+):\s(.*)$}xms;

            $zip  = $1;
            $name = $2;
            push @townOrder, $zip;

            $townFile{$zip} = { 'name' => $name, 'town' => {} };
        }
        else {
            die error("No section found for $line!")
              if !defined $zip
                  or !defined $name;
            die error("The town $line code already exists!")
              if exists $townFile{$zip}->{'town'}->{$line};
            $townFile{$zip}->{'town'}->{$line} = 1;
        }

    }
    close $fh;
}

##@method void writeTowns()
#@brief Writes the file '/tmp/towns.txt' from a hash table.
sub writeTowns {
    my $fh;
    die "$!" if !open( $fh, '>', $townFileW );
    foreach my $zip (@townOrder) {
        die error("$zip was not found") if !exists $townFile{$zip};
        print $fh '# ' . $zip . ': ' . $townFile{$zip}->{'name'} . "\n";
        foreach my $town ( sort keys %{ $townFile{$zip}->{'town'} } ) {
            print $fh $town . "\n";
        }
        print $fh "\n";
    }
    close $fh;
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
This script tries to get a zip code from city name from the website of Wikipedia.
Usage: 
 $Script [-v -d -t townCode]
  -v          Verbose mode
  -d          Debug mode
  -t townCode A town code (i.e. 'FR- Avignon', 'FR- Lille', ...)
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-04-01');
}

