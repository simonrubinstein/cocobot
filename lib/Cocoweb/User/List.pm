# @created 2012-03-19
# @date 2016-08-04
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
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
package Cocoweb::User::List;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;
use Time::HiRes qw(usleep);

use Cocoweb;
use Cocoweb::File;
use Cocoweb::User;
use Cocoweb::User::BaseList;
use base 'Cocoweb::User::BaseList';
__PACKAGE__->attributes(

    # If true, register users list into database
    'logUsersListInDB',

    # A 'Cocoweb::DB::Base' object
    'DB',

    # Users list (array) that not appear in the list of connected
    'DBUsersOffline',

    # Delay in seconds before deleting a user no longer appears
    # in the list of connected.
    'removeListDelay',

    # Count the number of times the function searchCode() was called.
    'checkUserIsReallyOfflineCount',

    # If true, use search function of "vote code" to check
    # if users are disconnected
    'removeListSearchCode',

    # Time to pause between searchCode() requests
    'removeListSearchcodePause1',
    'removeListSearchcodePause2'

);

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    foreach my $name ( 'removeListDelay', 'removeListSearchCode',
        'removeListSearchcodePause1' )
    {
        croak error("$name is missing")
            if !exists $args{$name};
    }
    my $logUsersListInDB
        = ( exists $args{'logUsersListInDB'} and $args{'logUsersListInDB'} )
        ? 1
        : 0;
    my $DB;
    $DB = Cocoweb::DB::Base->getInstance() if $logUsersListInDB;
    $self->attributes_defaults(
        'all'                        => {},
        'logUsersListInDB'           => $logUsersListInDB,
        'DB'                         => $DB,
        'DBUsersOffline'             => [],
        'removeListDelay'            => $args{'logUsersListInDB'},
        'removeListSearchCode'       => $args{'removeListSearchCode'},
        'removeListSearchcodePause1' => $args{'removeListSearchcodePause1'},
        'removeListSearchcodePause2' => $args{'removeListSearchcodePause1'},
        'checkUserIsReallyOfflineCount' => 0
    );
}

##@method void populate($myage, $mysex, $citydio, $mynickID,
#                       $mynickname, $myXP, $mystat, $myver)
#@brief Adds or updates a user in the list
sub populate {
    my ($self,       $myage, $mysex,  $citydio, $mynickID,
        $mynickname, $myXP,  $mystat, $myver
    ) = @_;
    if ( $mynickname =~ m{^([^\(]+)\(\d+$} ) {
        debug("strip end of string: $mynickname to $1");
        $mynickname = $1;
    }
    my $users_ref = $self->all();
    my @args      = (
        'mynickID'   => $mynickID,
        'myage'      => $myage,
        'mysex'      => $mysex,
        'citydio'    => $citydio,
        'mynickname' => $mynickname,
        'myXP'       => $myXP,
        'mystat'     => $mystat,
        'myver'      => $myver
    );
    if ( exists $users_ref->{$mynickID} ) {
        my $user = $users_ref->{$mynickID};
        $user->dateLastSeen(time);

        #moreDebug(
        #    "The user $mynickname already exists: isNew:" . $user->isNew() );
        if ( $user->isNew() ) {
            $user->update(@args);
        }
        else {
            $user->checkAndupdate(@args);
            $user->isView(1);
        }
    }
    else {
        $users_ref->{$mynickID} = Cocoweb::User->new(@args);
    }
}

##@method void showUsersUnseen()
sub showUsersUnseen {
    my ($self) = @_;
    my $user_ref = $self->all();
    print STDOUT '! Last seen            '
        . '! NickID ! Nikcname          '
        . '! seconds! Min  !Hours!' . "\n";
    my $count = 0;
    foreach my $id (
        sort {
            $user_ref->{$b}->{'dateLastSeen'}
                <=> $user_ref->{$a}->{'dateLastSeen'}
        } keys %$user_ref
        )
    {
        my $user = $user_ref->{$id};
        next if $user->isView();

        my @dt        = localtime( $user->dateLastSeen() );
        my $deltaSec  = ( time - $user->dateLastSeen() );
        my $deltaMin  = $deltaSec / 60;
        my $deltaHour = $deltaMin / 60;
        my $dateStr   = timeToDate( $user->dateLastSeen() );
        my $line
            = sprintf( "! $dateStr " . '! %-6s !  %-16s ! %6d ! %4d ! %3d !',
            $user->mynickID(), $user->mynickname(), $deltaSec, $deltaMin,
            $deltaHour );

        print STDOUT $line . "\n";
        $count++;

    }
    print STDOUT "- $count user(s) displayed\n";
}

## @method purgeUsersUnseen($bot)
# @brief Purge users who have not been seen in the remote list for some time
# @param bot - required an Cocoweb:bot object
sub purgeUsersUnseen {
    my ( $self, $bot ) = @_;
    my $user_ref        = $self->all();
    my $removeListDelay = $self->removeListDelay();
    my ( $count, $countPurge ) = ( 0, 0 );
    $self->checkUserIsReallyOfflineCount(0);
    $self->removeListSearchcodePause2( $self->removeListSearchcodePause1() );
    my $DBUsersOffline_ref = $self->DBUsersOffline();
    my $userCount          = 0;
    foreach my $id (
        sort {
            $user_ref->{$a}->{'dateLastSeen'}
                <=> $user_ref->{$b}->{'dateLastSeen'}
        } keys %$user_ref
        )
    {
        $userCount++;
        my $user = $user_ref->{$id};
        next if $user->isView();
        $count++;
        my $delta = time - $user->dateLastSeen();
        next if $delta < $removeListDelay;
        my $dateStr = timeToDate( $user->dateLastSeen() );
        debug(    'Remove user '
                . $user->mynickID() . ' '
                . $user->mynickname()
                . '; last seen: '
                . $dateStr );

        if ( $self->_checkUserIsReallyOffline( $user, $bot ) ) {
            debug(    'Remove user '
                    . $user->mynickID() . ' '
                    . $user->mynickname() );
            delete $user_ref->{$id};
            push @$DBUsersOffline_ref, $user->DBUserId()
                if $self->logUsersListInDB();
            $countPurge++;
        }
        else {
            debug(    'Do not Remove user '
                    . $user->mynickID() . ' '
                    . $user->mynickname() );
        }
    }
    info("$countPurge users were purged on a $count users unseen")
        if $countPurge > 0;
    info(     'Remove user: '
            . $self->checkUserIsReallyOfflineCount()
            . ' requests to searchCode(); Total users:'
            . $userCount
            . '; users unseen: '
            . $count
            . '; deleted users: '
            . $countPurge );
}

#@method private _checkUserIsReallyOffline($user, $bot)
# @param user - required an Cocoweb::User object
# @param bot - required an Cocoweb:bot object
# @retval
sub _checkUserIsReallyOffline {
    my ( $self, $user, $bot ) = @_;
    return 1 if !defined $bot or !$self->removeListSearchCode();
    my $code = $user->code();
    if ( !checkInfuzCode($code) ) {
        error("$code infuz code is invalid");
        return 1;
    }
    my $count = $self->checkUserIsReallyOfflineCount();
    my $pause = $self->removeListSearchcodePause2();
    if ( $count > 0 and $pause > 0 ) {
        debug( '(' . ($count + 1) . ') ' . 'Remove user: pause between searchCode() request: ' . $pause );
        Time::HiRes::usleep($pause);
    }
    $self->checkUserIsReallyOfflineCount( ++$count );
    my $response;
    eval { $response = $bot->requestCodeSearch($code); };
    if ($@) {
        error("requestCodeSearch($code) was failed: $@");
        $self->removeListSearchcodePause2( $pause * 2 );
        # FIXME accept a couple errors before 
        $self->removeListSearchCode(0);
        return 1;
    }
    my $userFound = $response->userFound();
    return 1 if !defined $userFound;
    debug(    "($count) Remove user: requestCodeSearch() returns: "
            . $userFound->mynickname() . '; '
            . $userFound->mynickID() . '; '
            . $userFound->mysex() . '; '
            . $userFound->myage() . '; '
            . $userFound->citydio() );
    if ( $userFound->myage() eq '99' ) {
        debug("($count) Remove user:  age 99 = offline ");
        return 1;
    }
    if ( $userFound->mynickID() ne $user->mynickID() ) {
        debug("($count) Remove user:  mynickID differ = offline ");
        return 1;
    }

    my @args = (
        'mynickname' => $userFound->mynickname(),
        'myage'      => $userFound->myage(),
        'citydio'    => $userFound->citydio(),
        'mysex'      => $userFound->mysex(),
        'mynickID'   => $userFound->mynickID(),
    );
    $user->dateLastSeen(time);
    $user->checkAndupdate(@args);
    $user->isView(1);
    return 0;
}

##@method void removeUser($userWanted)
#@brief Removes a user from the list, based on its nickname ID
#@param object A 'Cocoweb::user' from the user to delete
sub removeUser {
    my ( $self, $userWanted ) = @_;
    my $id                 = $userWanted->mynickID();
    my $user_ref           = $self->all();
    my $DBUsersOffline_ref = $self->DBUsersOffline();
    if ( exists $user_ref->{$id} ) {
        my $user = $user_ref->{$id};

        #info(   'The user "'
        #      . $user->mynickname()
        #      . '" was disconnected after being seen not in the list '
        #      . $user->notViewCount()
        #      . ' times. Table `users` ID:'
        #      . $user->DBUserId() );
        delete $user_ref->{$id};
        push @$DBUsersOffline_ref, $user->DBUserId()
            if $self->logUsersListInDB();
    }
    else {
        warning(  'The user "'
                . $userWanted->mynickname()
                . '" could not be removed from the list' );
    }
}

##@method void setUsersOfflineInDB()
sub setUsersOfflineInDB {
    my ($self) = @_;
    if ( !$self->logUsersListInDB() ) {
        warning('The record in the database is not enabled');
        return;
    }
    my $DBUsersOffline_ref = $self->DBUsersOffline();
    $self->DB()->setUsersOffline($DBUsersOffline_ref);
    $self->DBUsersOffline( [] );
}

## @method public addOrUpdateInDB(updateDates)
# @brief
# @param updateDates - required, boolean if true update 
sub addOrUpdateInDB {
    my ( $self, $updateDates ) = @_;
    if ( !$self->logUsersListInDB() ) {
        warning('The record in the database is not enabled');
        return;
    }
    $updateDates = 1 if !defined $updateDates;
    my $user_ref           = $self->all();
    my @codesToUpdate      = ();
    my @usersToUpdate      = ();
    my @users              = ();
    my $DBUsersOffline_ref = $self->DBUsersOffline();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};

        #debug(  '['
        #      . $user->mynickname()
        #      . '] isNew: '
        #      . $user->isNew()
        #      . '; hasChange: '
        #      . $user->hasChange()
        #      . '; DBUserId:'
        #      . $user->DBUserId()
        #      . '; DBCodeId: '
        #      . $user->DBCodeId() );
        next if !$user->isView();
        if (   $user->isNew()
            or $user->hasChange()
            or $user->DBUserId() == 0
            or $user->DBCodeId() == 0 )
        {
            push @$DBUsersOffline_ref, $user->DBUserId()
                if $self->logUsersListInDB()
                and $user->hasChange();
            $self->DB()->addNewUser($user);
            $user->isNew(0);
            $user->hasChange(0);
            $user->updateDbRecord(0);
        }
        elsif ( $user->updateDbRecord() ) {
            $self->DB()->updateUser($user);
            $user->updateDbRecord(0);
        }
        else {
            if ($updateDates) {
                push @codesToUpdate, $user->DBCodeId();
                push @usersToUpdate, $user->DBUserId();
            }
        }
    }
    if ($updateDates) {
        $self->DB()->updateCodesDate( \@codesToUpdate );
        $self->DB()->updateUsersDate( \@usersToUpdate );
    }
}

##@method arrayref getUsersNotViewed()
#@brief Returns list of users that have not been seen in the
#       users list returned by the last query.
sub getUsersNotViewed {
    my ($self)     = @_;
    my $user_ref   = $self->all();
    my @users      = ();
    my $usersCount = 0;
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        if ( !$user->isView() ) {
            $usersCount++;
            $user->incNotViewCount();

            #info(   'The user "'
            #      . $user->mynickname()
            #      . '" has not been seen in the list. Counter: '
            #      . $user->notViewCount() );
            my $notViewCount = $user->incNotViewCount();
            if ( $notViewCount > 100 ) {
                next if $notViewCount % 20 == 0;
            }
            elsif ( $notViewCount > 80 ) {
                next if $notViewCount % 10 == 0;
            }
            elsif ( $notViewCount > 60 ) {
                next if $notViewCount % 8 == 0;
            }
            elsif ( $notViewCount > 40 ) {
                next if $notViewCount % 4 == 0;
            }
            elsif ( $notViewCount > 20 ) {
                next if $notViewCount % 2 == 0;
            }
            push @users, $user if !$user->isView();
        }
    }
    my $usersStr = '';
    foreach my $user (@users) {
        $usersStr
            .= '['
            . $user->mynickname() . ': '
            . $user->notViewCount() . '] ';
    }

    info(
              scalar(@users)
            . ' user(s) were not found in the list: '
            . $usersStr );
    info(     'Total size of the local list: '
            . scalar( keys %$user_ref )
            . '. Number of users not viewed in the remote list: '
            . $usersCount );
    return \@users;
}

##@method object checkIfNicknameExists($nickname)
#@brief Check if a nickname already exists in the list
#@param string The nickname wanted
#@return object The 'Cocoweb::User' object if the nickname wanted
sub checkIfNicknameExists {
    my ( $self, $nickname ) = @_;
    return if !defined $nickname or length($nickname) == 0;
    my $user_ref = $self->all();
    foreach my $id ( keys %$user_ref ) {
        my $name = $user_ref->{$id}->{'mynickname'};
        if ( lc($name) eq lc($nickname) ) {
            debug("The nickname '$nickname' was found");
            return $user_ref->{$id};
        }
    }
    debug("The nickname '$nickname' was not found");
    return;
}

sub getRandomUser {
    my ($self) = @_;
    my $user_ref = $self->all();
    return $user_ref->{ ( keys %$user_ref )[ rand keys %$user_ref ] };
}

##@method string nickIdToNickname($nickid)
#@brief Returns a nickanme from a nickname id
#@param integer $nickid A nickname ID (i.e. 314857)
#@return string A nickname or returns the nickname if it has not found
sub nickIdToNickname {
    my ( $self, $nickid ) = @_;
    my $user_ref = $self->all();
    if ( exists $user_ref->{$nickid} ) {
        return $user_ref->{$nickid}->{'mynickname'} . ' (' . $nickid . ')';
    }
    else {
        warning(
            'The nickmane id ' . $nickid . ' was not found in the list' );
        return $nickid;
    }
}

##@method string getSerializedFilename()
#@brief Returns the name of the serialized file
#@return string Fullpathname of the serialized file
sub getSerializedFilename {
    my $self     = shift;
    my $filename = lc( ref($self) );
    $filename =~ s{[^a-z0-9]+}{-}g;
    $filename = getVarDir() . '/' . $filename . '.data';
    return $filename;
}

##@method void serialize()
#@brief Serialize the list of users in a file
sub serialize {
    my $self     = shift;
    my $user_ref = $self->all();
    my $filename = $self->getSerializedFilename();
    serializeData( $user_ref, $filename );
}

##@method deserialize()
#@brief Deserializes the list of users from a file
sub deserialize {
    my $self     = shift;
    my $filename = $self->getSerializedFilename();
    if ( !-f $filename ) {
        warning("$filename file was not found");
        return;
    }
    my $user_ref;
    eval { $user_ref = deserializeHash($filename); };
    if ($@) {
        error($@);
    }
    else {
        $self->all($user_ref);
    }
}

1
