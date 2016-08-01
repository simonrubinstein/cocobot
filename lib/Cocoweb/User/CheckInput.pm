# @created 2016-07-26
# @date 2016-07-31
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

__PACKAGE__->attributes( 'infuz-regex', 'nickname-regex', 'minimum-age', 'zip-code-regex', 'sex-regex' );

##@method void init(%args)
sub init {
    my ( $class, $instance ) = @_;
    my $conf = Cocoweb::Config->instance()
        ->getConfigFile( 'user-check-input.conf', 'File' );
    $instance->attributes_defaults(
        'infuz-regex'    => $conf->getRegex('infuz-regex'),
        'nickname-regex' => $conf->getRegex('nickname-regex'),
        'minimum-age'    => $conf->getInt('minimum-age'),
        'maximum-age'    => $conf->getInt('maximum-age'),
        'zip-code-regex' => $conf->getRegex('zip-code-regex'),
        'sex-regex'      => $conf->getRegex('sex-regex'),
    );
    return $instance;
}

##@method boolean checkVoteCode($code)
#@param string $code A three-character code (i.g.: WcL, PXd, uyI, 0fN)
#@return boolean 1 if code is valid premium or 0 otherwise
sub checkVoteCode {
    my ( $self, $code ) = @_;
    if ( $code =~ m{$self->{'infuz-regex'}} ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean checkNickname($nickname)
#@param string $nickname
#@return boolean 1 if nickname is valid premium or 0 otherwise
sub checkNickname {
    my ( $self, $nickname ) = @_;
    if ( $nickname =~ m{$self->{'nickname-regex'}} ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean checkAge($age)
#@param interger $age
#@return boolean 1 if age is valid premium or 0 otherwise
sub checkAge {
    my ( $self, $age ) = @_;
    if ( $age >= $self->{'minimum-age'} and $age <= $self->{'maximum-age'} ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean checkZipCode($zipCode)
#@param string $zipCode
#@return boolean 1 if zip code is valid premium or 0 otherwise
sub checkZipCode {
    my ( $self, $zipCode ) = @_;
    if ( $zipCode =~ m{$self->{'zipcode-regex'}} ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean checkSex($zipCode)
#@param string $sex
#@return boolean 1 if sex code is valid premium or 0 otherwise
sub checkSex {
    my ( $self, $sex ) = @_;
    if ( $sex =~ m{$self->{'sex-regex'}} ) {
        return 1;
    }
    else {
        return 0;
    }
}



1;

