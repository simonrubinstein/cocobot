# @brief
# @created 2012-03-30
# @date 2018-04-05 
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2018
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
use Date::Parse;
use Time::Piece;
use Time::Seconds;

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
        $dbh = DBI->connect( $self->datasource(), $self->username(),
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
    foreach my $table ( 'users', 'nicknames', 'codes', 'ISPs', 'towns',
        'citydios' )
    {
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
    debug('Creation of the "codes" table.');
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `ISPs` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          varchar(128) BINARY NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB
ENDTXT
    debug('Creation of the "ISPs" table.');
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `towns` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `name`          varchar(128) BINARY NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`name`)
    ) ENGINE=InnoDB
ENDTXT
    debug('Creation of the "towns" table.');
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `nicknames` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `nickname`      varchar(19) BINARY NOT NULL,
     PRIMARY KEY  (`id`),
     UNIQUE KEY `name` (`nickname`)
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
    debug('Creation of the "citydios" table.');
    $self->do($query);

    $query = <<ENDTXT;
    CREATE TABLE IF NOT EXISTS `users` (
    `id`            int(10) unsigned NOT NULL auto_increment, 
    `id_code`       int(10) unsigned NOT NULL,
    `id_ISP`        int(10) unsigned NOT NULL,
    `id_town`       int(10) unsigned NOT NULL,
    `id_mynickname` int(10) unsigned NOT NULL,
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
     KEY `users_FKIndex1` (`id_code`),
     CONSTRAINT `users_ibfk_1` FOREIGN KEY (`id_code`)
       REFERENCES `codes` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
     KEY `users_FKIndex2` (`id_ISP`),
     CONSTRAINT `users_ibfk_2` FOREIGN KEY (`id_ISP`)
       REFERENCES `ISPs` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
     KEY `users_FKIndex3` (`id_town`),
     CONSTRAINT `users_ibfk_3` FOREIGN KEY (`id_town`)
       REFERENCES `towns` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION,
     CONSTRAINT `users_ibfk_4` FOREIGN KEY (`id_mynickname`)
       REFERENCES `nicknames` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION
    ) ENGINE=InnoDB
ENDTXT
    debug('Creation of the "users" table.');
    $self->do($query);

    #CONSTRAINT `users_ibfk_5` FOREIGN KEY (`citydio`)
    #  REFERENCES `citydios` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION

}

##@method integer _insertCode($code)
#@brief Insert or update a code in the code tables
#@param $code string A three character code
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

##@method integer _insertCode2($code)
#@brief Insert or update a code in the code tables
#@param $code string A three character code
sub _insertCode2 {
    my ( $self, $code ) = @_;
    my $sth = $self->execute( 'SELECT `id` FROM `codes` WHERE `code` = ?',
        $code );
    my $hash_ref = $sth->fetchrow_hashref();
    if ( defined $sth and exists $hash_ref->{'id'} ) {
        $self->_updateCode( $hash_ref->{'id'} );
        return $hash_ref->{'id'};
    }
    my $query = q/
      INSERT INTO `codes`
        (`code`, `creation_date`, `update_date`) 
        VALUES
        (?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
      /;
    $self->do( $query, $code );
    my $id = $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
    return $id;
}

##@method intege _insertNickname($nickname)
#@brief Insert or update a code in the code tables
#@param string $nickname A nickname
sub _insertNickname {
    my ( $self, $nickname ) = @_;
    my $sth
        = $self->execute( 'SELECT `id` FROM `nicknames` WHERE `nickname` = ?',
        $nickname );
    my $hash_ref = $sth->fetchrow_hashref();
    return $hash_ref->{'id'} if defined $sth and exists $hash_ref->{'id'};
    my $query = q/
      INSERT INTO `nicknames`
        (`nickname`) 
        VALUES
        (?)
      /;
    $self->do( $query, $nickname );
    my $id = $self->dbh()->last_insert_id( undef, undef, 'nicknames', undef );
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

##@method integer insertUser($user, $idCode, $idISP, $idTown, $idNickname)
#@brief Inserts a new user in the "users" table
sub _insertUser {
    my ( $self, $user, $idCode, $idISP, $idTown, $idNickname ) = @_;
    my $query = q/
      INSERT INTO `users`
        (`id_code`, `id_ISP`, `id_town`, `id_mynickname`, `mynickID`, `mysex`,
          `myage`, `citydio`, `myXP`, `myver`, `myStat`, `status`, `level`, `since`,
          `premium`, `creation_date`, `update_date`) 
        VALUES
        (?, ?, ?, ?, ?, ?,
        ?, ?, ?, ?, ?, ?, ?, ?,
        ?, CURRENT_TIMESTAMP(), CURRENT_TIMESTAMP())
        /;

    $self->do(
        $query,           $idCode,
        $idISP,           $idTown,
        $idNickname,      $user->mynickID(),
        $user->mysex(),   $user->myage(),
        $user->citydio(), $user->myXP(),
        $user->myver(),   $user->mystat(),
        $user->status(),  $user->level(),
        $user->since(),   $user->premium()
    );
    return $self->dbh()->last_insert_id( undef, undef, 'codes', undef );
}

##@method _updateUser($user, $idCode, $idISP, $idTown, $idNickname)
sub _updateUser {
    my ( $self, $user, $idCode, $idISP, $idTown, $idNickname ) = @_;
    my $query = q/
      UPDATE `users` SET `id_code` = ?, `id_ISP` = ? , `id_town` = ?,
        `id_mynickname` = ?, `mynickID` = ?, `mysex` = ?, `myage` = ?,
        `citydio` = ?, `myXP` = ?, `myver` = ?, `myStat` = ?, `status` = ?,
        `level` = ?, `since` = ?, `premium` = ?,
        `update_date` = CURRENT_TIMESTAMP()
        WHERE `id` = ?
        /;

    $self->do(
        $query,           $idCode,
        $idISP,           $idTown,
        $idNickname,      $user->mynickID(),
        $user->mysex(),   $user->myage(),
        $user->citydio(), $user->myXP(),
        $user->myver(),   $user->mystat(),
        $user->status(),  $user->level(),
        $user->since(),   $user->premium(),
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
    debug(    'Set '
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

    my $isonlynicks;
    if ( exists $args{'__onlynicks'} ) {
        delete $args{'__onlynicks'};
        $isonlynicks = 1;
    }
    else {
        $isonlynicks = 0;
    }

    my $query;
    if ($isonlynicks) {
        $query = q/
        SELECT DISTINCT
           `nickname` /;
    }
    else {
        $query = q/
        SELECT
            `ISPs`.`name` as `ISP`,
            `codes`.`code` as `code`,
            `towns`.`name` as `town`,
             `mynickID` as `nickID`, `mysex` AS `sex`,
            `nickname`,
            `myage` as `age`,
            `citydios`.`townzz` as `city`,
            `users`.`creation_date`,
            `users`.`update_date`,
            `users`.`logout_date` AS `logout` /;
    }
    $query .= q/
        FROM `users` 
        LEFT OUTER JOIN `codes` ON `codes`.`id` = id_code
        LEFT OUTER JOIN `ISPs` ON `id_ISP` = `ISPs`.`id`
        LEFT OUTER JOIN `towns` ON `towns`.`id` = `id_town`
        LEFT OUTER JOIN `citydios`
        ON `users`.`citydio` = `citydios`.`id` 
        LEFT OUTER JOIN `nicknames`
        ON `id_mynickname` = `nicknames`.`id` 
        WHERE /;

    my @values   = ();
    my $and      = '';
    my %name2col = (
        'town'     => '`towns`.`name`',
        'ISP'      => '`ISPs`.`name`',
        'nickname' => '`nicknames`.`nickname`'
    );

    my $usersOnline;
    if ( exists $args{'__usersOnline'} ) {
        delete $args{'__usersOnline'};
        $usersOnline = 1;
    }
    else {
        $usersOnline = 0;
    }

    my $ileDeFrance;
    if ( exists $args{'__IleDeFrance'} ) {
        delete $args{'__IleDeFrance'};
        $ileDeFrance = 1;
    }
    else {
        $ileDeFrance = 0;
    }

    my $paris;
    if ( exists $args{'__paris'} ) {
        delete $args{'__paris'};
        $paris = 1;
    }
    else {
        $paris = 0;
    }

    my $nickname2filter_ref;
    if ( exists $args{'__nicknames2filter'} ) {
        $nickname2filter_ref = $args{'__nicknames2filter'};
        delete $args{'__nicknames2filter'};
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
        $query
            .= ' AND `logout_date` IS NULL'
            . ' AND  `users`.`update_date` >= '
            . ' DATE_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 MINUTE)';
    }

    if ($ileDeFrance) {
        $query .= ' AND `id_town` < 840';
    }
    if ($paris) {
        $query .= ' AND `citydio` >= 30915 AND `citydio` <= 30935';
    }
    if ( defined $nickname2filter_ref ) {
        $query .= ' AND `nicknames`.`nickname` NOT IN (';
        foreach my $nick (@$nickname2filter_ref) {
            $query .= ' ?,';
            push @values, $nick;
        }
        chop($query);
        $query .= ')';
    }

    $query .= ' ORDER BY `creation_date`' if !$isonlynicks;
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
#@param boolean isOnlyNicks 1: Displays only the nickname.
#@param integer integer $filtersCode 0 or 1
#@param boolean $output 1 HTML output or plain text otherwise
sub displaySearchUsers {
    my $self        = shift;
    my $isOnlyNicks = shift;
    my $filtersCode = shift;
    my $output      = shift;

    push @_, '__onlynicks', 1 if $isOnlyNicks;

    my $result_ref = $self->searchUsers(@_);
    if ( scalar @$result_ref == 0 ) {
        print STDOUT "No user was found.\n";
        return;
    }

    #Calculating the maximum width of the columns
    my @names = sort keys %{ $result_ref->[0] };
    my %max   = ();
    foreach my $name (@names) {
        $max{$name} = length($name);
    }
    my $totalTime = 0;
    foreach my $row_ref (@$result_ref) {
        if ( exists $row_ref->{'town'}
            and $row_ref->{'town'} =~ m{^FR- (.+)} )
        {
            $row_ref->{'town'} = $1;
        }
        if ( exists $row_ref->{'creation_date'} ) {
            my $startime = $row_ref->{'creation_date'};
            my $endtime;
            if ( exists $row_ref->{'logout'}
                and defined $row_ref->{'logout'} )
            {
                $endtime = $row_ref->{'logout'};
            }
            else {
                $endtime = $row_ref->{'update_date'};
            }
            my $delta = ( str2time($endtime) ) - ( str2time($startime) );
            $totalTime += $delta;
        }
        foreach my $name ( 'creation_date', 'logout', 'update_date' ) {
            if (    exists $row_ref->{$name}
                and defined $row_ref->{$name}
                and $row_ref->{$name}
                =~ m{^\d\d\d\d\-(\d\d\-\d\d\s\d\d:\d\d:\d\d)$} )
            {
                $row_ref->{$name} = $1;
            }
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
    my ( $line, $separator, $border, $border1, $border2, $border3 );
    if ( !$isOnlyNicks ) {
        my $lineSize = 0;
        foreach my $name (@names) {
            $lineSize += $max{$name} + 3;
        }
        $lineSize--;
        $separator = '!' . ( '-' x $lineSize ) . '!';

        if ($output) {
            $border1 = '<tr><td>';
            $border2 = '</td><td>';
            $border3 = '</td></tr>';
        }
        else {
            $border1 = $border2 = $border3 = '! ';
        }

        #Displays the table header
        $border = $border1;
        $line   = '';
        for ( my $i = 0; $i < scalar(@names); $i++ ) {
            $line
                .= $border
                . sprintf( '%-' . $max{ $names[$i] } . 's', $names[$i] )
                . ' ';
            $border = $border2;
        }
        $line .= $border3;
        print STDOUT $separator . "\n" if !$output;
        if ($output) {
            print
                '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">';
            print
                '<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr_FR" lang="fr_FR">';
            print
                '<head><title>Cocobot</title><meta content="text/html; charset=UTF-8" http-equiv="content-type"/></head><body><table><thead>';
        }
        print STDOUT $line . "\n";
        print STDOUT $separator . "\n" if !$output;
        print '</thead><tbody>' if $output;
    }
    else {
        ( $border, $border1, $border2, $border3 ) = ( '', '', '', '' );
    }

    #Displays the result of the query
    my $count = 0,;
    foreach my $row_ref (@$result_ref) {
        if ($filtersCode) {
            my $nick = $row_ref->{'nickname'};
            next if $nick !~ m{^[A-Z].*$};
        }
        $line   = '';
        $border = $border1;
        foreach my $name ( sort keys %$row_ref ) {
            my $val = $row_ref->{$name};
            $line
                .= $border . sprintf( '%-' . $max{$name} . 's', $val ) . ' ';
            $border = $border2;
        }
        $line .= $border3;
        print STDOUT $line . "\n";
        $count++;
    }
    if ( !$isOnlyNicks ) {
        print STDOUT '</tbody></table></body></html>' if $output;
        print STDOUT $separator . "\n" if !$output;
        print STDOUT "- $count user(s) displayed\n";
        print STDOUT "- $totalTime second(s);\n";
        my $val = Time::Seconds->new($totalTime);
        print STDOUT "- " . $val->pretty() . "\n";
    } else {
        print STDOUT "- $count user(s) displayed\n";
   }
}

1;
