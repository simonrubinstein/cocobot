# @brief
# @created 2016-07-01
# @date 2016-07-03
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
use base 'Cocoweb::Object';

__PACKAGE__->attributes( 'name', 'repliesdir', 'rs' );

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    my $conf    = $args{'conf'};
    my $dirpath = Cocoweb::Config->instance()
        ->getDirPath( $conf->getString('repliesdir') );
    $self->attributes_defaults(
        'name'       => $conf->getString('name'),
        'repliesdir' => $dirpath
    );
}

sub getRiveScript {
    my $self = shift;
    return $self->rs() if defined $self->rs();
    my $rs = RiveScript->new();
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
        my $message = unacString($messageLast);
        my $reply = $rs->reply( 'localuser', $message );
        if ( $reply eq 'ERR: No Reply Matched' ) {
            error("No reply matched for $messageLast");
            next;
        }
        utf8::encode($reply);
        my $logStr = ref($self);
        my $logStr = sprintf(
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

