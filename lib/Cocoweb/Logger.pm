# @brief
# @created 2012-02-17
# @date 2011-04-09
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
use Cocoweb::File;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use Data::Dumper;
use IO::File;
use Term::ANSIColor;
use strict;
use warnings;

__PACKAGE__->attributes( 'dirname', 'filename', 'fh', 'writeLogInFile' );

sub init {
    my ( $class, $instance ) = @_;
    my $path = getVarDir() . '/logs';
    croak 'mkdir(' . $path . ') was failed: ' if !-d $path and !mkdir($path);
    $instance->dirname($path);
    $instance->filename('');
    $instance->fh(undef);
    $instance->writeLogInFile(0);
    return $instance;
}

sub message {
    my ( $self, $message ) = @_;
    print STDOUT $message . "\n" if exists $ENV{'TERM'};
    $self->_writeLog( $message . "\n" );
}

sub info {
    my ( $self, $message ) = @_;
    $self->_log( 'info', $message );
}

sub debug {
    my ( $self, $message ) = @_;
    $self->_log( 'debug', $message );
}

sub moreDebug {
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
    $message =~ s{\%}{}g;
    my $hourStr = sprintf( '%02d:%02d:%02d', $dt[2], $dt[1], $dt[0] );
    $self->_display( $priority, "$message $hourStr [$identity]\n" )
      if exists $ENV{'TERM'};
    $self->_writeLog( "[$$][method: $function; line: $line] " 
          . $hourStr
          . " ($priority) $message\n" );
}

##@method _display($priority, $string)
sub _display {
    my ( $self, $priority, $string ) = @_;

    #$string = $message ."\n";
    if ( $priority eq 'err' or $priority eq 'emerg' ) {
        print STDERR colored( $string, 'bold red' );
    }
    elsif ( $priority eq 'warning' ) {
        print STDOUT colored( $string, 'yellow' );
    }
    elsif ( $priority eq 'info' ) {
        print STDOUT colored( $string, 'green' );

        #print STDOUT $string;
    }
    elsif ( $priority eq 'debug' ) {
        print STDOUT colored( $string, 'bold blue' );

        #print STDOUT $string;
    }
    else {
        print STDOUT $string;
    }
}

##@method string _getLogFilename()
sub _getLogFilename {
    my ($self) = @_;
    my @dt = localtime(time);
    return sprintf(
        '%02d-%02d-%02d_' . $Script . '.log',
        ( $dt[5] + 1900 ),
        ( $dt[4] + 1 ), $dt[3]
    );
}

##@method void _openFileLog()
sub _openFileLog {
    my ($self) = @_;
    my $pathname = $self->dirname() . '/' . $self->filename();
    my $fh = IO::File->new( $pathname, 'a' );
    confess error("open($pathname) was failed: $!")
      if !defined $fh;
    $self->fh($fh);
}

##@methdo void _writeLog($message)
sub _writeLog {
    my ( $self, $message ) = @_;
    return if !$self->writeLogInFile();
    my $filename = $self->_getLogFilename();
    my $fh       = $self->fh();
    if ( !defined $fh ) {
        $self->filename($filename);
        $self->_openFileLog();
        $fh = $self->fh();
    }
    elsif ( $filename ne $self->filename() ) {
        $self->filename($filename);
        if ( defined $fh ) {
            confess error("close() return $!") if !$fh->close();
        }
        $self->_openFileLog();
        $fh = $self->fh();
    }

    print $fh $message;

}

1;

