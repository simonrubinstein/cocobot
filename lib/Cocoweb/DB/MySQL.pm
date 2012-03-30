# @brief
# @created 2012-03-30
# @date 2012-03-30
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
            die error( 'connection timout after' . ' '
                  . $self->timeout()
                  . "seconds (DSN: $self->datasource())" );
        }
        else {
            die error( 'database connection error'
                  . " (DSN: $self->datasource()): "
                  . $@ );
        }
    }
    else {
        if ( !defined($dbh) ) {
            my $errorStr = $DBI::errstr;
            $errorStr = 'DBconnect() failed! '
              if !defined $errorStr;
            die error($errorStr);
        }
    }
    debug("The connection to the database is successful");
    $self->dbh($dbh);
}

##@method void dropTables()
#@brief Removes all tables
sub dropTables {
    my $self = shift;
    foreach my $table ( 'codes', 'nicknames', 'ISPs', 'towns' ) {
        $self->do( 'DROP TABLE `' . $table . '` IF EXISTS' );
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
    )
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `nicknames` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `login`         VARCHAR(16) NOT NULL,
    `sex`           INTEGER NOT NULL,
    `old`           INTEGER NOT NULL,
    `city`          INTEGER NOT NULL,
    `nickid`        INTEGER NOT NULL,
    `niv`           INTEGER NOT NULL,
    `ok`            INTEGER NOT NULL,
    `stat`          INTEGER NOT NULL,
    `ISP`           INTEGER NOT NULL,
    `status`        INTEGER NOT NULL,
    `level`         INTEGER NOT NULL,
    `since`         INTEGER NOT NULL,
    `town`          INTEGER NOT NULL,
    `premimum`      INTEGER NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL,
    `logout_date`   DATETIME DEFAULT NULL,
     PRIMARY KEY  (`id`)
    )
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          VARCHAR(255) NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    )
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          VARCHAR(255) NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    )
ENDTXT
    $self->do($query);
}

1;
