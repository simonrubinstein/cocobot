# @brief Handle SQLite database
# @created 2012-03-11
# @date 2012-03-11
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2012
# Id: $Id$
# Revision$
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
package Cocoweb::DB;
use Cocoweb;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use DBI;
use Data::Dumper;
use Term::ANSIColor;
use strict;
use warnings;

__PACKAGE__->attributes( 'dbh', 'filename', 'ISO3166Regex' );

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    my $config = Cocoweb::Config->instance()->getConfigFile('database.conf');
    $instance->attributes_defaults(
        'dbh'          => undef,
        'filename'     => $config->getString('filename'),
        'ISO3166Regex' => $config->getString('ISO-3166-1-alpha-2')
    );
    return $instance;
}

##@method hashref getInitTowns()
sub getInitTowns {
    my ($self) = @_;
    my $towns = Cocoweb::Config->instance()->getConfigFile( 'towns.txt', 1 );

    my $ISO3166Regex = $self->ISO3166Regex();
    $ISO3166Regex = qr/^$ISO3166Regex.*/;
    my $towns_ref = $towns->getAsHash();
    foreach my $town ( keys %$towns_ref ) {
        die error("The string $town is not valid") if $town !~ $ISO3166Regex;
    }
    info( 'number of towns: ' . scalar( keys %$towns_ref ) );
    #print Dumper $towns->all();
    return ($towns_ref, $towns);
}

##@method void connect()
sub connect {
    my ($self) = @_;
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $self->filename(),
        '', '', { 'PrintError' => 0, 'RaiseError' => 1, 'AutoCommit' => 1 } );
    if ( !defined($dbh) ) {
        my $errorMsg = $DBI::errstr;
        $errorMsg = 'DBI->connect() was failed' if !defined $errorMsg;
        croak error($errorMsg);
    }
    debug( $self->filename() . 'database connection successful' );
    $self->dbh($dbh);
}

sub createTables {
    my ($self) = @_;

    my $query;

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `codes` (
    `id`            INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    `code`          CHAR(3) UNIQUE NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `nicknames` (
    `id`            INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    `login`         VARCHAR(16) NOT NULL,
    `sex`           INTEGER NOT NULL,
    `old`           INTEGER NOT NULL,
    `city`          INTEGER NOT NULL,
    `nickid`        INTEGER NOT NULL,
    `niv`           INTEGER NOT NULL,
    `ok`            INTEGER NOT NULL,
    `stat`          INTEGER NOT NULL,
    `code`          INTEGER NOT NULL,
    `ISP`           INTEGER NOT NULL,
    `status`        INTEGER NOT NULL,
    `level`         INTEGER NOT NULL,
    `since`         INTEGER NOT NULL,
    `town`          INTEGER NOT NULL,
    `creation_date` DATETIME NOT NULL,
    `update_date`   DATETIME NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    `name`          VARCHAR(255) UNIQUE NOT NULL)
ENDTXT
    $self->dbh()->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            INTEGER UNSIGNED NOT NULL PRIMARY KEY,
    `name`          VARCHAR(255) UNIQUE NOT NULL)
ENDTXT
    $self->dbh()->do($query);

}

sub insertTown {
    my ( $self, $name ) = @_;

}

1;

