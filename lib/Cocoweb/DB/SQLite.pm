# @brief
# @created 2012-03-30
# @date 2012-05-17
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
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
package Cocoweb::DB::SQLite;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use POSIX;
use Cocoweb;
use Cocoweb::File;
use Cocoweb::Config;
use base 'Cocoweb::DB::Base';

__PACKAGE__->attributes('filename');

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->initializesMemberVars();
    $instance->attributes_defaults( 'filename' => '', );
    return $instance;
}

##@method readConfiguration($config)
#@brief Initializes some variables from the configuration file.
#@param $config A 'Cocoweb::Config::File' object
sub setConfig {
    my ( $self, $config ) = @_;
    my $filename = $config->getString('sqlite-filename');
    $filename = getVarDir() . '/' . $filename
      if substr( $filename, 1 ) ne '/';
    $self->filename($filename);
    $self->SUPER::setConfig($config);
}

##@method void connect()
#@brief Establishes a database connection
sub connect {
    my ($self) = @_;
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $self->filename(),
        '', '', { 'PrintError' => 0, 'RaiseError' => 0, 'AutoCommit' => 1 } );
    if ( !defined($dbh) ) {
        my $errorMsg = $DBI::errstr;
        $errorMsg = 'DBI->connect() was failed' if !defined $errorMsg;
        croak error($errorMsg);
    }
    debug( $self->filename() . 'database connection successful' );
    $self->dbh($dbh);
}

##@method void dropTables()
#@brief Removes all tables
sub dropTables {
    my $self = shift;
    foreach my $table ( 'users', 'codes', 'ISPs', 'towns', 'citydios' ) {
        $self->dbh()->do( 'DROP TABLE `' . $table . '`' );
    }
}

##@method void createTables()
#@brief Creates the tables in the database
sub createTables {
    my ($self) = @_;

    my $query;

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `codes` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `code`          CHAR(3) UNIQUE NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `users` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `id_code`       INTEGER NOT NULL,
    `id_ISP`        INTEGER NOT NULL,
    `id_town`       INTEGER NOT NULL,
    `mynickname`    VARCHAR(16) NOT NULL,
    `mynickID`      INTEGER NOT NULL,
    `mysex`         INTEGER NOT NULL,
    `myage`         INTEGER NOT NULL,
    `citydio`       INTEGER NOT NULL,
    `myXP`          INTEGER NOT NULL,
    `myver`         INTEGER NOT NULL,
    `myStat`        INTEGER NOT NULL,
    `status`        INTEGER NOT NULL,
    `level`         INTEGER NOT NULL,
    `since`         INTEGER NOT NULL,
    `premium`       INTEGER NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL,
    `logout_date`   DATETIME DEFAULT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `name`          VARCHAR(255) UNIQUE NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `name`          VARCHAR(255) UNIQUE NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `citydios` (
    `id`            INTEGER PRIMARY KEY,
    `townzz`        VARCHAR(36) UNIQUE NOT NULL)
ENDTXT
    $self->dbh()->do($query);

}

##@method integer _insertCode($code)
#@brief Insert or update a code in the code tables
#@param string A three character code
sub _insertCode {
    my ( $self, $code ) = @_;
    my $query = q/
        INSERT INTO `codes`
        (`code`, `creation_date`, `update_date`) 
        VALUES
        (?, ?, ?);
    /;
    if ( $self->dbh()->do( $query, undef, $code, time, time ) ) {
        return $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
    }
    elsif ( $self->dbh()->err() != 19 ) {
        confess error( $self->dbh()->errstr() );
    }
    warning( $self->dbh()->errstr() );
    my $sth =
      $self->execute( 'SELECT `id` FROM `codes` WHERE `code` = ?  ', $code );
    my $result = $sth->fetchrow_hashref();
    my $idCode = $result->{'id'};
    $self->_updateCode($idCode);
    return $idCode;
}

##@method void _updateCode($idCode)
#@brief Updates the date of a record in the table `codes`
#@input integer $idCode The Id of the record
sub _updateCode {
    my ( $self, $idCode ) = @_;
    my $query = q/
      UPDATE `codes` SET `update_date` = ? 
      WHERE id = ?
   /;
    $self->do( $query, time, $idCode );
}

##@method integer insertUser($user, $idCode, $idISP, $idTown)
#@brief Inserts a new user in the "users" table
sub _insertUser {
    my ( $self, $user, $idCode, $idISP, $idTown ) = @_;
    my $query = q/
      INSERT INTO `users`
        (`id_code`, `id_ISP`, `id_town`, `mynickname`, `mynickID`, `mysex`,
          `myage`, `citydio`, `myXP`, `myver`, `myStat`, `status`, `level`, `since`,
          `premium`, `creation_date`, `update_date`) 
        VALUES
        (?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, ?, ?)
        /;

    $self->do(
        $query,              $idCode,
        $idISP,              $idTown,
        $user->mynickname(), $user->mynickID(),
        $user->mysex(),      $user->myage(),
        $user->citydio(),    $user->myXP(),
        $user->myver(),      $user->mystat(),
        $user->status(),     $user->level(),
        $user->since(),      $user->premium(),
        time,                time
    );
    return $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
}

##@method void updateCodesDate($idCodes_ref)
#@brief Initializes the date of updating of a code list
#@param arrayref $idUsers_ref The list of IDs that need to be updated 
sub updateCodesDate {
    my ( $self, $idCodes_ref ) = @_;
    return if scalar(@$idCodes_ref) == 0;
    my $query = q/
      UPDATE `codes` SET `update_date` = ? 
      WHERE `id` IN ( 
   /;
    foreach my $code (@$idCodes_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
    unshift @$idCodes_ref, time;
    $self->do( $query, @$idCodes_ref );
}

##@method void updateUsersDate($idUsers_ref)
#@brief Initializes the date of updating of a user list
#@param arrayref $idUsers_ref The list of IDs that need to be updated 
sub updateUsersDate {
    my ( $self, $idUsers_ref ) = @_;
    return if scalar(@$idUsers_ref) == 0;
    my $query = q/
      UPDATE `users` SET `update_date` = ? 
      WHERE `id` IN ( 
   /;
    foreach my $idUser (@$idUsers_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
    unshift @$idUsers_ref, time;
    $self->do( $query, @$idUsers_ref );
}

##@method void setUsersOffline($idUsers_ref)
#@brief Initializes the date of disconnection of a user list
#@param arrayref $idUsers_ref The list of IDs to be disconnected
sub setUsersOffline {
    my ( $self, $idUsers_ref ) = @_;
    return if scalar(@$idUsers_ref) == 0;
    debug(  'Set '
          . scalar(@$idUsers_ref)
          . ' user(s) offline into `users` table' );
    my $query = q/
      UPDATE `users` SET `logout_date` = ? 
      WHERE `id` IN ( 
   /;
    foreach my $idUser (@$idUsers_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
    unshift @$idUsers_ref, time;
    $self->do( $query, @$idUsers_ref );
}



1;

