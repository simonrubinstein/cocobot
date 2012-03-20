# @created 2012-01-26
# @date 2012-03-20
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
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
package Cocoweb::User;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use base 'Cocoweb::User::Base';

__PACKAGE__->attributes( 'isNew', 'isView', 'hasChange' );

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    die error("Missing argument")
      if !exists $args{'mynickname'}
          or !exists $args{'myage'}
          or !exists $args{'mysex'}
          or !exists $args{'mynickID'}
          or !exists $args{'citydio'}
          or !exists $args{'mystat'}
          or !exists $args{'mystat'};

    $self->attributes_defaults(
        'mynickname' => $args{'mynickname'},
        'myage'      => $args{'myage'},
        'mysex'      => $args{'mysex'},
        'mynickID'   => $args{'mynickID'},
        'citydio'    => $args{'citydio'},
        'mystat'     => $args{'mystat'},
        'myXP'       => $args{'myXP'},
        'myver'      => $args{'myver'},
        'isNew'      => 1,
        'isView'     => 1,
        'hasChange'  => 0
    );
}

1;
