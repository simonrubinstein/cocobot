# @brief
# @created 2016-07-01
# @date 2017-01-22 
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2017
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
package Cocoweb::Alert::RiveScript;
use strict;
use warnings;
use utf8;
no utf8;
use RiveScript;
use Carp;
use Data::Dumper;
use Encode;
use Cocoweb;
use Cocoweb::File;
use Cocoweb::Config;
use Cocoweb::RiveScript;
use base 'Cocoweb::Object';

__PACKAGE__->attributes( 'name', 'repliesdir', 'rs' );

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    my $conf    = $args{'conf'};
    my $dirpath = $conf->getString('repliesdir');
    $self->attributes_defaults(
        'name'       => $conf->getString('name'),
        'repliesdir' => $dirpath
    );
}

##@method object getRiveScript()
#@brief Instantiates the "Cocoweb::RiveScript" object.
#@return A "Cocoweb::RiveScript"  object
sub getRiveScript {
    my $self = shift;
    return $self->rs() if defined $self->rs();
    my $rs = new Cocoweb::RiveScript();
    $self->rs($rs);

    #$rs->loadFile( $self->repliesdir() );
    $rs->loadDirectory( $self->repliesdir() );
    $rs->sortReplies();
    return $rs;
}

##@method void process($bot, $alarmCount, $users_ref)
#@brief Sends messages to users.
#@param object $bot A Cocoweb::Bot object
#@param integer $alarmCount The alarm number from 1 to n
#@param arrayref $users_ref List of users to process
sub process {
    my ( $self, $bot, $alarmCount, $users_ref, $isDryRun ) = @_;
    my $rs = $self->getRiveScript();
    foreach my $user (@$users_ref) {
        $user->isMessageWasSent(0);
        my $messageLast = trim( $user->messageLast() );
        next if !defined $messageLast or length($messageLast) == 0;
        my $reply = $rs->reply( 'localuser', $messageLast );
        if ( $reply eq 'ERR: No Reply Matched' ) {
            warning("No reply matched for $messageLast");
            next;
        }
        elsif ( $reply eq 'ERR: No Reply Found' ) {
            warning("No reply found for $messageLast");
            #$bot->requestWriteMessage( $user, ';)' );
            next;
        }
        my $logStr = ref($self);
        $logStr = sprintf(
            "%-19s => %-19s %-4s $logStr $reply",
            $bot->user()->mynickname(),
            $user->mynickname(), $user->code()
        );

        if ($isDryRun) {
            info($logStr);
        }
        else {
            $bot->requestWriteMessage( $user, $reply );
            writeLog( 'alert-messages', $logStr );
        }
    }
}

1;

