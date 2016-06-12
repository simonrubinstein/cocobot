# @created 2012-03-24
# @date 2012-03-25
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
package Cocoweb::User::Wanted;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use base 'Cocoweb::User::Base';


##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    $args{'mynickname'} = 'nobody' if !exists $args{'mynickname'};
    $args{'myage'}      = 89       if !exists $args{'myage'};
    $args{'mysex'}      = 1        if !exists $args{'mysex'};
    $args{'mynickID'}   = 999999   if !exists $args{'mynickID'};
    $args{'citydio'}    = 30915    if !exists $args{'citydio'};
 
    $self->attributes_defaults(
        'mynickname'  => $args{'mynickname'},
        'myage'       => $args{'myage'},
        'mysex'       => $args{'mysex'},
        'mynickID'    => $args{'mynickID'},
        'citydio'     => $args{'citydio'},
        'mystat'      => 0,
        'myXP'        => 0,
        'myver'       => 0, 
        'infuz'       => '',
        'code'        => '',
        'ISP'         => '',
        'status'      => 0,
        'premium'     => 0,  
        'level'       => 0,
        'since'       => 0,
        'town'        => ''
    );
}

1;
