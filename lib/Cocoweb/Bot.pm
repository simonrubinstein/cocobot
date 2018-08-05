##@file Bot.pm
# @brief
# @created 2012-02-19
# @date 2018-08-05
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2017
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
__PACKAGE__->attributes( 'user', 'request', 'rivescript',
    'riveScriptGenderAnswer' );

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

    my $rivescript;
    if ( exists $args{'riveScriptDir'}
        and length( $args{'riveScriptDir'} ) > 0 )
    {
        require "Cocoweb/RiveScript.pm";
        $rivescript = Cocoweb::RiveScript->new();
        $rivescript->loadDirectory( $args{'riveScriptDir'} );
        $rivescript->sortReplies();
        delete $args{'riveScriptDir'};

    }
    my $riveScriptGenderAnswer;
    if ( exists $args{'riveScriptGenderAnswer'}
        and length( $args{'riveScriptGenderAnswer'} ) > 0 )
    {
        $riveScriptGenderAnswer = $args{'riveScriptGenderAnswer'};
        delete $args{'riveScriptGenderAnswer'};
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
        'user'                   => $user,
        'request'                => $request,
        'rivescript'             => $rivescript,
        'riveScriptGenderAnswer' => $riveScriptGenderAnswer
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
#@return object A 'CocoWeb::Response' object
sub requestWriteMessage {
    my ( $self, $userWanted, $message ) = @_;
    return $self->request()->writus( $self->user(), $userWanted, $message );
}

##@method void requestToBeAFriend($userWanted)
#@brief Send a friend request
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
sub requestToBeAFriend {
    my ( $self, $userWanted ) = @_;
    return $self->request()->amigo( $self->user(), $userWanted );
}

##@method void reportAbuse($userWanted)
#@brief Report a user for abusive behavior
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
sub reportAbuse {
    my ( $self, $userWanted ) = @_;
    return $self->request()->reportAbuse( $self->user(), $userWanted );
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
    return $self->request()->getUserInfo( $self->user() );
}

##@method void requestCodeSearch()
#@brief Search a nickname from his code of 3 characters
#@param string $code A nickname code (i.e. WcL)
#@return object A 'CocoWeb::Response' object
sub requestCodeSearch {
    my ( $self, $code ) = @_;
    return $self->request()->searchCode( $self->user(), $code );
}

##@method object requestUserInfuz($user)
#@brief Retrieves information about an user
#       for Premium subscribers only
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#@return object A 'CocoWeb::Response' object
sub requestUserInfuz {
    my ( $self, $user ) = @_;
    $user = $self->user() if !defined $user;
    return $self->request()->infuz( $self->user(), $user );
}

##@method void actuam($user)
#@brief Get the list of contacts, nicknamed 'amiz'
#@return object A 'CocoWeb::Response' object
sub actuam {
    my ($self) = @_;
    return $self->request()->actuam( $self->user() );
}

##@method object searchChatRooms()
#@return object A 'CocoWeb::Response' object
sub searchChatRooms {
    my ($self) = @_;
    return $self->request()->cherchasalon( $self->user() );
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

## @method public requestInfuzForNewUsers()
# @brief Search "informz" string for new users.
sub requestInfuzForNewUsers {
    my ($self)     = @_;
    my $users_ref  = $self->request()->usersList()->all();
    my $count      = 0;
    my $userCount  = 0;
    my $infuzCount = 0;

    # 1 second = 1,000,000 microseconds
    my $microsecondsPause1  = $self->request->infuzPause1();
    my $microsecondsPause2  = $self->request->infuzPause2();
    my $infuzNotToFastRegex = $self->request->infuzNotToFastRegex();
    my $infuzMaxOfTriesAfterPause
        = $self->request->infuzMaxOfTriesAfterPause();
    debug("infuzNotToFastRegex: $infuzNotToFastRegex");
    my $numberOfUsers = scalar( keys %$users_ref );
    debug( 'Starts the loop: ' . $numberOfUsers . ' users.' );

    foreach my $niknameId ( keys %$users_ref ) {
        $userCount++;
        my $user = $users_ref->{$niknameId};

#debug("$userCount) mynickname: " . $user->mynickname() . '; isNew: ' . $user->isNew() . '; infuz: ' . $user->infuz() );
        next if !$user->isNew() and $user->infuz() !~ $infuzNotToFastRegex;
        if ( $user->infuz() =~ $infuzNotToFastRegex ) {
            debug( 'Retry infuz request for ' . $user->mynickname() );
        }
        my $infuzRequest = 1;
        while ($infuzRequest) {
            if ( $infuzCount > 0 and $microsecondsPause1 > 0 ) {
                debug( 'Pause between each infuz request:  '
                        . $microsecondsPause1 );
                Time::HiRes::usleep($microsecondsPause1);
            }
            $infuzCount++;
            $user = $self->request()->infuz( $self->user(), $user );
            last if $self->beenDisconnected();
            debug(
                "---> $userCount/$numberOfUsers; infuzCount: $infuzCount <---"
            );
            if ( $self->request()->isInfuzNotToFast() ) {
                debug( 'isInfuzNotToFast: '
                        . $self->request()->isInfuzNotToFast() );
                if ( ++$infuzRequest > $infuzMaxOfTriesAfterPause ) {
                    warning("The infuz request has definitely failed");
                    $infuzRequest = 0;
                }
                else {
                    debug( 'Another pause between each infuz request:  '
                            . $microsecondsPause2 );
                    Time::HiRes::usleep($microsecondsPause2);
                }
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

## @method public void getMyInfuz()
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

##@method void setTimz1($timz1)
#@param integer $timz1
sub setTimz1 {
    my ( $self, $timz1 ) = @_;
    $self->request()->timz1($timz1);
}

##@method boolean isRiveScriptEnable()
#@brief Check if RiveScript is enbale
#@return boolean 1 if RiveScript is enable or 0 otherwise
sub isRiveScriptEnable {
    my ($self) = @_;
    if ( defined $self->{'rivescript'} ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method void setAddNewWriterUserIntoList()
#@brief If a user writes to the bot and the user does not exist
#       in the list, so we add the new user in the list.
sub setAddNewWriterUserIntoList {
    my ($self) = @_;
    $self->request()->isAddNewWriterUserIntoList(1);
}

## @method public beenDisconnected()
# @brief Checks whether the bot has been disconnected or not
# @return boolean 1 The bot has been disconnected.
sub beenDisconnected {
    my ($self) = @_;
    return $self->request()->beenDisconnected();
}

##@method void riveScriptLoop()
sub riveScriptLoop {
    my ($self) = @_;
    return if !defined $self->{'rivescript'};
    my $rs        = $self->{'rivescript'};
    my $users_ref = $self->request()->usersList()->all();
    foreach my $niknameId ( keys %$users_ref ) {
        my $user = $users_ref->{$niknameId};
        next if !$user->isMessageWasSent();
        $user->isMessageWasSent(0);
        my $messageLast = trim( $user->messageLast() );
        next if !defined $messageLast or length($messageLast) == 0;
        info( $user->mynickname() . '> ' . $messageLast );
        if ( defined $self->{'riveScriptGenderAnswer'} ) {
            if ( $self->{'riveScriptGenderAnswer'} eq 'W' and $user->isMan() )
            {
                debug( "No answers given to male profiles: "
                        . $user->mynickname() );
                next;
            }
            elsif ( $self->{'riveScriptGenderAnswer'} eq 'M'
                and $user->isWoman() )
            {
                debug( "No answers given to women profiles: "
                        . $user->mynickname() );
                next;
            }
        }
        my $reply = $rs->reply( 'localuser', $messageLast );
        if ( $reply eq 'ERR: No Reply Matched' ) {
            error("No reply matched for $messageLast");
            next;
        }
        info(     $self->user()->mynickname() . ' > '
                . $user->mynickname() . ' => '
                . $reply );
        $self->requestWriteMessage( $user, $reply );
    }
}

1;

