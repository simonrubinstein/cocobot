# @created 2012-03-19
# @date 2018-07-26
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
package Cocoweb::User::Base;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;
use FindBin qw($Script);

use Cocoweb;
use Cocoweb::File;
use base 'Cocoweb::Object';

__PACKAGE__->attributes(
    ## A nickname from 4 to 16 characters.
    'mynickname',
    ## Age from 18 to 89 years.
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
    ## "code de vote", three chars extracted from "infuz" string.
    ## i.g.: cZj, 23m, Wcl, PXd
    'code',
    ## ISP, Internet Service Provider, extracted from "infuz" string.
    ## i.g.: Orange, SFR, Free SAS
    'ISP',
    'status',
    'premium',
    'level',
    'since',
    ## Geolocation extracted from "infuz" string.
    ## i.g.: FR- La Rochelle, FR- Paris, FR- Montpellier
    'town',
    ## Total messages sent by the user
    'messageCounter',
    ## Date of last message sent by the user (unix timestamp)
    'messageSentTime',
    ## Content of the message sent by the user
    'messageLast',
    ## true = The user had sent a message
    'isMessageWasSent'
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
        'mynickname', 'myage',   'mysex',  'mynickID',
        'zip',        'citydio', 'mystat', 'myXP',
        'myver'
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
        'mynickname', 'myage', 'mysex', 'mynickID', 'citydio', 'mystat',
        'myXP',
        'myver', 'code', 'ISP', 'status', 'premium', 'level', 'since', 'town',

    );
    my $max = 1;
    foreach my $name (@names) {
        $max = length($name) if length($name) > $max;
    }
    $max++;
    foreach my $name (@names) {
        print STDOUT
            sprintf( '%-' . $max . 's ' . $self->$name(), $name . ':' )
            . "\n";
    }
}

##@method void dump()
sub dump {
    my $self = shift;
    my $max  = 1;
    foreach my $name ( keys %$self ) {
        $max = length($name) if length($name) > $max;
    }
    $max++;
    foreach my $name ( keys %$self ) {
        print STDOUT
            sprintf( '%-' . $max . 's ' . $self->$name(), $name . ':' )
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
    debug($infuz);
    $self->infuz($infuz);
    my @lines = split( /\n/, $infuz );
    die error('The string "'
            . $infuz
            . '" does not have three lines! mynickname:'
            . $self->mynickname() )
        if ( scalar(@lines) != 3 );
    if ($lines[0] =~ m{.*code:\s(...)
                        \s\-(.*)$}xms
        )
    {
        $self->code($1);
        $self->ISP( trim($2) );
    }
    else {
        die error( "string '$lines[0]' is bad. infuz: $infuz! mynickname:"
                . $self->mynickname() );
    }
    if ($lines[1] =~ m{.*statu(?:t:)?\s([0-9]+)
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
    my $allZipCodes = Cocoweb::Config->instance()
        ->getConfigFile( 'zip-codes.txt', 'ZipCodes' );
    $self->zip( $allZipCodes->getZipAndTownFromCitydio( $self->citydio() ) );
    return $self->zip();
}

##@method int getZipcode()
sub getZipcode {
    my ($self) = @_;
    my $zip = $self->zip();
    return $zip if defined $zip;
    $zip = $self->citydio2zip() if !defined $zip;
    $self->zip($zip);
    return $zip;
}

##@method void hasSentMessage($message)
sub hasSentMessage {
    my ( $self, $message ) = @_;
    $self->isMessageWasSent(1);
    $self->messageSentTime(time);
    my $messageCounter = $self->messageCounter();
    $messageCounter++;
    $self->messageCounter($messageCounter);
    $self->messageLast($message);
    writeLog(
        'messages',
        sprintf(
            '%3s town: %-26s ISP: %-27s sex: %1s age: %2s nick: %-19s: '
                . $message,
            $self->code(),  $self->town(),  $self->ISP(),
            $self->mysex(), $self->myage(), $self->mynickname()
        )
    );
}
1;

