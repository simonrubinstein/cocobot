# @brief
# @created 2012-02-19
# @date 2014-03-03
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2014
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
use Time::HiRes qw(usleep);
use Cocoweb;
use Cocoweb::Config;
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
    my $isAvatarRequest;
    if ( exists $args{'isAvatarRequest'} and $args{'isAvatarRequest'} ) {
        $isAvatarRequest = 1;
        delete $args{'isAvatarRequest'};
    }
    else {
        $isAvatarRequest = 0;
    }
    if ( exists $args{'mynickname'} ) {
        if ( substr( $args{'mynickname'}, 0, 8 ) eq 'file:///' ) {
            my $file
                = Cocoweb::Config->instance()
                ->getConfigFile( substr( $args{'mynickname'}, 8 ),
                'Plaintext' );
            $args{'mynickname'} = $file->getRandomLine();
        }
        elsif ( $args{'mynickname'} =~ m{:} ) {
            my @nicknames = split( /:/, $args{'mynickname'} );
            $args{'mynickname'}
                = $nicknames[ randum( scalar @nicknames ) - 1 ];
        }
    }
    my $user    = Cocoweb::User::Connected->new(%args);
    my $request = Cocoweb::Request->new(
        'logUsersListInDB' => $logUsersListInDB,
        'isAvatarRequest'  => $isAvatarRequest
    );
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

##@method setUsersList(users_ref)
#@brief Set a list of users
#@param object $users_ref A 'Cocoweb::User::List' object
sub setUsersList {
    my ( $self, $users_ref ) = @_;
    $self->request()->usersList($users_ref);
}

##@method void requestAuthentication()
#@brief Performs authentication requests to the server Coco.fr
sub requestAuthentication {
    my ($self)  = @_;
    my $user    = $self->user();
    my $request = $self->request();
    $request->getCitydioAndTownzz($user);
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

##@method void requestToBeAFriend($userWanted)
#@brief Send a friend request
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
sub requestToBeAFriend {
    my ( $self, $userWanted ) = @_;
    $self->request()->amigo( $self->user(), $userWanted );
}

##@method void reportAbuse($userWanted)
#@brief Report a user for abusive behavior
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
sub reportAbuse {
    my ( $self, $userWanted ) = @_;
    $self->request()->reportAbuse( $self->user(), $userWanted );
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
    my ($self)     = @_;
    my $users_ref  = $self->request()->usersList()->all();
    my $count      = 0;
    my $userCount  = 0;
    my $infuzCount = 0;

    # 1 second = 1,000,000 microseconds
    my $microsecondsPause1 = 950000;
    my $microsecondsPause2 = 450000;
    my $numberOfUsers      = scalar( keys %$users_ref );
    foreach my $niknameId ( keys %$users_ref ) {
        $userCount++;
        my $user = $users_ref->{$niknameId};
        next if !$user->isNew();
        my $infuzRequest = 1;
        while ($infuzRequest) {
            if ( $infuzCount > 0 ) {
                debug( 'Pause between each infuz request:  '
                        . $microsecondsPause1 );
                Time::HiRes::usleep($microsecondsPause1);
            }
            $infuzCount++;
            $user = $self->request()->infuz( $self->user(), $user );
            debug(
                "---> $userCount/$numberOfUsers; infuzCount: $infuzCount <---"
            );
            if ( $self->request()->isInfuzNotToFast() ) {
                debug( 'isInfuzNotToFast: '
                        . $self->request()->isInfuzNotToFast() );
                $infuzRequest = 0 if ++$infuzRequest > 10;
                debug( 'Another pause between each infuz request:  '
                        . $microsecondsPause2 );
                Time::HiRes::usleep($microsecondsPause2);
            }
            else {
                #The infuz request was successful.
                $infuzRequest = 0;
            }
        }
        next if !defined $user;
        $count++;
        my $infuz = $user->infuz();
        $infuz =~ s{\n}{; }g;
        moreDebug('(*) new nickname: '
                . $user->mynickname()
                . ' infuz: '
                . $infuz );
    }
    info( $count . ' new "infuz" was requested and returned' ) if $count > 0;
}

sub getMyInfuz {
    my ($self) = @_;
    $self->request()->infuz( $self->user(), $self->user() );
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

##@method void setUsersOfflineInDB()
sub setUsersOfflineInDB {
    my ($self) = @_;
    $self->request()->usersList()->setUsersOfflineInDB();
}

sub setTimz1 {
    my ( $self, $timz1 ) = @_;
    $self->request()->timz1($timz1);
}

1;

