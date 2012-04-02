# @brief
# @created 2012-03-30
# @date 2012-04-01
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
package Cocoweb::DB::SQLite;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use POSIX;
use Cocoweb;
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
    $filename = Cocoweb::Config->instance()->getVarDir() . '/' . $filename
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
    foreach my $table ( 'nicknames', 'codes', 'ISPs', 'towns' ) {
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
    CREATE TABLE IF NOT EXISTS `nicknames` (
    `id`            INTEGER PRIMARY KEY AUTOINCREMENT,
    `id_codes`      INTEGER NOT NULL,
    `id_town`       INTEGER NOT NULL,
    `id_ISP`        INTEGER NOT NULL,
    `nickname`      VARCHAR(16) NOT NULL,
    `sex`           INTEGER NOT NULL,
    `old`           INTEGER NOT NULL,
    `city`          INTEGER NOT NULL,
    `nickid`        INTEGER NOT NULL,
    `niv`           INTEGER NOT NULL,
    `ok`            INTEGER NOT NULL,
    `stat`          INTEGER NOT NULL,
    `status`        INTEGER NOT NULL,
    `level`         INTEGER NOT NULL,
    `since`         INTEGER NOT NULL,
    `premimum`      INTEGER NOT NULL,
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
}

##@method void insertCode($code)
#@brief Insert or update a code in the code tables
#@param string A three character code
sub insertCode {
    my ( $self, $code ) = @_;
    my $query;
    my $codesCache_ref = $self->codesCache();
    my $id;
    if ( !exists $codesCache_ref->{$code} ) {
        $query = q/
        INSERT INTO `codes`
          (`code`, `creation_date`, `update_date`) 
          VALUES
          (?, ?, ?);
        /;
        if ( $self->dbh()->do( $query, undef, $code, time, time ) ) {
            $id = $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
            $codesCache_ref->{$code} = $id;
            return $id;
        }
        elsif ( $self->dbh()->err() != 19 ) {
            confess error( $self->dbh()->errstr() );
        }
        warning( $self->dbh()->errstr() );
        $id = 0;
        my $sth = $self->execute('SELECT `id` FROM `codes` WHERE `code` = ?  ', $code);
        my $result = $sth->fetchrow_hashref();
        $id = $result->{'id'};
        $codesCache_ref->{$code} = $id;
    }
    else {
        $id = $codesCache_ref->{$code};
    }
    $query = 'UPDATE `codes` SET `update_date` = ? WHERE `id` = ?';
    $self->do( $query, time, $id );
    return $id; 
}

sub offlineNickname {
    my ( $self, $user ) = @_;
}

1;
