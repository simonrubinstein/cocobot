# @created 2012-03-19
# @date 2012-06-16
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

    #Real zip code
    'zip',
    ## Custom code that corresponds to zip code.
    'citydio',
    'mystat',
    'myXP',
    ## 4 = Premium Subscription
    'myver',
    ## String retrieved by the function infuz()
    'infuz',
    'code',
    'ISP',
    'status',
    'premium',
    'level',
    'since',
    'town'
);

##@method void init(%args)
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
        'mynickname', 'myage', 'mysex', 'mynickID', 'citydio', 'mystat', 'myXP',
        'myver', 'code', 'ISP', 'status', 'premium', 'level', 'since', 'town',

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
}

##@method boolean isMan()
#@brief Checks whether the user is or is not a man
#@return boolean 1 if the user is a man or 0 otherwise
sub isMan {
    my ($self) = @_;
    if ( $self->mysex() % 5 == 1 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method boolean isWoman()
#@brief Checks whether the user is or is not a woman
#@return boolean 1 if the user is a woman or 0 otherwise
sub isWoman {
    my ($self) = @_;
    if ( $self->mysex() % 5 == 2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

##@method void setInfuz($infuz)
#@brief Parse and extracts the information of the 'infuz' string.
#@param string $infuz
sub setInfuz {
    my ( $self, $infuz ) = @_;
    $self->infuz($infuz);
    my @lines = split( /\n/, $infuz );
    if (
        $lines[0] =~ m{.*code:\s([A-Za-z0-9]{3})
                        \s\-(.*)$}xms
      )
    {
        $self->code($1);
        $self->ISP( trim($2) );
    }
    else {
        die error("string '$lines[0]' is bad. infuz: $infuz");
    }
    if (
        $lines[1] =~ m{.*statu(?:t:)?\s([0-9]+)
                       \s*(PREMIUM)?
                       \s*niveau:\s([0-9]+)
                       \sdepuis
                       \s(-?[0-9]+).*$}xms
      )
    {
        $self->status($1);
        $self->premium( defined $2 ? 1 : 0 );
        $self->level($3);
        $self->since($4);
    }
    else {
        $self->status(0);
        $self->premium(0);
        $self->level(0);
        $self->since(0);
        error("string '$lines[1]' is bad. infuz: $infuz");
    }
    if ( $lines[2] =~ m{Ville: (.*)$} ) {
        $self->town( trim($1) );
    }
    else {
        die error("string '$lines[2]' is bad. infuz: $infuz");
    }
}

##@method string citydio2zip()
#@brief Converts custom zip code member to real zip code and city
#@return string Real zip code and city (i.e. '92100 Boulogne Billancourt')
sub citydio2zip {
    my ($self) = @_;
    my $allZipCodes =
      Cocoweb::Config->instance()->getConfigFile( 'zip-codes.txt', 'ZipCodes' );
    $self->zip( $allZipCodes->getZipAndTownFromCitydio( $self->citydio() ) );
    return $self->zip();
}

1;

