# @brief
# @created 2012-03-30
# @date 2012-03-30
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
package Cocoweb::DB::MySQL;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use POSIX;

use Cocoweb;
use base 'Cocoweb::DB::Base';

__PACKAGE__->attributes( 'datasource', 'username', 'password'  );

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->initializesMemberVars();
    $instance->attributes_defaults(
        'datasource' => '',
        'username'   => '',
        'password'   => '',
    );
    return $instance;
}

##@method readConfiguration($config)
#@brief Initializes some variables from the configuration file.
#@param $config A 'Cocoweb::Config::File' object
sub setConfig {
    my ( $self, $config) = @_;
    $self->SUPER::setConfig($config);
}



1;
