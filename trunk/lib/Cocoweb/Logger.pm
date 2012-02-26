# @brief
# @created 2012-02-17
# @date 2011-02-26
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2012
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
package Cocoweb::Logger;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use Data::Dumper;
use Term::ANSIColor;
use strict;
use warnings;

sub init {
    my ( $class, $instance ) = @_;
    return $instance;
}

sub message {
    my ( $self, $message ) = @_;
    $self->_log( 'info', $message );
}

sub info {
    my ( $self, $message ) = @_;
    $self->_log( 'info', $message );
}

sub debug {
    my ( $self, $message ) = @_;
    $self->_log( 'debug', $message );
}

sub warning {
    my ( $self, $message ) = @_;
    $self->_log( 'warning', $message );
}

sub error {
    my ( $self, $message ) = @_;
    $self->_log( 'err', $message );
}

sub _log {
    my ( $self, $priority, $message ) = @_;
    my ( $pack, $filename, $line, $function );
    ( $pack, $filename, $line, $function ) = caller(3);
    $function = '' if !defined $function;
    ( $pack, $filename, $line ) = caller(2);
    my $identity = "file: $Script; method: $function; line: $line";
    my @dt       = localtime(time);
    $message =~s{\%}{}g;
    my $string =
      sprintf( "%02d:%02d:%02d [$identity][$$]: ($priority) $message\n",
        $dt[2], $dt[1], $dt[0] );
    if ( $priority eq 'err' or $priority eq 'emerg' ) {
        print STDERR colored( $string, 'bold red' );
    }
    elsif ( $priority eq 'warning' ) {
        print STDOUT colored( $string, 'yellow' );
    }
    elsif ( $priority eq 'info' ) {
        print STDOUT colored( $string, 'green' );
    }
    elsif ( $priority eq 'debug' ) {
        print STDOUT colored( $string, 'bold blue' );
    }
    else {
        print STDOUT $string;
    }
}

1;

