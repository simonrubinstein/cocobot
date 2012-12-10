# @brief
# @created 2012-12-10 
# @date 2012-12-10
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
package Cocoweb::Alert::XMPP;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Cocoweb;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes( 'name', 'hostname', 'port', 'componentname', 'connectiontype', 'tls', 'username', 'password', 'to' );


##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->attributes_defaults(
        'name'   => '',
        'hostname'   => '',
        'port'   => '',
        'componentname'   => '',
        'connectiontype'   => '',
        'tls'   => '',
        'username'   => '',
        'password'   => '',
        'to'   => '',
    );
    return $instance;
}

1;
