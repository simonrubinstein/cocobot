#!/usr/bin/perl
# @created 2012-12-31
# @date 2013-01-16
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
#
# copyright (c) Simon Rubinstein 2010-2013
# Id: $Id $
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
use Cocoweb::Alert;
my $CLI;

init();
run();

sub run {
    my $cocoAlert        = Cocoweb::Alert->instance();
    my $enableAlerts_ref = $cocoAlert->getAlerts();
    foreach my $alert (@$enableAlerts_ref) {
        my $transport = $alert->getString('transport');
        next if $transport ne 'XMPP';
        print "$transport\n";

        my $alertSender;
        $alertSender = $cocoAlert->getTransport( $alert->getString('transport'),
            $alert->getString('recipient') );
        next if $@ or !defined $alertSender;

        #$alertSender->messageSend("Test");

        my $timeout = 10;
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            alarm $timeout;
            info("Set Alarm");
            $alertSender->messageSend("test");
            alarm 0;
        };
        if ($@) {
            if ( $@ eq "alarm\n" ) {
                error(  'timeout after ' 
                      . $timeout
                      . ' seconds. ('
                      . ref($alertSender)
                      . ')' );
            }
            else {
                error($@);
            }
        }

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
 $Script [-v -d ]
  -v          Verbose mode
  -d          Debug mode
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2012-12-31');
}

