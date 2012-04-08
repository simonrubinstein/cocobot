# @brief
# @created 2012-02-19
# @date 2012-04-08
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

##@method void init($args)
sub init {
    my ( $self, %args ) = @_;
    my $logUsersListInDB;
    if ( exists $args{'logUsersListInDB'} ) {
        $logUsersListInDB = 1;
        delete $args{'logUsersListInDB'};
    }
    else {
        $logUsersListInDB = 0;
    }
    my $user = Cocoweb::User::Connected->new(%args);
    my $request =
      Cocoweb::Request->new( 'logUsersListInDB' => $logUsersListInDB );
    $self->attributes_defaults(
        'user'    => $user,
        'request' => $request,
    );
}

##@method object getUsersList()
#@brief Returns list of users
#@return object A 'Cocoweb::User::List' object
sub getUsersList {
    my ($self) = @_;
    return $self->request()->usersList();
}

##@method void requestAuthentication()
#@brief Performs authentication requests to the server Coco.fr
sub requestAuthentication {
    my ($self)  = @_;
    my $user    = $self->user();
    my $request = $self->request();
    $request->getCityco($user);
    $user->validatio( $request->getValue('urlprinc') );
    $user->initial( $request->getValue('avaref') );
    $self->request()->firsty($user);
}

##@method void requestWriteMessage($userWanted, $message)
#@brief Performs a request to write a message to another user
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
#@param string $message The message to write to the user
sub requestWriteMessage {
    my ( $self, $userWanted, $message ) = @_;
    $self->request()->writus( $self->user(), $userWanted, $message );
}

##@method object searchNickname($userWanted)
#@brief Search a nickname connected
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#@return object A CocoWeb::User
sub searchNickname {
    my ( $self, $userWanted ) = @_;
    return $self->request()->searchNickname( $self->user(), $userWanted );
}

##@methode object requestUsersList()
#@brief Request and returns the list of connected users
#@return object A 'Cocoweb::User::List' object
sub requestUsersList {
    my ($self) = @_;
    return $self->request()->getUsersList( $self->user() );
}

##method void requestConnectedUserInfo()
#@brief Get the number of days remaining until the end of
#       the Premium subscription.
#       This method works only for user with a Premium subscription
#
sub requestConnectedUserInfo {
    my ($self) = @_;
    $self->request()->getUserInfo( $self->user() );
}

##@method void requestCodeSearch()
#@brief Search a nickname from his code of 3 characters
#@param string $code A nickname code (i.e. WcL)
#@return object A 'CocoWeb::User' object
sub requestCodeSearch {
    my ( $self, $code ) = @_;
    return $self->request()->searchCode( $self->user(), $code );
}

##@method object requestUserInfuz($user)
#@brief Retrieves information about an user
#       for Premium subscribers only
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#@return object A 'CocoWeb::User::Wanted' object
sub requestUserInfuz {
    my ( $self, $user ) = @_;
    $user = $self->user() if !defined $user;
    return $self->request()->infuz( $self->user(), $user );
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

##@method void requestsChecksIfUserOffline($user)
sub requestsChecksIfUserOffline {
    my ( $self, $users ) = @_;
    $self->request()->isDead( $self->user(), $users );
}

##@method boolean isAuthenticated()
##@brief Checks whether bot the  is authenticated on the website Coco.fr
#@return boolean 1 if the user is authenticated, otherwise 0
sub isAuthenticated {
    my ($self) = @_;
    return $self->user()->isAuthenticated();
}

##@method requestInfuzForNewUsers()
#@brief Search "informz" string for new users.
sub requestInfuzForNewUsers {
    my ($self)    = @_;
    my $users_ref = $self->request()->usersList()->all();
    my $count     = 0;
    foreach my $niknameId ( keys %$users_ref ) {
        my $user = $users_ref->{$niknameId};
        next if !$user->isNew();
        $user = $self->request()->infuz( $self->user(), $user );
        next if !defined $user;
        $count++;
        my $infuz = $user->infuz();
        $infuz =~ s{\n}{; }g;
        moreDebug(
            '(*) new nickname: ' . $user->mynickname() . ' infuz: ' . $infuz );
    }
    info( $count . ' new "infuz" was requested and returned' );

}

##@method void requestMessagesFromUsers()
#@brief Returns the messages sent by other users
sub requestMessagesFromUsers {
    my ($self) = @_;
    $self->request()->requestMessagesFromUsers( $self->user() );
}

##@method void requestCheckIfUsersNotSeenAreOffline()
#@brief Checks if the not viewed users are offline
sub requestCheckIfUsersNotSeenAreOffline {
    my ($self) = @_;
    $self->request()->checkIfUsersNotSeenAreOffline( $self->user() );
}

##@method void setUserOfflineInDB()
sub setUserOfflineInDB {
    my ($self) = @_;
    $self->request()->usersList()->setUserOfflineInDB();
}

1;

