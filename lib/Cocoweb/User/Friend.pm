# @created 2012-03-19
# @date 2012-03-24
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2012
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
package Cocoweb::User::Friend;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use Cocoweb::User;
use Cocoweb::User::BaseList;
use base 'Cocoweb::User::BaseList';

__PACKAGE__->attributes('count');

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults( 'all' => {}, 'count' => 0 );
}

sub populate {
    my (
        $self,       $myage, $mysex,  $citydio, $mynickID,
        $mynickname, $myXP,  $mystat, $myver
    ) = @_;
    my $users_ref = $self->all();
    my $count     = $self->count();
    $count++;
    $self->count($count);
    $users_ref->{$count} = Cocoweb::User->new(
        'mynickID'   => $mynickID,
        'myage'      => $myage,
        'mysex'      => $mysex,
        'citydio'    => $citydio,
        'mynickname' => $mynickname,
        'myXP'       => $myXP,
        'mystat'     => $mystat,
        'myver'      => $myver
    );
}

1;

