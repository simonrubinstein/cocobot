# @brief
# @created 2012-03-30
# @date 2016-07-02
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
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
use Cocoweb::Config;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes( 'dbh', 'ISO3166Regex', 'town2id', 'ISP2id',
    'isDebug' );

##@method object getInstance()
#@brief Returns an instance of an database object
#@return object An 'Cocoweb::DB::SQLite' or 'Cocoweb::DB::MySQL' object
sub getInstance {
    my $config = Cocoweb::Config->instance()
        ->getConfigFile( 'database.conf', 'File' );
    my $databaseClass = $config->getString('database-class');
    require 'Cocoweb/DB/' . $databaseClass . '.pm';
    my $class = 'Cocoweb::DB::' . $databaseClass;
    my $DB = $class->instance( 'config' => $config );
    $DB->setConfig($config);
    return $DB;
}

##@method object init($class, $instance)
sub init {
    confess error("This class can not be instantiated");
}

##@method void initializesMemberVars()
##@method Initializes member variables.
sub initializesMemberVars {
    my ($self) = @_;
    $self->dbh(undef);
    $self->town2id( {} );
    $self->ISP2id(  {} );
    $self->ISO3166Regex('');
}

##@method readConfiguration($config)
#@brief Initializes some variables from the configuration file.
#@param $config A 'Cocoweb::Config::File' object
sub setConfig {
    my ( $self, $config ) = @_;
    $self->ISO3166Regex( $config->getString('ISO-3166-1-alpha-2') );
    $self->isDebug( $config->getBool('isDebug') );
}

##@method void connect()
#@brief Establishes a database connection
sub connect {
    croak error('The connect() method must be overridden!');
}

##@method void createTables()
#@brief Creates the tables in the database
sub createTables {
    croak error('The createTables() method must be overridden!');
}

##@method void dropTables()
#@brief Removes all tables
sub dropTables {
    croak error('The dropTables() method must be overridden!');
}

##@method void debug($query, $bindValues_ref)
##@brief Log a SQL query
##@input string $query SQL Query
##@input arrayref $values_ref Array ref of values
sub debugQuery {
    my $self = shift;
    return if !$Cocoweb::isDebug;
    my $query = shift;
    $query =~ s{\n}{}g;
    my $bindValues_ref = shift;
    $query =~ s{\s{2,}}{ }g;
    $query .= ' [';
    if ( scalar(@$bindValues_ref) > 0 ) {

        foreach my $val (@$bindValues_ref) {
            if ( !defined $val ) {
                $query .= 'NULL, ';
            }
            else {
                $query .= $val . ', ';
            }
        }
        $query = substr( $query, 0, -2 );
    }
    $query .= ']';
    debug($query);
}

##@method object select ($query, $values_ref)
#@brief Select raws from table(s)
#@input string $query SQL Query
#@input array $values_ref Array of values
#@return DBI::sth object
sub execute {
    my $self  = shift;
    my $query = shift;
    my $sth   = $self->dbh()->prepare($query)
        or croak error( "prepare($query) fail: " . $self->dbh()->errstr() );
    $self->debugQuery( $query, \@_ ) if $self->isDebug();
    my $res = $sth->execute(@_);
    croak error( "$query failed!" . " errstr: " . $self->dbh()->errstr() )
        if !$res;
    return $sth;
}

##@method void do($query)
#@input string $query SQL Query
#@input array $values_ref Array of values
sub do {
    my $self  = shift;
    my $query = shift;
    $self->debugQuery( $query, \@_ ) if $self->isDebug();
    $self->dbh()->do( $query, undef, @_ )
        or croak error(
        $self->dbh()->errstr() . '; error code: ' . $self->dbh()->err() );
}

##@method array getInitTowns()
#@brief Returns a list of town codes from the configuration file
#@return array A list of two elements:
#              - a hash table containing town codes
#              - an Cocoweb::Config::Plaintext object
sub getInitTowns {
    my ($self) = @_;
    my $towns = Cocoweb::Config->instance()
        ->getConfigFile( 'towns.txt', 'Plaintext' );
    my $ISO3166Regex = $self->ISO3166Regex();
    $ISO3166Regex = qr/^$ISO3166Regex.*/;
    my $towns_ref = $towns->getAsHash();
    foreach my $town ( keys %$towns_ref ) {
        confess error("The string $town is not valid")
            if $town !~ $ISO3166Regex;
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
    my $ISPs = Cocoweb::Config->instance()
        ->getConfigFile( 'ISPs.txt', 'Plaintext' );
    my $ISPs_ref = $ISPs->getAsHash();
    info( 'number of ISP codes: ' . scalar( keys %$ISPs_ref ) );
    return ( $ISPs_ref, $ISPs );
}

##@method void insertTown($name)
#@brief Inserts a new town code in the table "towns"
#@param string $name An town code, i.e. "FR- Sevran"
sub insertTown {
    my ( $self, $name ) = @_;
    my $query = q/
      INSERT INTO `towns`
        (`name`) 
        VALUES
        (?);
      /;
    $self->do( $query, $name );
    return $self->dbh()->last_insert_id( undef, undef, 'towns', undef );
}

##@method void insertISP($name)
#@brief Inserts a new ISP code in the table "towns"
#@param string $name An ISP code, i.e. "Free SAS"
sub insertISP {
    my ( $self, $name ) = @_;
    my $query = q/
      INSERT INTO `ISPs`
        (`name`) 
        VALUES
        (?);
      /;
    $self->do( $query, $name );
    return $self->dbh()->last_insert_id( undef, undef, 'ISPs', undef );
}

##@method void insertCitydio ($id, $townzz)
#@brief Inserts a new citydio and townzz code in the table "citydios"
#@param int $id
#@param string $townzz
sub insertCitydio {
    my ( $self, $id, $townzz ) = @_;
    my $query = q/
      INSERT INTO `citydios`
        (`id`, `townzz`) 
        VALUES
        (?, ?);
      /;
    $self->do( $query, $id, $townzz );
}

##@method void insertCode($code)
#@brief Insert or update a code in the code tables
#@param string A three character code
sub insertCode {
    my ( $self, $code ) = @_;
    croak error('The dropTables() method must be overridden!');
}

##@method void initialize()
sub initialize {
    my ($self) = @_;
    $self->connect();
    $self->getAllTowns();
    $self->getAllIPSs();
}

##@method integer getTown($town)
sub getTown {
    my ( $self, $town ) = @_;
    my $town2id_ref = $self->town2id();
    return $town2id_ref->{$town} if exists $town2id_ref->{$town};
    my $id = $self->insertTown($town);
    $town2id_ref->{$town} = $id;
    return $id;
}

##@method integer getISP($ISP)
sub getISP {
    my ( $self, $ISP ) = @_;
    my $ISP2id_ref = $self->ISP2id();
    return $ISP2id_ref->{$ISP} if exists $ISP2id_ref->{$ISP};
    my $id = $self->insertISP($ISP);
    $ISP2id_ref->{$ISP} = $id;
    return $id;
}

##@method void getAllTowns()
sub getAllTowns {
    my ($self) = @_;
    my $sth = $self->execute('SELECT `id`, `name` FROM `towns`');
    my ( $id, $town );
    my $town2id_ref = $self->town2id();
    while ( ( $id, $town ) = $sth->fetchrow_array() ) {
        $town2id_ref->{$town} = $id;
    }
}

##@method void getAllISPs()
sub getAllIPSs {
    my ($self) = @_;
    my $sth = $self->execute('SELECT `id`, `name` FROM `ISPs`');
    my ( $id, $ISP );
    my $ISP2id_ref = $self->ISP2id();
    while ( ( $id, $ISP ) = $sth->fetchrow_array() ) {
        $ISP2id_ref->{$ISP} = $id;
    }
}

##@method void addNewUser($user)
#@brief Adds a new row in the 'users' table
#@param $user A 'Cocoweb::User' object
sub addNewUser {
    my ( $self, $user ) = @_;
    my $idTown     = $self->getTown( $user->town() );
    my $idISP      = $self->getISP( $user->ISP() );
    my $idCode     = $self->_insertCode2( $user->code() );
    my $idNickname = $self->_insertNickname( $user->mynickname() );
    debug(    'mynickname: '
            . $user->mynickname()
            . "; idTown: $idTown; idISP: $idISP; idCode: $idCode" );
    $user->DBCodeId($idCode);

    my $idUser
        = $self->_insertUser( $user, $idCode, $idISP, $idTown, $idNickname );
    $user->DBUserId($idUser);
    debug("idUser: $idUser");
}

##@method void updateCode($user)
#@brief Updates the date of a record in the table `codes`
#@param $user A 'Cocoweb::User' object
sub updateCode {
    my ( $self, $user ) = @_;
    debug( $user->mynickname() );
    my $code = $user->code();
    confess error("No Id of table `codes` were found (code: $code)")
        if $user->DBCodeId() == 0;
    $self->_updateCode( $user->DBCodeId() );
    return $user->DBCodeId();
}

##@method void updateUser($user)
#@brief Updates the date of a record in the table `users`
#@param $user A 'Cocoweb::User' object
sub updateUser {
    my ( $self, $user ) = @_;
    debug( $user->mynickname() );
    confess error("No Id of table `users` were found")
        if $user->DBUserId() == 0;
    my $idCode     = $self->updateCode($user);
    my $idNickname = $self->_insertNickname( $user->mynickname() );
    my $idTown     = $self->getTown( $user->town() );
    my $idISP      = $self->getISP( $user->ISP() );
    $self->_updateUser( $user, $idCode, $idISP, $idTown, $idNickname );
}

##@method void setUserOffline($user)
sub setUserOffline {
    my ( $self, $user ) = @_;
    if ( $user->DBUserId() == 0 ) {
        print Dumper $user;
        confess error( "No Id of table `users` were found. Nickname: "
                . $user->mynickname() );
    }
    $self->_setUserLogoutDate( $user->DBUserId() );
    $user->DBUserId(0);
}

##@method void updateUserDate($user)
#@brief Updates all field records in the table `users`
#@param $user A 'Cocoweb::User' object
sub updateUserDate {
    my ( $self, $user ) = @_;
    confess error("No Id of table `users` were found")
        if $user->DBUserId() == 0;
    $self->updateCode($user);
    $self->_updateUserDate( $user->DBUserId() );
}

1;

