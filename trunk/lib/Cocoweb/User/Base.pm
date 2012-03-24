# @created 2012-03-19
# @date 2012-03-24
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
package Cocoweb::User::Base;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use base 'Cocoweb::Object';

__PACKAGE__->attributes(
    ## A nickname from 4 to 16 characters.
    'mynickname',
    ## Age from 15 to 89 years.
    'myage',
    ## Sex: 1 = male or 2 = female.
    'mysex',
    ## nickname ID for current session
    'mynickID',
    ## Custom code that corresponds to zip code.
    'citydio',
    'mystat',
    'myXP',
    ## 4 = Premium Subscription
    'myver',
    ## String retrieved by the function infuz()
    'infuzSting',
    ##'infuzString' exploded in a hash table
    'infuz',
);

sub init {
    my ( $self, %args ) = @_;
}

##@method boolean isPremiumSubscription()
#@brief Verifies whether the user has a subscription premium
#@return boolean 1 if the user has a subscription premium or 0 otherwise
sub isPremiumSubscription {
    my ($self) = @_;
    if ( $self->myver() > 3 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method void display()
#@brief Prints on one line some member variables to the console
#       of the user object
sub display {
    my $self  = shift;
    my @names = (
        'mynickname', 'myage',  'mysex', 'mynickID',
        'citydio',    'mystat', 'myXP',  'myver'
    );
    foreach my $name (@names) {
        print STDOUT $name . ':' . $self->$name() . '; ';
    }
    print STDOUT "\n";

}

##@method void show()
#@brief Prints some member variables to the console of the user object
sub show {
    my $self  = shift;
    my @names = (
        'mynickname', 'myage',  'mysex', 'mynickID',
        'citydio',    'mystat', 'myXP',  'myver'
    );
    my $max = 1;
    foreach my $name (@names) {
        $max = length($name) if length($name) > $max;
    }
    $max++;
    foreach my $name (@names) {
        print STDOUT sprintf( '%-' . $max . 's ' . $self->$name(), $name . ':' )
          . "\n";
    }
    my $infuz_ref = $self->infuz();
    return if scalar( keys %$infuz_ref ) == 0;
    foreach my $name ( keys %$infuz_ref ) {
        print STDOUT
          sprintf( '%-' . $max . 's ' . $infuz_ref->{$name}, $name . ':' )
          . "\n";
    }
}

##@method boolean isMan()
#@brief Checks whether the user is or is not a man
#@return boolean
sub isMan {
    my ($self) = @_;
    if ( $self->mysex() == 1 or $self->mysex() == 6 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean isWoman()
#@brief Checks whether the user is or is not a woman
#@return boolean
sub isWoman {
    my ($self) = @_;
    if ( $self->mysex() == 2 or $self->mysex() == 7 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method void setInfuz($infuzString)
sub setInfuz {
    my ( $self, $infuzString ) = @_;
    print "$infuzString\n";
    $self->infuzSting($infuzString);
    my @lines = split( /\n/, $infuzString );
    my $infuz_ref = $self->infuz();
    if (
        $lines[0] =~ m{.*code:\s([A-Za-z0-9]{3})
                        \s\-(.*)$}xms
      )
    {
        $infuz_ref->{'code'} = $1;
        $infuz_ref->{'ISP'}  = trim($2);
    }
    else {
        die error("string '$lines[0]' is bad");
    }
    if (
        $lines[1] =~ m{.*statu(?:t:)?\s([0-9]+)
                       \s*(PREMIUM)?
                       \s*niveau:\s([0-9]+)
                       \sdepuis
                       \s([0-9]+).*$}xms
      )
    {
        $infuz_ref->{'status'}  = $1;
        $infuz_ref->{'premium'} = defined $2 ? 1 : 0;
        $infuz_ref->{'level'}   = $3;
        $infuz_ref->{'since'}   = $4;
    }
    else {
        die error("string '$lines[1]' is bad");
    }
    if ( $lines[2] =~ m{Ville: (.*)$} ) {
        $infuz_ref->{'town'} = trim($1);
    }
    else {
        die error("string '$lines[2]' is bad");
    }
}

1;

