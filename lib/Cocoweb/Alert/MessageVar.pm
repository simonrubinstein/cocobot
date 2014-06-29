# @brief
# @created 2014-06-28
# @date 2014-06-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2014
# Id: $Id$
# $Revision$
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
package Cocoweb::Alert::MessageVar;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use FindBin qw($Script $Bin);
use base 'Cocoweb::Object::Singleton';
use Cocoweb;
__PACKAGE__->attributes('daysOfTheWeek');

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    my @days = (
        'dimanche', 'lundi',    'mardi', 'mercredi',
        'jeudi',    'vendredi', 'samedi'
    );
    $instance->daysOfTheWeek( \@days );
    info( "instance of " . ref($instance) );
    return $instance;
}

sub DESTROY {
}

#
sub substitution {
    my ( $self, $string, $user ) = @_;
    $string =~ s{(\[%(_[^\]]+_)%\])}{$self->$2($user)}ge;
    return $string;
}

#
sub _DAY_OF_THE_WEEK_ {
    my ( $self, $user ) = @_;
    ( undef, undef, undef, undef, undef, undef, my $wday, undef, undef )
        = localtime();
    my $days_ref = $self->daysOfTheWeek();
    return $days_ref->[$wday];

}

sub _TITLE_ {
    my ( $self, $user ) = @_;
    if ( $user->isMan() ) {
        return 'Monsieur';
    }
    else {
        if ( $user->myage() >= 30 ) {
            return 'Madame';
        }
        else {
            return 'Mademoiselle';
        }
    }

}

sub _NICKNAME_ {
    my ( $self, $user ) = @_;
    return $user->mynickname();

}

sub _AGE_ {
    my ( $self, $user ) = @_;
    return $user->myage();

}

sub AUTOLOAD {
    my ( $self, $user ) = @_;
    our $AUTOLOAD;
    my $method = $AUTOLOAD;
    error("$method method was not found!");
    return '';
}

1;
