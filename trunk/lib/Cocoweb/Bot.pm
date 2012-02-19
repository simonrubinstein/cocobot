# @created 2012-02-19
# @date 2012-02-19
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
package Cocoweb::Bot;
use strict;
use warnings;
use Carp;

use Cocoweb;
use Cocoweb::Request;
use Cocoweb::User;

use base 'Cocoweb::Object';
__PACKAGE__->attributes( 'user', 'request' );

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    my $user    = Cocoweb::User->new(%args);
    my $request = Cocoweb::Request->new();
    $self->attributes_defaults( 'user' => $user, 'request' => $request );
}

##@method process()
sub process {
    my ($self)  = @_;
    my $user    = $self->user();
    my $request = $self->request();
    $request->getCityco($user);
    $user->validatio( $request->getValue('urlprinc') );
    $user->initial( $request->getValue('avaref') );
    $self->request()->agir( $user,
            '40'
          . $user->pseudonym() . '*'
          . $user->year()
          . $user->sex()
          . $user->citydio()
          . $user->myavatar()
          . $user->password() );
}

sub show {
    my ($self) = @_;
    $self->user()->show();
}
1;
