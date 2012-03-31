# @created 2012-03-19
# @date 2012-03-31
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
package Cocoweb::User::List;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use Cocoweb::User;
use Cocoweb::User::BaseList;
use base 'Cocoweb::User::BaseList';
__PACKAGE__->attributes( 'logUsersListInDB', 'DB' );

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    my $logUsersListInDB =
      ( exists $args{'logUsersListInDB'} and $args{'logUsersListInDB'} )
      ? 1
      : 0;
    my $DB;
    $DB = Cocoweb::DB::Base->getInstance() if $logUsersListInDB;
    $self->attributes_defaults(
        'all'              => {},
        'logUsersListInDB' => $logUsersListInDB,
        'DB'               => $DB
    );
}

##@method void populate($myage, $mysex, $citydio, $mynickID,
#                       $mynickname, $myXP, $mystat, $myver)
#@brief Adds or updates a user from the list
sub populate {
    my (
        $self,       $myage, $mysex,  $citydio, $mynickID,
        $mynickname, $myXP,  $mystat, $myver
    ) = @_;
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
        $user->update(@args);
        $user->isNew(0);
        $user->isView(1);
    }
    else {
        $users_ref->{$mynickID} = Cocoweb::User->new(@args);
    }
}

##@method void removeUser($userWanted)
sub removeUser {
    my ( $self, $userWanted ) = @_;
    my $id       = $userWanted->mynickID();
    my $user_ref = $self->all();
    if ( exists $user_ref->{$id} ) {
        my $user = $user_ref->{$id};
        info(   'The user "'
              . $user->mynickname()
              . '" was disconnected after being seen not in the list '
              . $user->notViewCount()
              . ' times' );

        delete $user_ref->{$id};
        $self->DB()->offlineNickname($user) if $self->logUsersListInDB();

    }
    else {
        warning('The user "'
              . $userWanted->mynickname()
              . '" could not be removed from the list' );
    }

}

sub addOrUpdateInDB {
    my ($self) = @_;
    if ( !$self->logUsersListInDB() ) {
        warning('The record in the database is not enabled');
        return;
    }
    my $user_ref = $self->all();
    my @users    = ();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        next !$user->isView();
        if ( $user->isNew() or $user->hasChange() ) {
            $self->DB()->addNewNickname($user);
        }
        elsif ( $user->updateDbRecord() ) {
            $self->DB()->updateNickname($user);
        }
        else {
            $self->DB()->updateNicknameDate($user);
        }

    }
}

##@method arrayref getUsersNotViewed()
sub getUsersNotViewed {
    my ($self)   = @_;
    my $user_ref = $self->all();
    my @users    = ();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        if ( !$user->isView() ) {
            $user->incNotViewCount();
            info(   'The user "'
                  . $user->mynickname()
                  . '" has not been seen in the list. Counter: '
                  . $user->notViewCount() );
            push @users, $user if !$user->isView();
        }
    }
    info( scalar(@users) . ' user(s) were not found in the list' );
    return \@users;
}

##@method hashref checkIfNicknameExists($pseudonym)
#@brief Check if a pseudonym already exists in the list
#       of pseudonym already read.
#@param string The pseudonym wanted
#@return hashref
sub checkIfNicknameExists {
    my ( $self, $pseudonym ) = @_;
    return if !defined $pseudonym or length($pseudonym) == 0;
    my $user_ref = $self->all();
    foreach my $id ( keys %$user_ref ) {
        my $name = $user_ref->{$id}->{'mynickname'};
        if ( lc($name) eq lc($pseudonym) ) {
            debug("The pseudonym '$pseudonym' was found");
            return $user_ref->{$id};
        }
    }
    debug("The pseudonym '$pseudonym' was not found");
    return;
}

1
