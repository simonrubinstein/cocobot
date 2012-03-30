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
package Cocoweb::DB::Base;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use DBI;
use POSIX;

use Cocoweb;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes( 'dbh', 'ISO3166Regex', 'town2id' );

##@method object getInstance()
#@brief Returns an instance of an database object
#@return object An 'Cocoweb::DB::SQLite' or 'Cocoweb::DB::MySQL' object
sub getInstance {
    my $config = Cocoweb::Config->instance()->getConfigFile('database.conf');
    my $databaseClass = $config->getString('database-class');
    require 'Cocoweb/DB/' . $databaseClass . '.pm';
    my $class = 'Cocoweb::DB::' . $databaseClass;
    my $DB = $class->instance('config' => $config);
    $DB->setConfig($config);
    return $DB;
}

##@method object init($class, $instance)
sub init {
    die error("This class can not be instantiated");
}

##@method void initializesMemberVars()
##@method Initializes member variables.
sub initializesMemberVars {
    my ($self) = @_;
    $self->dbh(undef);
    $self->town2id([]);
    $self->ISO3166Regex('');
}

##@method readConfiguration($config)
#@brief Initializes some variables from the configuration file.
#@param $config A 'Cocoweb::Config::File' object
sub setConfig {
    my ( $self, $config) = @_;
    $self->ISO3166Regex($config->getString('ISO-3166-1-alpha-2'));
}

##@method void connect()
#@brief Establishes a database connection
sub connect {
    croak  error('The connect() method must be overridden!');
}

##@method void createTables()
#@brief Creates the tables in the database
sub createTables {
    croak  error('The createTables() method must be overridden!');
}
 
##@method void debug($query, $bindValues_ref)
##@brief Log a SQL query
##@input string $query SQL Query
##@input arrayref $values_ref Array ref of values
sub debugQuery {
    my $self = shift;
    return if !$Cocoweb::isDebug;
    my $query          = shift;
    my $bindValues_ref = shift;
    $query =~ s{\s{2,}}{ }g;
    $query .= ' [';
    foreach my $val (@$bindValues_ref) {
        if ( !defined $val ) {
            $query .= 'NULL, ';
        }
        else {
            $query .= $val . ', ';
        }
    }
    chop($query);
    $query .= ']';
    debug($query);
}

##@method object select ($query, $values_ref)
##Select raws from table(s)
##@input string $query SQL Query
##@input arrayref $values_ref Array ref of values
##@return DBI::sth object
sub execute {
    my ( $self, $query, $values_ref ) = @_; 
    $values_ref = [] if !defined $values_ref;
    my $sth = $self->dbh()->prepare($query)
        or croak 
        error( "prepare($query) fail: " . $self->dbh()->errstr() );
    $self->debugQuery( $query, \@$values_ref );
    my $res = $sth->execute(@$values_ref);
    croak error( "$query failed!" . " errstr: " . $self->dbh()->errstr() )
        if !$res;
    return $sth;
}

##@method array getInitTowns()
#@brief Returns a list of town codes from the configuration file
#@return array A list of two elements:
#              - a hash table containing town codes
#              - an Cocoweb::Config::Plaintext object
sub getInitTowns {
    my ($self) = @_;
    my $towns = Cocoweb::Config->instance()->getConfigFile( 'towns.txt', 1 );
    my $ISO3166Regex = $self->ISO3166Regex();
    $ISO3166Regex = qr/^$ISO3166Regex.*/;
    my $towns_ref = $towns->getAsHash();
    foreach my $town ( keys %$towns_ref ) {
        die error("The string $town is not valid") if $town !~ $ISO3166Regex;
    }
    info( 'number of town codes: ' . scalar( keys %$towns_ref ) );
    return ( $towns_ref, $towns );
}

##@method array getInitISPs()
#@brief Returns a list of ISP codes from the configuration file
#@return array A list of two elements:
#              - a hash table containing ISP codes
#              - an Cocoweb::Config::Plaintext object
sub getInitISPs() {
    my ($self) = @_;
    my $ISPs = Cocoweb::Config->instance()->getConfigFile( 'ISPs.txt', 1 );
    my $ISPs_ref = $ISPs->getAsHash();
    info( 'number of ISP codes: ' . scalar( keys %$ISPs_ref ) );
    return ( $ISPs_ref, $ISPs );
}

##@method void insertTown($name)
#@brief Inserts a new town code in the table "towns"
#@param string An town code, i.e. "FR- Sevran"
sub insertTown {
    my ( $self, $name ) = @_;
    my $query = q/
      INSERT INTO `towns`
        (`name`) 
        VALUES
        (?);
      /;
    $self->dbh()->do( $query, undef, $name );
}

##@method void insertISP($name)
#@brief Inserts a new ISP code in the table "towns"
#@param string An ISP code, i.e. "Free SAS"
sub insertISP {
    my ( $self, $name ) = @_;
    my $query = q/
      INSERT INTO `ISPs`
        (`name`) 
        VALUES
        (?);
      /;
    $self->dbh()->do( $query, undef, $name );
}

sub insertCode {
    my ( $self, $code ) = @_;
    my $query = q/
      INSERT INTO `codes`
        (`code`, `creation_date`, `update_date`) 
        VALUES
        (?);
      /;
    $self->dbh()->do( $query, undef, $code, time, time );
}

sub initialize {
    my ($self) = @_;
    $self->connect();
    $self->getAllTowns();
}

sub getAllTowns {
    my ($self) = @_;
    my $sth = $self->execute('SELECT `id`, `name` FROM `towns`');
    my ($id, $town);
    my $town2id_ref = $self->town2id();
    while ( ($id, $town) = $sth->fetchrow_array ()) {
        $town2id_ref->{$town} = $id;
    }
}



1;



