# @brief
# @created 2012-03-30
# @date 2012-05-31
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
    foreach my $table ( 'users', 'codes', 'ISPs', 'towns', 'citydios' ) {
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
    `code`          CHAR(3) BINARY NOT NULL,
    `creation_date` datetime NOT NULL,
    `update_date`   datetime NOT NULL,
    PRIMARY KEY  (`id`),
    UNIQUE KEY `id` (`id`),
    UNIQUE KEY `code` (`code`)
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          varchar(255) NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB
ENDTXT
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          varchar(255) NOT NULL,
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
    `mynickname`    varchar(16) NOT NULL,
    `mynickID`      int(10) unsigned NOT NULL,
    `mysex`         int(10) unsigned NOT NULL,
    `myage`         int(10) unsigned NOT NULL,
    `citydio`       int(10) unsigned NOT NULL,
    `myXP`          int(10) unsigned NOT NULL,
    `myver`         int(10) unsigned NOT NULL,
    `myStat`        int(10) unsigned NOT NULL,
    `status`        int(10) unsigned NOT NULL,
    `level`         int(10) unsigned NOT NULL,
    `since`         int(10) unsigned NOT NULL,
    `premium`       int(10) unsigned NOT NULL,
    `creation_date` datetime NOT NULL,
    `update_date`   datetime NOT NULL,
    `logout_date`   datetime DEFAULT NULL,
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

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `citydios` (
     `id`        int(10) unsigned NOT NULL,
     `townzz`    varchar(36) NOT NULL,
     PRIMARY KEY (`id`),
     UNIQUE KEY `townzz` (`townzz`)
    ) ENGINE=InnoDB
ENDTXT
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
        (?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
        ON DUPLICATE KEY UPDATE `update_date` = CURRENT_TIMESTAMP()
      /;
    $self->do( $query, $code );
    my $id = $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
    return $id;
}

##@method void _updateCode($idCode)
#@brief Updates the date of a record in the table `codes`
#@input integer $idCode The Id of the record
sub _updateCode {
    my ( $self, $idCode ) = @_;
    my $query = q/
      UPDATE `codes` SET `update_date` = CURRENT_TIMESTAMP()
      WHERE id = ?
   /;
    $self->do( $query, $idCode );
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

##@method _updateUser($user, $idCode, $idISP, $idTown)
sub _updateUser {
    my ( $self, $user, $idCode, $idISP, $idTown ) = @_;
    my $query = q/
      UPDATE `users` SET `id_code` = ?, `id_ISP` = ? , `id_town` = ?,
        `mynickname` = ?, `mynickID` = ?, `mysex` = ?, `myage` = ?,
        `citydio` = ?, `myXP` = ?, `myver` = ?, `myStat` = ?, `status` = ?,
        `level` = ?, `since` = ?, `premium` = ?,
        `update_date` = CURRENT_TIMESTAMP()
        WHERE `id` = ?
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
        $user->DBUserId()
    );
}

##@method void _updateUserDate($idUser)
#@brief Updates the date of a record in the table `users`
sub _updateUserDate {
    my ( $self, $idUser ) = @_;
    my $query = q/
      UPDATE `users` SET `update_date` = CURRENT_TIMESTAMP()
      WHERE `id` = ?
   /;
    $self->do( $query, $idUser );
}

##@method void _setUserLogoutDate($idUser)
sub _setUserLogoutDate {
    my ( $self, $idUser ) = @_;
    my $query = q/
      UPDATE `users` SET `logout_date` = CURRENT_TIMESTAMP()
      WHERE `id` = ? AND `logout_date` = NULL
   /;
    $self->do( $query, $idUser );
}

##@method void updateCodesDate($idCodes_ref)
#@brief Initializes the date of updating of a code list
#@param arrayref $idUsers_ref The list of IDs that need to be updated
sub updateCodesDate {
    my ( $self, $idCodes_ref ) = @_;
    return if scalar(@$idCodes_ref) == 0;
    my $query = q/
      UPDATE `codes` SET `update_date` = CURRENT_TIMESTAMP()
      WHERE `id` IN ( 
   /;
    foreach my $code (@$idCodes_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
    $self->do( $query, @$idCodes_ref );
}

##@method void updateUsersDate($idUsers_ref)
#@brief Initializes the date of updating of a user list
#@param arrayref $idUsers_ref The list of IDs that need to be updated
sub updateUsersDate {
    my ( $self, $idUsers_ref ) = @_;
    return if scalar(@$idUsers_ref) == 0;
    my $query = q/
      UPDATE `users` SET `update_date` = CURRENT_TIMESTAMP()
      WHERE `id` IN ( 
   /;
    foreach my $idUser (@$idUsers_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
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
      UPDATE `users` SET `logout_date` = CURRENT_TIMESTAMP()
      WHERE `id` IN ( 
   /;
    foreach my $idUser (@$idUsers_ref) {
        $query .= ' ?,';
    }
    chop($query);
    $query .= ' )';
    $self->do( $query, @$idUsers_ref );
}

##@method arrayref searchUsers(%args)
#@brief Executes a user search
sub searchUsers {
    my ( $self, %args ) = @_;
    my $query = q/
    SELECT
        `ISPs`.`name` as `ISP`,
        `codes`.`code` as `code`,
        `towns`.`name` as `town`,
        `mynickID` as `nickID`, `mysex` AS `sex`,
        `mynickname` as `nickname`,
        `myage` as `age`,
        `citydios`.`townzz` as `city`,
        `users`.`creation_date`,
        `users`.`update_date`,
        `users`.`logout_date` AS `logout` FROM `users` 
        LEFT OUTER JOIN `codes` ON `codes`.`id` = id_code
        LEFT OUTER JOIN `ISPs` ON `id_ISP` = `ISPs`.`id`
        LEFT OUTER JOIN `towns` ON `towns`.`id` = `id_town`
        LEFT OUTER JOIN `citydios`
        ON `users`.`citydio` = `citydios`.`id` 
        WHERE /;
    my @values   = ();
    my $and      = '';
    my %name2col = ( 'town' => '`towns`.`name`', 'ISP' => '`ISPs`.`name`' );
    
    my $usersOnline;
    if (exists $args{'__usersOnline'}) {
        delete  $args{'__usersOnline'};
        $usersOnline = 1;
    } else {
        $usersOnline = 0;
    }

    foreach my $name ( keys %args ) {
        my $val = $args{$name};
        if ( exists $name2col{$name} ) {
            $name = $name2col{$name};
        }
        else {
            $name = '`' . $name . '`';
        }
        $query .= $and . ' ' . $name;

        if ( ref($val) eq 'ARRAY' ) {
            $query .= ' IN (';
            foreach my $v (@$val) {
                $query .= ' ?,';
                push @values, $v;
            }
            chop($query);
            $query .= ')';

        }
        else {
            if ( $val =~ m{%} ) {
                $query .= ' like ?';
            }
            else {
                $query .= ' = ?';
            }
            push @values, $val;
        }
        $and = ' AND';
    }
    if ($usersOnline) {
         $query .= ' AND `logout_date` IS NULL' 
                .  ' AND  `users`.`update_date` >= '
                .  ' DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 MINUTE)'
    }

    $query .= ' ORDER BY `update_date`';
    my $sth = $self->execute( $query, @values );
    my $hash_ref;
    my @result = ();
    while ( $hash_ref = $sth->fetchrow_hashref ) {
        push @result, $hash_ref;
    }
    return \@result;
}

##@method void displaySearchUsers(%args)
#@brief Displays the result of a query on the console
sub displaySearchUsers {
    my $self       = shift;
    my $result_ref = $self->searchUsers(@_);
    if ( scalar @$result_ref == 0 ) {
        print STDOUT "No user was found.\n";
        return;
    }

    #Calculating the maximum width of the columns
    my @names = keys %{ $result_ref->[0] };
    my %max   = ();
    foreach my $name (@names) {
        $max{$name} = length($name);
    }
    foreach my $row_ref (@$result_ref) {
        if ( exists $row_ref->{'town'} and $row_ref->{'town'} =~ m{^FR- (.+)} )
        {
            $row_ref->{'town'} = $1;
        }
        foreach my $name ( keys %$row_ref ) {
            my $val = $row_ref->{$name};
            if ( !defined $val ) {
                $val = '-';
                $row_ref->{$name} = $val;
            }
            $max{$name} = length($val) if length($val) > $max{$name};
        }
    }

    #Create the separation line
    my $lineSize = 0;
    foreach my $name (@names) {
        $lineSize += $max{$name} + 3;
    }
    $lineSize--;
    my $separator = '!' . ( '-' x $lineSize ) . '!';

    #Displays the table header
    my $line = '';
    for ( my $i = 0 ; $i < scalar(@names) ; $i++ ) {
        $line .=
          '! ' . sprintf( '%-' . $max{ $names[$i] } . 's', $names[$i] ) . ' ';
    }
    $line .= '!';
    print STDOUT $separator . "\n";
    print STDOUT $line . "\n";
    print STDOUT $separator . "\n";

    #Displays the result of the query
    my $count = 0,;
    foreach my $row_ref (@$result_ref) {
        $line = '';
        foreach my $name ( keys %$row_ref ) {
            my $val = $row_ref->{$name};
            $line .= '! ' . sprintf( '%-' . $max{$name} . 's', $val ) . ' ';
        }
        $line .= '!';
        print STDOUT $line . "\n";
        $count++;
    }
    print STDOUT $separator . "\n";
    print STDOUT "- $count user(s) displayed\n";
}

1;
