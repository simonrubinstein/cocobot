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
package Cocoweb::DB::MySQL;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use POSIX;

use Cocoweb;
use base 'Cocoweb::DB::Base';

__PACKAGE__->attributes( 'datasource', 'username', 'password', 'timeout' );

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->initializesMemberVars();
    $instance->attributes_defaults(
        'datasource' => '',
        'username'   => '',
        'password'   => '',
        'timeout'    => 0,
    );
    return $instance;
}

##@method readConfiguration($config)
#@brief Initializes some variables from the configuration file.
#@param $config A 'Cocoweb::Config::File' object
sub setConfig {
    my ( $self, $config ) = @_;
    $self->SUPER::setConfig($config);
    $self->datasource( $config->getString('dbi-datasource') );
    $self->username( $config->getString('dbi-username') );
    $self->password( $config->getString('dbi-password') );
    $self->timeout( $config->getInt('dbi-timeout') );
}

##@method void connect()
#@brief Establishes a database connection
sub connect {
    my ($self) = @_;
    my $dbh;
    eval {
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm $self->timeout();
        $dbh =
          DBI->connect( $self->datasource(), $self->username(),
            $self->password(), { 'PrintError' => 0, 'RaiseError' => 0 } );
        alarm 0;
    };
    if ($@) {
        if ( $@ eq "alarm\n" ) {
            confess error( 'connection timout after' . ' '
                  . $self->timeout()
                  . "seconds (DSN: $self->datasource())" );
        }
        else {
            confess error( 'database connection error'
                  . " (DSN: $self->datasource()): "
                  . $@ );
        }
    }
    else {
        if ( !defined($dbh) ) {
            my $errorStr = $DBI::errstr;
            $errorStr = 'DBconnect() failed! '
              if !defined $errorStr;
            confess error($errorStr);
        }
    }
    debug("The connection to the database is successful");
    $self->dbh($dbh);
}

##@method void dropTables()
#@brief Removes all tables
sub dropTables {
    my $self = shift;
    foreach my $table ( 'nicknames', 'codes', 'ISPs', 'towns' ) {
        $self->do( 'DROP TABLE IF EXISTS `' . $table . '`' );
    }
}

##@method void createTables()
#@brief Creates the tables in the database
sub createTables {
    my ($self) = @_;

    my $query;

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `codes` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `code`          CHAR(3) NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL,
    PRIMARY KEY  (`id`),
    UNIQUE KEY `id` (`id`),
    UNIQUE KEY `code` (`code`)
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          VARCHAR(255) NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          VARCHAR(255) NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `users` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `id_code`       int(10) unsigned NOT NULL,
    `id_ISP`        int(10) unsigned NOT NULL,
    `id_town`       int(10) unsigned NOT NULL,
    `mynickname`    VARCHAR(16) NOT NULL,
    `mynickID`        int(10) unsigned NOT NULL,
    `mysex`           int(10) unsigned NOT NULL,
    `myage`         int(10) unsigned NOT NULL,
    `citydio`       int(10) unsigned NOT NULL,
    `myXP`          int(10) unsigned NOT NULL,
    `myver`         int(10) unsigned NOT NULL,
    `myStat`        int(10) unsigned NOT NULL,
    `status`        int(10) unsigned NOT NULL,
    `level`         int(10) unsigned NOT NULL,
    `since`         int(10) unsigned NOT NULL,
    `premium`       int(10) unsigned NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL,
    `logout_date`   DATETIME DEFAULT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `id` (`id`),
     KEY `nicknames_FKIndex1` (`id_code`),
     CONSTRAINT `nicknames_ibfk_1` FOREIGN KEY (`id_code`)
       REFERENCES `codes` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
     KEY `nicknames_FKIndex2` (`id_ISP`),
     CONSTRAINT `nicknames_ibfk_2` FOREIGN KEY (`id_ISP`)
       REFERENCES `ISPs` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
     KEY `nicknames_FKIndex3` (`id_town`),
     CONSTRAINT `nicknames_ibfk_3` FOREIGN KEY (`id_town`)
       REFERENCES `towns` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

}

##@method void insertCode($code)
#@brief Insert or update a code in the code tables
#@param string A three character code
sub insertCode {
    my ( $self, $code ) = @_;
    my $query = q/
      INSERT INTO `codes`
        (`code`, `creation_date`, `update_date`) 
        VALUES
        (?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
        ON DUPLICATE KEY UPDATE `update_date` = CURRENT_TIMESTAMP()
      /;
    $self->do( $query, $code );
    return $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
}

##@method integer insertUser($user, $idCode, $idISP, $idTown)
#@brief Inserts a new user in the "users" table
sub insertUser {
    my ( $self, $user, $idCode, $idISP, $idTown ) = @_;
    my $query = q/
      INSERT INTO `users`
        (`id_code`, `id_ISP`, `id_town`, `mynickname`, `mynickID`, `mysex`,
          `myage`, `citydio`, `myXP`, `myver`, `myStat`, `status`, `level`, `since`,
          `premium`, `creation_date`, `update_date`) 
        VALUES
        (?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
        /;

    $self->do(
        $query,              $idCode,
        $idISP,              $idTown,
        $user->mynickname(), $user->mynickID(),
        $user->mysex(),      $user->myage(),
        $user->citydio(),    $user->myXP(),
        $user->myver(),      $user->mystat(),
        $user->status(),     $user->level(),
        $user->since(),      $user->premium()
    );

    return $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
}

sub offlineNickname {
    my ( $self, $user ) = @_;
}

1;
