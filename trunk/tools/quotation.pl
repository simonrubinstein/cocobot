#!/usr/bin/perl
# @created 2013-11-24
# @date 2013-11-24
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2013
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

init();
run();

sub run {

    my $filename = '/tmp/quotations.txt';
    my $fh = IO::File->new( $filename, 'w' );
    die error("open($filename) was failed: $!") if !defined $fh;

    my $quotations = Cocoweb::Config->instance()
        ->getConfigFile( 'quotations.txt', 'Plaintext' );

    my $lines_ref = $quotations->all();
    my @quotations = ();
    foreach my $quote ( sort @$lines_ref ) {
        push @quotations, trim($quote);
    }

    
    my $str = '';
    my %unique = ();
    foreach my $quote ( sort @quotations ) {
        $quote = trim($quote);
        if (exists $unique{$quote}) {
            warning("$quote quote already exists");
            next;
        }
        $str .= $quote . '|';
        $unique{$quote} = 1;
        print $fh $quote . "\n";
    }

    die error("close($filename) was failed: $!") if !$fh->close();

    my $filenameOneline = '/tmp/quotations-one-line.txt';
    $fh = IO::File->new( $filenameOneline, 'w' );
    die error("open($filenameOneline) was failed: $!") if !defined $fh;
    print $fh $str . "\n";
    die error("close($filenameOneline) was failed: $!") if !$fh->close();

    message("Files $filename and $filenameOneline were generated.");



    return;
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
 $Script [-v -d ]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2013-11-11');
}

