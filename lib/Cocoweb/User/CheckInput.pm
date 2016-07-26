# @created 2016-03-26
# @date 2016-03-26
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
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
package Cocoweb::User::CheckInput;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;
use FindBin qw($Script);
use Cocoweb;
use Cocoweb::File;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes('infuz-regex');

##@method void init(%args)
sub init {
    my ( $class, $instance ) = @_;
    my $conf = Cocoweb::Config->instance()
        ->getConfigFile( 'user-check-input.conf', 'File' );
    $instance->attributes_defaults(
        'infuz-regex' => $conf->getRegex('infuz-regex') );
    return $instance;
}

##@method boolean checkInfuzCode($code)
#@param string $code A three-character code (i.g.: WcL, PXd, uyI, 0fN)
#@return boolean 1 if code is valid premium or 0 otherwise
sub checkInfuzCode {
    my ( $self, $code ) = @_;
    if ( $code =~ m{$self->{'infuz-regex'}} ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;

