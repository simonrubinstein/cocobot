# @created 2012-02-17
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
package Cocoweb::Request;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Config;
use Cocoweb::Config::Hash;
use Cocoweb::Encode;
use Cocoweb::Response;
use Cocoweb::User::List;
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use Encode qw(encode FB_PERLQQ);
use LWP::UserAgent;
use Time::HiRes qw(usleep nanosleep);
use utf8;
no utf8;

__PACKAGE__->attributes(
    'agent',
    'urlav',
    'myport',
    'url1',
    ## 0 = all; 1 = mens;  womens: 2
    'genru',
    ## 0 = all; 1 = -30 / 2 = 20 to 40 / 3 = 30 to 50 / 4 = 40 and more
    'yearu',
    'usersList',
    'speco',
    'convert',
    'timz1',
    'rechrech'
);

my $conf_ref;
my $agent_ref;
my $userAgent;

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;

    my $logUsersListInDB =
      ( exists $args{'logUsersListInDB'} and $args{'logUsersListInDB'} )
      ? 1
      : 0;

    if ( !defined $conf_ref ) {
        my $conf = Cocoweb::Config->instance()->getConfigFile('request.conf');
        $conf_ref = $conf->all();
        foreach my $name (
            'urly0',  'urlprinc',    'current-url', 'avatar-url',
            'avaref', 'urlcocoland', 'urlav'
          )
        {
            $conf->isString($name);
        }
        $agent_ref = $conf->getHash('user-agent');
        my $uaConf = Cocoweb::Config::Hash->new( 'hash' => $agent_ref );
        $uaConf->isString('agent');
        $uaConf->isInt('timeout');
        $uaConf->isHash('header');
        $userAgent = LWP::UserAgent->new(
            'agent'   => $agent_ref->{'agent'},
            'timeout' => $agent_ref->{'timeout'}
        );
    }

    my $myport = 3000 + randum(1000);

    $self->attributes_defaults(
        'agent'  => $agent_ref,
        'urlav'  => $conf_ref->{'urlav'},
        'myport' => $myport,
        'url1'   => $conf_ref->{'urly0'} . ':' . $myport . '/',
        'genru'  => 0,
        'yearu'  => 0,
        'usersList' =>
          Cocoweb::User::List->new( 'logUsersListInDB' => $logUsersListInDB ),
        'speco'    => 0,
        'convert'  => Cocoweb::Encode->instance(),
        'timz1'    => 0,
        'rechrech' => 0
    );
}

##@method string getValue($name)
#@brief Returns a value in the configuration file 'request.conf'
#@param string $name A name value to return
#@rerturn string The requested value
sub getValue {
    my ( $self, $name ) = @_;
    if ( exists $conf_ref->{$name} ) {
        return $conf_ref->{$name};
    }
    else {
        croak error( 'Error: The "' 
              . $name
              . '" value was not found in the configuration.' );
    }
}

## @method object execute($url, $cookie_ref)
#@brief Executes a HTTP request with the object HTTP::Request
#@param string An HTTP request method, e.g. 'GET' or 'POST'
#@param string An URL for the HTTP request
#@param hashref
#@return object A HTTP::Response object
sub execute {
    my ( $self, $method, $url, $cookie_ref ) = @_;
    croak error("The HTTP method is missing")             if !defined $method;
    croak error("The URL of the HTTP request is missing") if !defined $url;
    my $req = HTTP::Request->new( $method => $url );
    debug($url);
    foreach my $field ( keys %{ $agent_ref->{'header'} } ) {
        $req->header( $field => $agent_ref->{'header'}->{$field} );
    }
    if ( defined $cookie_ref and scalar keys %$cookie_ref > 0 ) {
        debug( ( scalar keys %$cookie_ref ) . ' cookies where found' );
        my $cookieStr = '';
        foreach my $k ( keys %$cookie_ref ) {
            my $val = $self->jsEscape( $cookie_ref->{$k} );
            $cookieStr .= $k . "=" . $val . ';';
        }
        chop($cookieStr);
        $req->header( 'Cookie' => $cookieStr );
    }

    #debug($req->as_string());
    my $response = $userAgent->request($req);
    if ( !$response->is_success() ) {
        croak error( $response->status_line() );
    }
    return $response;
}

## @method string jsEscape($string)
# @brief works to escape a string to JavaScript's URI-escaped string.
# @author Koichi Taniguchi
sub jsEscape {
    my ( $self, $string ) = @_;
    $string =~ s{([\x00-\x29\x2C\x3A-\x40\x5B-\x5E\x60\x7B-\x7F])}
    {'%' . uc(unpack('H2', $1))}eg;    # XXX JavaScript compatible
    $string = encode( 'ascii', $string, sub { sprintf '%%u%04X', $_[0] } );
    return $string;
}

##@method void getCityco($user)
#@brief Performs an HTTP request to retrieve the custom code
#       corresponding to zip code.
#@param object $user An 'Cocoweb::User::Connected' object
sub getCityco {
    my ( $self, $user ) = @_;

    my $zip = $user->zip();
    croak error("Error: The '$zip' zip code is invalid!")
      if $zip !~ /^\d{5}$/;
    my $i = index( $zip, '0' );
    if ( $i == 0 ) {
        $zip = substr( $zip, 1, 5 );
    }
    my $url      = $conf_ref->{'urlcocoland'} . $zip . '.js';
    my $response = $self->execute( 'GET', $url );
    my $res      = $response->content();

    # Retrieves a string like "var cityco='30926*PARIS*';"
    if ( $res !~ m{var\ cityco='([^']+)';}xms ) {
        die error( 'Error: cityco have not been found!'
              . 'The HTTP requests "'
              . $url
              . '" return: '
              . $res );
    }
    my $cityco = $1;

    #debug("cityco: $cityco");
    my @tmp = split( /\*/, $cityco );
    my ( $citydio, $townzz );
    my $count = scalar @tmp;
    die error("Error: The cityco is not valid (cityco: $cityco)")
      if $count % 2 != 0
          or $count == 0;

    if ( $count == 2 ) {
        $citydio = $tmp[0];
        $townzz  = $tmp[1];
    }
    else {
        my $r = int( rand( $count / 2 ) );
        $r += $r;
        $citydio = $tmp[$r];
        $townzz  = $tmp[ $r + 1 ];
    }

    #debug("citydio: $citydio; townzz: $townzz");
    $user->citydio($citydio);
    $user->townzz($townzz);
}

##@method void firsty($user)
#@brief The first HTTP request sent to the server
#@param object $user An 'Cocoweb::User::Connected' object
sub firsty {
    my ( $self, $user ) = @_;
    $self->agix( $user,
            $self->url1() . '40'
          . $user->mynickname() . '*'
          . $user->myage()
          . $user->mysex()
          . $user->citydio()
          . $user->myavatar()
          . $self->speco()
          . $user->mypass() );
}

##@method void agir($user, $txt1)
#@brief Initiates a standard request to the server
#@param object $user An 'Cocoweb::User::Connected' object
#@param string $txt1 The parameter of the HTTP request
sub agir {
    my ( $self, $user, $txt3 ) = @_;
    my $code = substr( $txt3, 0, 2 );
    if ( $code != 10 and $code != 89 and $code != 48 and $code != 83 ) {

        #info($txt3);
    }

    $self->agix( $user,
            $self->url1()
          . substr( $txt3, 0, 2 )
          . $user->mynickID()
          . $user->monpass()
          . substr( $txt3, 2 ) );
}

##@method void agix($user, $url, $cookie_ref)
#@brief Performs an HTTP Requests to invoke a remote method
#@param object $user An 'Cocoweb::User::Connected' object
#@param string An URL for the HTTP request
#@param hashref $cookie_ref A hash that contains possible cookies.
sub agix {
    my ( $self, $user, $url, $cookie_ref ) = @_;
    croak error("The URL of the HTTP request is missing") if !defined $url;

    #info("url: $url");
    my $response = $self->execute( 'GET', $url, $cookie_ref );
    my $res = $response->content();

    #debug($res);
    die error(
        'Error: the JavaScript function not found in the string: ' . $res )
      if $res !~ m{^([^\(]+)\('([^']*)'\)}xms;
    my $function = $1;
    my $arg      = $2;
    die error('The method called "' . $function . '()" is unknown!')
        if $function ne 'process1';
    $response = Cocoweb::Response->new();
    return $response->$function( $self, $user, $arg );
}

##@method void searchnow($user)
#@brief Call the remote method to retrieve the list of pseudonyms.
#@param object $user An 'User::Connected' object
sub searchnow {
    my ( $self, $user ) = @_;
    $self->agir( $user, '10' . $self->genru() . $self->yearu() );
}

##@method void cherchasalon($user)
#@param object $user An 'User::Connected' object
sub cherchasalon {
    my ( $self, $user ) = @_;
    $self->agir( $user, '89' );
}

##@method void actuam($user)
#@brief Get the list of contacts, nicknamed 'amiz'
#@param object $user An 'User::Connected' object
#@return string
sub actuam {
    my ( $self, $user ) = @_;
    $self->agir( $user, '48' );
}

##@method void requestMessagesFromUsers($user)
#@brief Returns the messages sent by other users
sub requestMessagesFromUsers {
    my ( $self, $user ) = @_;
    $self->agir( $user, $user->camon() . $user->typcam() );
}

##@method void lancetimer($user)
#@brief Method that periodically performs requests to the server
#@param object $user An 'User::Connected' object
sub lancetimer {
    my ( $self, $user ) = @_;
    my $timz1 = $self->timz1();
    $timz1++;
    $self->timz1($timz1);

    if ( ( $timz1 % 160 ) == 39 ) {
        my $users_ref = $self->usersList()->getUsersNotViewed();
        $self->isDead( $user, $users_ref );
    }

    if ( ( $timz1 % 28 ) == 9 ) {
        if ( $self->rechrech() ) {
            $self->searchnow($user);
        }
        else {
            $self->rechrech(1);
        }
    }
    $self->requestMessagesFromUsers($user);
}

##@method void getUserInfo()
#@brief Get the number of days remaining until the end of
#       the Premium subscription.
#       This method works only for user with a Premium subscription
#@param object $user An 'User::Connected' object
sub getUserInfo {
    my ( $self, $user ) = @_;
    $self->agir( $user, '77369' );
}

##@method void searchCode()
#@brief Search a nickname from his code of 3 characters
#       This method works only for user with a Premium subscription
#@param object $user An 'User::Connected' object
#@param string $code A nickname code (i.e. WcL)
sub searchCode {
    my ( $self, $user, $code ) = @_;
    $self->agir( $user, '83733000000' . $code );
}

sub isDead {
    my ( $self, $user, $users_ref ) = @_;
    return if scalar(@$users_ref) < 1;
    my $nickIds = '';
    foreach my $userWanted (@$users_ref) {
        $nickIds .= $userWanted->mynickID();
    }
    $self->agir( $user, '90' . $nickIds );
}

##@method void writus($user, $userWanted, $s1) 
#@brief Performs a request to write a message to another user
#@param object $user An 'User::Connected' object
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#              The user for whom the message is intended
#@param string $s1 The message to write to the user
sub writus {
    my ( $self, $user, $userWanted, $s1 ) = @_;
    return if !defined $s1 or length($s1) == 0;
    my $s2 = '';
    $s2 = $self->convert()->writo($s1);
    $self->agir( $user,
        '99' . $userWanted->mynickID() . $user->roulix() . $s2 );
    my $roulix = $user->roulix();

    if ( ++$roulix > 8 ) {
        $roulix = 0;
    }
    $user->roulix($roulix);
}

##@method string infuz($user, $userWanted)
#@brief Retrieves informations (unique code, ISP, status, level,
#       connection time a country code and city) about an user.
#       This information is not reliable.
#       this function is restricted to Premium subscribers.
#@param object $user       An 'User::Connected' object
#@param object $userWanted A 'CocoWeb::User::Wanted' object
#@return object A 'CocoWeb::User::Wanted' object
sub infuz {
    my ( $self, $user, $userWanted ) = @_;
    if ( $user->isPremiumSubscription() ) {
        my $infuzString =
          $self->agir( $user, '83555' . $userWanted->mynickID() );
        $userWanted->setInfuz($infuzString);
        return $userWanted;
    }
    else {
        warning('The command "infuz" is reserved for users with a'
              . ' Premium subscription.' );
        return;
    }
}

##@methode object getUsersList($user)
#@bref Request and returns the list of connected users
#@param object $user An 'User::Connected' object
#@return object A 'Cocoweb::User::List' object
sub getUsersList {
    my ( $self, $user ) = @_;
    $self->usersList()->clearFlags();
    foreach my $g ( 1, 2 ) {
        $self->genru($g);
        foreach my $y ( 1, 2, 3, 4 ) {
            $self->yearu($y);
            $self->searchnow($user);
        }
    }
    return $self->usersList();
}

sub checkDisconnectedUsers {
    my ( $self, $user ) = @_;
    my $users_ref = $self->usersList()->getUsersNotViewed();
    $self->isDead( $user, $users_ref );
}

##@method object searchNickname($user, $userWanted)
#@brief Search a nickname connected
#@param object $user      An 'User::Connected' object
#@param object $userWanted A CocoWeb::User::Wanted object
#@return object A CocoWeb::User
sub searchNickname {
    my ( $self, $user, $userWanted ) = @_;
    my $nickname = $userWanted->mynickname();
    $userWanted = $self->usersList()->checkIfNicknameExists($nickname);
    return $userWanted if defined $userWanted;
    foreach my $g ( 1, 2 ) {
        $self->genru($g);
        foreach my $y ( 1, 2, 3, 4 ) {
            $self->yearu($y);
            $self->searchnow($user);
            $userWanted = $self->usersList()->checkIfNicknameExists($nickname);
            return $userWanted if defined $userWanted;
        }
    }
    return $self->usersList()
      if !defined $nickname
          or length($nickname) == 0;
    return;
}

1;

