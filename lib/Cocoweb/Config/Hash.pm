# @created 2012-02-18
# @date 2012-02-18
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
package Cocoweb::Config::Hash;
use strict;
use warnings;
use Cocoweb;
use Carp;
use Data::Dumper;

use base 'Cocoweb::Config::Base';

__PACKAGE__->attributes('all');

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    croak error('Error: Required parameter "hash" is missing!')
      if !exists $args{'hash'};
    $self->all( $args{'hash'} );
}
1;
