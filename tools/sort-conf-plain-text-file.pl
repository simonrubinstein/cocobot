#!/usr/bin/perl
# @created 2013-11-24
# @date 2016-06-21
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
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
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
use Cocoweb::Config;
my $CLI;
my $myTime;
my $messagePath;
my $alertMessagePath;
my $textFilename;
my $maxSize;
my $defaultFilename = 'plain-text/quotations.txt';

init();
run();

sub run {
    my $filename = $textFilename;
    $filename =~ s{^.*/}{/tmp/};
    my $fh = IO::File->new( $filename, 'w' );
    die error("open($filename) was failed: $!") if !defined $fh;

    my $plainText = Cocoweb::Config->instance()
        ->getConfigFile( $textFilename, 'Plaintext' );

    my $lines_ref   = $plainText->all();
    my @linesOfText = ();
    foreach my $string ( sort @$lines_ref ) {
        push @linesOfText, trim($string);
    }

    my %unique = ();
    foreach my $string ( sort @linesOfText ) {
        $string = trim($string);
        if ( exists $unique{$string} ) {
            warning("$string quote already exists");
            next;
        }
        if ( defined $maxSize and length($string) > $maxSize ) {
            warning(  '"'
                    . $string . '": '
                    . 'string length exceeds maximum length of '
                    . $maxSize
                    . ' characters' );
            next;

        }
        $unique{$string} = 1;
        print $fh $string . "\n";
    }

    die error("close($filename) was failed: $!") if !$fh->close();

    message(
        "File '$filename' was generated from " . $plainText->pathname() );

    return;
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 'f:x:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $maxSize = $opt_ref->{'x'} if exists $opt_ref->{'x'};
    if ( defined $maxSize ) {
        if ( $maxSize !~ m{^\d+$} ) {
            HELP_MESSAGE();
            exit;
        }
    }
    $textFilename = $opt_ref->{'f'}             if exists $opt_ref->{'f'};
    $textFilename = 'plain-text/quotations.txt' if !defined $textFilename;
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, sorts a plain text configuration file.
Usage: 
 $Script [-v -d -f filename -x maxSize]
  -v          Verbose mode
  -d          Debug mode
  -f filename Plain text filename ($defaultFilename by default)
  -x maxSize  Maximum number of characters.     

Examples:
sort-conf-plain-text-file.pl
sort-conf-plain-text-file.pl -f plain-text/nicknames-to-filter.txt
sort-conf-plain-text-file.pl -f plain-text/nicknames-bot.txt -x 16
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-06-21');
}

