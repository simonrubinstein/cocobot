# @created 2012-01-26 
# @date 2012-01-29 
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# $Id$
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

use base 'Cocoweb::Object';
 
 __PACKAGE__->attributes('pseudonym', 'year', 'sex', 'zip', 'nickId', 'password');

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults(
        'pseudonym' => 'nobody',
        'year'      => 89,
        'sex'       => 'male',
        'zip'       => 75001,
        'nickId'    => 99999,
        'password'  => 0,
    );


}

sub show {
    my $self = shift;
    print STDOUT 'pseudonym: ' . $self->pseudonym . "\n";
    print STDOUT 'year:      ' . $self->year . "\n";
    print STDOUT 'sexe:      ' . $self->sex . "\n";
    print STDOUT 'zip:       ' . $self->zip . "\n";
    print STDOUT 'nickId:    ' . $self->nickId . "\n";
    print STDOUT 'password:  ' . $self->password . "\n";

}



1;
