# @created 2012-03-19
# @date 2016-07-07
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
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
package Cocoweb::User::BaseList;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use Cocoweb::User;
use base 'Cocoweb::Object';

__PACKAGE__->attributes('all');

##@method void init(%args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults( 'all' => {} );
}

##@method void clearFlags()
#@brief Reset at zero 'isNew', 'isView', 'hasChange'
#       and 'updateDbRecord' data members of each user
sub clearFlags {
    my ($self) = @_;
    my $user_ref = $self->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        $user->isNew(0);
        $user->isView(0);
        $user->hasChange(0);
        $user->updateDbRecord(0);
    }
}

##@method void clearRecentFlags()
#@brief Reset at zero 'recent' data member of each user
sub clearRecentFlags {
    my ($self) = @_;
    my $user_ref = $self->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        $user->isRecent(0);
    }
}

##@method object getUser($id)
#@brief Returns a user object from its id or nickname id
#@return object A 'Cocoweb::User' object
sub getUser {
    my ( $self, $id ) = @_;
    my $user_ref = $self->all();
    if ( !exists $user_ref->{$id} ) {
        warning("The user ID $id has not been found");
        return;
    }
    else {
        return $user_ref->{$id};
    }
}

##@method void addUser($id)
#@brief Add a user to the list 
#@param object A 'Cocoweb::User' object
sub addUser {
    my ( $self, $user ) = @_;
    my $user_ref = $self->all();
    my $id = $user->mynickID(); 
    if ( exists $user_ref->{$id} ) {
        die error("The user ID $id already exists");
    }
    else {
        $user_ref->{$id} = $user; 
    }
}

##@method void display(%args)
#@brief Displays the whole list of nicknames in the terminal
sub display {
    my ( $self, %args ) = @_;
    my ( $sex, $nickmaneWanted, $old, $nicknames2filter_ref );
    $sex            = $args{'mysex'}     if exists $args{'mysex'};
    $old            = $args{'myage'}     if exists $args{'myage'};
    $nickmaneWanted = $args{'mynickame'} if exists $args{'mynickame'};
    $nicknames2filter_ref = $args{'nicknames2filter'} if exists $args{'nicknames2filter'};
    
    my @titles =
      ( 'Id', 'Nickname', 'Sex', 'Old', 'City', 'Ver', 'Stat', 'XP' );
    my @names = (
        'mynickID', 'mynickname', 'mysex',  'myage',
        'zip',      'myver',      'mystat', 'myXP'
    );
    my %max = ();

    for ( my $i = 0 ; $i < scalar(@names) ; $i++ ) {
        $max{ $names[$i] } = length( $titles[$i] );
    }
    my %sexCount = ();
    my $user_ref = $self->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        $user->citydio2zip();
        foreach my $name (@names) {
            my $l = length( $user->$name );
            $max{$name} = $l if $l > $max{$name};
        }
        $sexCount{ $user->mysex() }++;
    }

    my $lineSize = 0;
    foreach my $name (@names) {
        $lineSize += $max{$name} + 3;
    }
    $lineSize--;
    my $separator = '!' . ( '-' x $lineSize ) . '!';

    print STDOUT $separator . "\n";
    my $line = '';
    for ( my $i = 0 ; $i < scalar(@names) ; $i++ ) {
        $line .=
          '! ' . sprintf( '%-' . $max{ $names[$i] } . 's', $titles[$i] ) . ' ';
    }
    $line .= '!';
    print STDOUT $line . "\n";
    print STDOUT $separator . "\n";

    my $count = 0,;
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};

        if ( defined $sex ) {

            my $mysex = $user->mysex();
            if ( $sex == 1 ) {
                next if !$user->isMan();
            }
            elsif ( $sex == 2 ) {
                next if !$user->isWoman();
            }
            else {
                next;
            }
        }
        next
          if defined $nickmaneWanted
              and $user->mynickname() !~ m{^.*$nickmaneWanted.*$}i;
        next if defined $nicknames2filter_ref and exists $nicknames2filter_ref->{$user->mynickname()};
        next if defined $old and $user->myage() != $old;
        $line = '';
        foreach my $k (@names) {
            $line .= '! ' . sprintf( '%-' . $max{$k} . 's', $user->$k ) . ' ';
        }
        $line .= '!';
        print STDOUT $line . "\n";
        $count++;
    }
    print STDOUT $separator . "\n";

    my ( $womanCount, $manCount ) = ( 0, 0 );
    foreach my $sex ( keys %sexCount ) {
        my $cnt = $sexCount{$sex};
        if ( $sex % 5 == 2 ) {
            $womanCount += $cnt;
        }
        elsif ( $sex % 5 == 1 ) {
            $manCount += $cnt;
        }
    }
    print STDOUT "- $count user(s) displayed\n";
    print STDOUT "- Number of woman(s): $womanCount\n";
    print STDOUT "- Number of man(s):   $manCount\n";
}

1
