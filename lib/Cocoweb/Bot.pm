# @brief
# @created 2012-02-19
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
package Cocoweb::Bot;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use Cocoweb;
use Cocoweb::Request;
use Cocoweb::User::Connected;
use base 'Cocoweb::Object';
__PACKAGE__->attributes( 'user', 'request', );

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    my $user    = Cocoweb::User::Connected->new(%args);
    my $request = Cocoweb::Request->new();
    $self->attributes_defaults(
        'user'    => $user,
        'request' => $request,
    );
}

##@method void process()
sub process {
    my ($self)  = @_;
    my $user    = $self->user();
    my $request = $self->request();
    $request->getCityco($user);
    $user->validatio( $request->getValue('urlprinc') );
    $user->initial( $request->getValue('avaref') );
    $self->request()->firsty($user);
}

##@method void writeMessage()
sub writeMessage {
    my ( $self, $message, $destinationId ) = @_;
    $self->request()->writus( $self->user(), $message, $destinationId );
}

##@method hashref searchUser($pseudonym)
sub searchUser {
    my ( $self, $pseudonym ) = @_;
    my $pseudonyms_ref =
      $self->request()->searchPseudonym( $self->user(), $pseudonym );
    return $pseudonyms_ref;
}

##@methode object getUsersList()
#@brief Request and returns the list of connected users
#@return object A 'User::HashList' object
sub getUsersList {
    my ($self) = @_;
    return $self->request()->getUsersList( $self->user() );
}

##method void getUserInfo()
#@brief Get the number of days remaining until the end of
#       the Premium subscription.
#       This method works only for user with a Premium subscription
#
sub getUserInfo {
    my ($self) = @_;
    $self->request()->getUserInfo( $self->user() );
}

##@method void searchCode()
#@brief Search a nickname from his code of 3 characters 
#       This method works only for user with a Premium subscription
#@param object $user An 'User object' object
#@param string $code A nickname code (i.e. WcL)
sub searchCode {
    my ( $self, $code ) = @_;
    $self->request()->searchCode( $self->user(), $code );
}

##@method string infuz($nickId)
#@brief Retrieves information about an user
#       for Premium subscribers only
sub infuz {
    my ( $self, $nickId ) = @_;
    $self->request()->infuz( $self->user(), $nickId );
}

##@method hashref getInfuz($nickId)
#@brief Retrieves information about an user
#       for Premium subscribers only
sub getInfuz {
    my ( $self, $nickId ) = @_;
    $self->request()->getInfuz( $self->user(), $nickId );
}

##@method void actuam($user)
#@brief Get the list of contacts, nicknamed 'amiz'
#@return string
sub actuam {
    my ($self) = @_;
    $self->request()->actuam( $self->user() );
}

##@method boolean isPremiumSubscription()
#@brief Verifies whether the user has a subscription premium
#@return boolean 1 if the user has a subscription premium or 0 otherwise
sub isPremiumSubscription {
    my ($self) = @_;
    return $self->user()->isPremiumSubscription();
}

##@method void show()
#@brief Prints some member variables to the console of the user object
sub show {
    my ($self) = @_;
    $self->user()->show();
}

##@method void display()
#@brief Prints on one line some member variables to the console
#       of the user object
sub display {
    my ($self) = @_;
    $self->user()->display();
}

##@method void lancetimer($user)
#@brief Method that periodically performs requests to the server
sub lancetimer {
    my ($self) = @_;
    $self->request()->lancetimer( $self->user() );
}

1;

