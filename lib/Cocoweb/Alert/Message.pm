# @brief
# @created 2013-01-19
# @date 2016-06-25
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
package Cocoweb::Alert::Message;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Cocoweb;
use Cocoweb::File;
use Cocoweb::Config;
use Cocoweb::Alert::MessageVar;
use base 'Cocoweb::Object';
my $rs;

__PACKAGE__->attributes( 'name', 'write' );

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    my $conf = $args{'conf'};
    $self->attributes_defaults(
        'name'  => $conf->getString('name'),
        'write' => $conf->getArray('write')
    );
}

##@method void process($bot, $alarmCount, $users_ref)
#@brief Sends messages to users.
#@param object $bot A Cocoweb::Bot object
#@param integer $alarmCount The alarm number from 1 to n
#@param arrayref $users_ref List of users to process
sub process {
    my ( $self, $bot, $alarmCount, $users_ref, $isDryRun ) = @_;
    foreach my $user (@$users_ref) {
        #$user->messageSentTime(0);
        $user->isMessageWasSent(0);
        my $write_ref = $self->write();
        my $str;
        foreach my $write (@$write_ref) {
            if ( substr( $write, 0, 8 ) eq 'file:///' ) {
                my $file = Cocoweb::Config->instance()
                    ->getConfigFile( substr( $write, 8 ), 'Plaintext' );
                $str = $file->getRandomLine();
            }
            elsif ( substr( $write, -1, 1 ) eq '|' ) {
                my @strings = split( /\|/, $write );
                if ( scalar(@strings) == 1 ) {
                    $str = $strings[0];
                }
                else {
                    $str = $strings[ randum( scalar(@strings) ) ];
                }
            }
            else {
                $str = $write;
            }
            my $var = Cocoweb::Alert::MessageVar->instance();
            $str = $var->substitution( $str, $user );
            my $logStr = sprintf(
                "%-19s => %-19s %-4s $str",
                $bot->user()->mynickname(),
                $user->mynickname(), $user->code()
            );

            if ($isDryRun) {
                info($logStr);
            }
            else {
                $bot->requestWriteMessage( $user, $str );
                writeLog( 'alert-messages', $logStr );
            }
        }
    }
}

1;

