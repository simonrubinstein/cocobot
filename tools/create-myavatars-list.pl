#!/usr/bin/perl
# @created 2015-01-06
# @date 2016-06-19
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
use Date::Parse;
use FindBin qw($Script $Bin);
use Carp;
use Data::Dumper;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
use Cocoweb::MyAvatar::File;
my $CLI;
my $myavatarFiles;
use IO::File;

init();
run();

##@method void run()
sub run {
    my $filename = $myavatarFiles->fileList();

    # Reads all avatars availables from "var/myavatar/run" directory
    my $myavatars_ref = $myavatarFiles->getRun();
    my $fh = IO::File->new( $filename, 'w' );
    confess Cocoweb::error("open($filename) was failed: $!")
        if !defined $fh;

    my $count = 0;
    foreach my $val (@$myavatars_ref) {
        croak Cocoweb::error("$val if bad")
            if $val !~ m{^(\d{9})([A-Z]{20})$};
        my ( $myavatar, $mypass ) = ( $1, $2 );
        print $fh $myavatar . $mypass . "\n";
        $count++;
    }
    confess Cocoweb::error("close() return $!") if !$fh->close();
    message(
        "The file $filename has been successfully written. ($count lines)");
}

##@method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts();
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $myavatarFiles = Cocoweb::MyAvatar::File->instance();
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Generates "var/myavatar/list.txt " file.
This file contains the list of available avatares.
Usage: 
 $Script [-v -d ]
  -v            Verbose mode
  -d            Debug mode
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-06-19');
}

