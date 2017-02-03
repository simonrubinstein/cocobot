# @created 2012-02-17
# @date 2017-30-01
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
#
# copyright (c) Simon Rubinstein 2010-2017
#
# https://github.com/simonrubinstein/cocobot
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
use IO::Socket::INET;
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
    ## 0 = all; 1 = -30 years old / 2 = 20 to 40 / 3 = 30 to 50 / 4 = 40 and more
    'yearu',
    'usersList',
    'speco',
    'convert',
    'timz1',
    'rechrech',
    'isAvatarRequest',
    'isInfuzNotToFast',
    'infuzNotToFastRegex',
    'profilTooNewRegex',
    'beenDisconnectedRegex',
    'beenDisconnected',
    'accountproblemRegex',
    'infuzMaxOfTries',
    'infuzPause1',
    'infuzPause2',
    'infuzMaxOfTriesAfterPause',
    'magicAuthString',
    'localIP',
    'publicIP',
    'isConfHTTPrequests',
    'isAddNewWriterUserIntoList',
    'isDieIfDisconnected'
);

my $conf_ref;
my $agent_ref;
my $userAgent;
my $removeListSearchCode;
my $removeListSearchcodePause1;
my $removeListDelay;
my $localIP;
my $publicIP;
my $isConfHTTPrequests;
my $infuzNotToFast;
my $profilTooNew;
my $beenDisconnectedRegex;
my $accountproblemRegex;
my $myport;

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;

    my $logUsersListInDB
        = ( exists $args{'logUsersListInDB'} and $args{'logUsersListInDB'} )
        ? 1
        : 0;

    my $isAvatarRequest
        = ( exists $args{'isAvatarRequest'} and $args{'isAvatarRequest'} )
        ? 1
        : 0;
    if ( !defined $conf_ref ) {
        my $conf = Cocoweb::Config->instance()
            ->getConfigFile( 'request.conf', 'File' );
        $conf_ref = $conf->all();
        foreach my $name (
            'urly0',             'urlprinc',
            'current-url',       'avatar-url',
            'avaref',            'urlcocoland',
            'urlav',             'url_initio.js',
            'magic-auth-string', 'get-ip-address-url',
            'remote-address-ipv4-default'
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

        $removeListSearchCode = $conf->getBool('remove_list_searchcode');
        $removeListSearchcodePause1
            = $conf->getInt('remove_list_searchcode_pause1');

        my $delay = $conf->getString('remove_list_delay');
        if ( $delay =~ m{^(\d+)s?$} ) {
            $removeListDelay = $1;
        }
        elsif ( $delay =~ m{^(\d+)m$} ) {
            $removeListDelay = $1 * 60;
        }
        elsif ( $delay =~ m{^(\d+)h$} ) {
            $removeListDelay = $1 * 3600;
        }
        elsif ( $delay =~ m{^(\d+)d$} ) {
            $removeListDelay = $1 * 86400;
        }
        else {
            croak "bad delay format: $delay. "
                . "Format excepted: 60, 60s, 60m, 24h or 15d";
        }

        eval { $self->getInitioJSVar( $conf_ref->{'url_initio.js'} ); };

        $conf->isInt('infuz-max-of-tries');
        $conf->isInt('infuz-pause1');
        $conf->isInt('infuz-pause2');
        $conf->isInt('infuz-max-of-tries-after-pause');
        $conf->isInt('remote-port-default');
        $isConfHTTPrequests    = $conf->getBool('isConfHTTPrequests');
        $infuzNotToFast        = $conf->getRegex('infuz-not-to-fast');
        $profilTooNew          = $conf->getRegex('profile-too-new');
        $beenDisconnectedRegex = $conf->getRegex('been-disconnected');
        $accountproblemRegex   = $conf->getRegex('account-problem');
        $myport                = 80;
    }

    if ( !defined $publicIP ) {
        my $req = HTTP::Request->new(
            'GET' => $conf_ref->{'get-ip-address-url'} );
        my $response = $userAgent->request($req);
        if ( !$response->is_success() ) {
            $publicIP = '216.58.209.35';
        }
        else {
            $publicIP = trim( $response->content() );
            $publicIP = '216.58.209.35'
                if $publicIP !~ m{^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$};

        }
    }

    # Discovering the local system's IP address
    if ( !defined $localIP ) {
        my $sock = IO::Socket::INET->new(
            'Proto'    => 'udp',
            'PeerAddr' => $conf_ref->{'remote-address-ipv4-default'},
            'PeerPort' => $conf_ref->{'remote-port-default'}
        );
        if ( !defined $sock ) {

            #Set a bogus IP address
            $localIP = '192.168.0.1';
        }
        else {
            $localIP = $sock->sockhost();
        }
    }

    $self->attributes_defaults(
        'agent'     => $agent_ref,
        'urlav'     => $conf_ref->{'urlav'},
        'myport'    => $myport,
        'url1'      => $conf_ref->{'urly0'} . ':' . $myport . '/',
        'genru'     => 0,
        'yearu'     => 0,
        'usersList' => Cocoweb::User::List->new(
            'logUsersListInDB'           => $logUsersListInDB,
            'removeListDelay'            => $removeListDelay,
            'removeListSearchCode'       => $removeListSearchCode,
            'removeListSearchcodePause1' => $removeListSearchcodePause1
        ),
        'speco'                 => 0,
        'convert'               => Cocoweb::Encode->instance(),
        'timz1'                 => 0,
        'rechrech'              => 0,
        'isAvatarRequest'       => $isAvatarRequest,
        'isInfuzNotToFast'      => 0,
        'infuzNotToFastRegex'   => $infuzNotToFast,
        'magicAuthString'       => $conf_ref->{'magic-auth-string'},
        'publicIP'              => $publicIP,
        'localIP'               => $localIP,
        'profilTooNewRegex'     => $profilTooNew,
        'beenDisconnectedRegex' => $beenDisconnectedRegex,
        'beenDisconnected'      => 0, 
        'accountproblemRegex'   => $accountproblemRegex,
        'infuzMaxOfTries'       => $conf_ref->{'infuz-max-of-tries'},
        'infuzPause1'           => $conf_ref->{'infuz-pause1'},
        'infuzPause2'           => $conf_ref->{'infuz-pause2'},
        'infuzMaxOfTriesAfterPause' =>
            $conf_ref->{'infuz-max-of-tries-after-pause'},
        'isConfHTTPrequests'         => $isConfHTTPrequests,
        'isAddNewWriterUserIntoList' => 0,
        'isDieIfDisconnected'        => 1
    );
}

##@method void getInitioJSVar($url)
#@brief Find the value of certain variables in the JavaScript code.
#@param string $url "initio.js" URL (http://www.coco.fr/chat/initio.js)
sub getInitioJSVar {
    my ( $self, $url ) = @_;
    return if !$self->isConfHTTPrequests();
    my $response = $self->execute( 'GET', $url );
    my $res = $response->content();
    foreach my $line ( split /\n/, $res ) {

        # var urly0="http://91.121.52.98";
        if ( $line =~ m{^\s*var\s+urly0="(http://\d+\.\d+\.\d+\.\d+)"} ) {
            my $urly0 = $1;
            debug( 'urly0 was found: ' . $urly0 );
            if ( $conf_ref->{'urly0'} ne $urly0 ) {
                warning(  'The URL has changed from '
                        . $conf_ref->{'urly0'} . ' to '
                        . $urly0 );
                $conf_ref->{'urly0'} = $urly0;
            }
        }
    }
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
        croak error( "$method $url was failed: " . $response->status_line() );
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

##@method void getCitydioAndTownzz($user)
#@brief Performs an HTTP request to retrieve the custom code
#       corresponding to zip code.
#@param object $user An 'Cocoweb::User::Connected' object
sub getCitydioAndTownzz {
    my ( $self, $user ) = @_;
    my $cityco;

    #Reads citydio and townzz values from an HTTP request.
    my $isUseConf;
    if ( $self->isConfHTTPrequests() ) {
        eval { $cityco = $self->getCityco( $user->zip() ); };
        $isUseConf = 1 if $@;
    }
    else {
        $isUseConf = 1;
    }
    if ($isUseConf) {

        #If the HTTP request fails, read the values from configuration file.
        my $allZipCodes = Cocoweb::Config->instance()
            ->getConfigFile( 'zip-codes.txt', 'ZipCodes' );
        $cityco = $allZipCodes->getCityco( $user->zip() );
    }

    #debug("cityco: $cityco");
    my @citycoList = split( /\*/, $cityco );
    my ( $citydio, $townzz );
    my $count = scalar @citycoList;
    die error("Error: The cityco is not valid (cityco: $cityco)")
        if $count % 2 != 0
        or $count == 0;

    if ( $count == 2 ) {
        $citydio = sprintf( "%05d", $citycoList[0] );
        $townzz = $citycoList[1];
    }
    else {
        my $r = int( rand( $count / 2 ) );
        $r += $r;
        $citydio = $citycoList[$r];
        $townzz  = $citycoList[ $r + 1 ];
    }

    #debug("citydio: $citydio; townzz: $townzz");
    $user->citydio($citydio);
    $user->townzz($townzz);
}

##@method string requestCityco($zip)
#@brief Performs an HTTP request to retrieve the zip custom code
#       and town corresponding to zip code.
#@param integer $zip A zip code (i.e. 75001)
#@return string cityco and town (i.e. '30915*PARIS*')
sub getCityco {
    my ( $self, $zip ) = @_;
    croak error("Error: The '$zip' zip code is invalid!")
        if $zip !~ /^\d{5}$/;
    my $i = index( $zip, '0' );
    if ( $i == 0 ) {
        $zip = substr( $zip, 1, 5 );
    }
    my $url      = $conf_ref->{'urlcocoland'} . $zip . '.js';
    my $response = $self->execute( 'GET', $url );
    my $res      = $response->content();

    #debug($res);

    # Retrieves a string like "var cityco='30926*PARIS*';"
    if ( $res !~ m{var\ cityco='([^']+)';}xms ) {
        die error('Error: cityco have not been found!'
                . 'The HTTP requests "'
                . $url
                . '" return: '
                . $res );
    }
    my $cityco = $1;

    #debug("===> cityco: $cityco");
    return $cityco;
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
            . $user->mypass() . '?'
            . rand(1) * 10000000 );
}

##@method object agir($user, $txt1)
#@brief Initiates a standard request to the server
#@param object $user An 'Cocoweb::User::Connected' object
#@param string $txt1 The parameter of the HTTP request
#@param object A possible Cocoweb::Response object
#@return object Cocoweb::Response
sub agir {
    my ( $self, $user, $txt3, $response ) = @_;
    my $code = substr( $txt3, 0, 2 );
    if ( $code != 10 and $code != 89 and $code != 48 and $code != 83 ) {

        #info($txt3);
    }

    return $self->agix(
        $user,
        $self->url1()
            . substr( $txt3, 0, 2 )
            . $user->mynickID()
            . $user->monpass()
            . substr( $txt3, 2 ),
        undef,
        $response
    );
}

##@method object agix($user, $url, $cookie_ref)
#@brief Performs an HTTP Requests to invoke a remote method
#@param object $user An 'Cocoweb::User::Connected' object
#@param string An URL for the HTTP request
#@param hashref $cookie_ref A hash that contains possible cookies.
#@param object A possible Cocoweb::Response object
#@return object Cocoweb::Response
sub agix {
    my ( $self, $user, $url, $cookie_ref, $response ) = @_;
    croak error("The URL of the HTTP request is missing") if !defined $url;

    #info("url: $url");
    my $HTTPResponse = $self->execute( 'GET', $url, $cookie_ref );
    my $res = $HTTPResponse->content();

    #debug($res);
    die error(
        'Error: the JavaScript function not found in the string: ' . $res )
        if $res !~ m{^([^\(]+)\('([^']*)'\)}xms;
    my $function = $1;
    my $arg      = $2;
    die error( 'The method called "' . $function . '()" is unknown!' )
        if $function ne 'process1';
    $response = Cocoweb::Response->new() if !defined $response;
    my $beenDisconnected = $response->beenDisconnected();
    $self->beenDisconnected($beenDisconnected) if $beenDisconnected;
    $response->$function( $self, $user, $arg );
    return $response;
}

##@method obkect searchnow($user)
#@brief Call the remote method to retrieve the list of pseudonyms.
#@param object $user An 'User::Connected' object
#@param object A possible Cocoweb::Response object
sub searchnow {
    my ( $self, $user ) = @_;
    return $self->agir( $user, '10' . $self->genru() . $self->yearu() );
}

##@method object guw($user, $adz, $response)
#@param object $user An 'User::Connected' object
#@param string Authentication string (i.g. "iGRQh3J1jcBfhHJui3teGhIrID0=")
#@param object A possible Cocoweb::Response object
#@return object Cocoweb::Response
sub guw {
    my ( $self, $user, $adz, $response ) = @_;
    $response = $self->agir( $user, '52' . $adz, $response );
    $user->mystat($adz);
    return $response;
}

##@method void cherchasalon($user)
#@param object $user An 'User::Connected' object
sub cherchasalon {
    my ( $self, $user ) = @_;
    return $self->agir( $user, '89' );
}

##@method void actuam($user)
#@brief Get the list of contacts, nicknamed 'amiz'
#@param object $user An 'User::Connected' object
#@return string
sub actuam {
    my ( $self, $user ) = @_;
    return $self->agir( $user, '48' );
}

##@method void requestMessagesFromUsers($user)
#@brief Returns the messages sent by other users
sub requestMessagesFromUsers {
    my ( $self, $user ) = @_;
    my $timz1 = $self->timz1();
    if ( $timz1 % 4 != 0 ) {
        $self->agir( $user,
            $user->camon() . $user->typcam() . '?' . rand(1) );
    }

    #else {
    #    debug("<<<<< timz1 == $timz1  >>>>>");
    #}
    if ( $timz1 == 20 and length( $user->mypass() ) != 20 ) {

        #This is a new user without password.
        #Request a password for this user.
        $self->agir( $user, '29' );
    }
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
#@return object A 'CocoWeb::Response' object
sub writus {
    my ( $self, $user, $userWanted, $s1 ) = @_;
    return if !defined $s1 or length($s1) == 0;
    my $s2 = '';
    $s2 = $self->convert()->writo($s1);
    my $response = $self->agir( $user,
        '99' . $userWanted->mynickID() . $user->roulix() . $s2 );
    my $roulix = $user->roulix();

    if ( ++$roulix > 8 ) {
        $roulix = 0;
    }
    $user->roulix($roulix);
    return $response;
}

##@method void amigo($user, $userWanted)
#@brief Requests to be added to the friends list.
#@param object $user An 'User::Connected' object
#@param object $userWanted A 'CocoWeb::User::Wanted' object
sub amigo {
    my ( $self, $user, $userWanted ) = @_;
    return $self->agir( $user, '46' . $userWanted->mynickID() );
}

##@method void reportAbuse($user, $userWanted)
#@brief report a user for abusive behavior.
#@param object $user An 'User::Connected' object
#@param object $userWanted A 'CocoWeb::User::Wanted' object
sub reportAbuse {
    my ( $self, $user, $userWanted ) = @_;
    $self->agir( $user, '69' . $userWanted->mynickID() );
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
    if ( !$user->isPremiumSubscription() ) {
        warning(  'The command "infuz" is reserved for users with a'
                . ' Premium subscription.' );
        return;
    }
    my $count           = 0;
    my $infuzMaxOfTries = $self->infuzMaxOfTries();
    while ( $infuzMaxOfTries > 0 ) {
        $infuzMaxOfTries--;
        $count++;
        $self->isInfuzNotToFast(0);
        debug( "try $count: infuz request for " . $userWanted->mynickname() );
        my $response
            = $self->agir( $user, '83555' . $userWanted->mynickID() );
        my $infuzString = $response->infuzString();
        if ( $infuzString eq "\nINTERDIT\n" ) {
            warning(
                'It is forbidden to request this information from the user '
                    . $userWanted->mynickname() );
            $infuzMaxOfTries = 0;
            next;
        }
        my $regex = $self->infuzNotToFastRegex();
        if ( $infuzString =~ $regex ) {
            $self->isInfuzNotToFast(1);
            warning("infuz: not too fast!");
            next;
        }
        eval { $userWanted->setInfuz($infuzString); };
        $infuzMaxOfTries = 0;
    }
    debug(    "NUMBER ATTEMPTED INFUZ REQUESTS: $count. "
            . $userWanted->mynickname() . ' '
            . $userWanted->mynickID() );
    return $userWanted;
}

##@methode object getUsersList($user)
#@bref Request and returns the list of connected users
#@param object $user An 'User::Connected' object
#@return object A 'Cocoweb::User::List' object
sub getUsersList {
    my ( $self, $user ) = @_;

    # Reset at zero 'isNew', 'isView', 'hasChange' and
    # 'updateDbRecord' data members of each user
    $self->usersList()->clearFlags();

    #1 = search mans; 2 = search womans
    foreach my $g ( 1, 2 ) {
        $self->genru($g);

        # 1 = -30 years old; 2 = 20 to 40  years old; 3 = 30 to 50 years old;
        # 4 = 40  years old  and more
        foreach my $y ( 1, 2, 3, 4 ) {
            $self->yearu($y);
            $self->searchnow($user);
        }
    }
    return $self->usersList();
}

##@method void requestDisconnectedUsers($user)
#@brief Checks if the not viewed users are offline
#@param object $user An 'User::Connected' object
sub checkIfUsersNotSeenAreOffline {
    my ( $self, $user ) = @_;
    my $users_ref = $self->usersList()->getUsersNotViewed();
    $self->isDead( $user, $users_ref );
}

##@method object searchNickname($user, $userWanted)
#@brief Search a nickname connected
#@param object $user       An 'User::Connected' object
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
            $userWanted
                = $self->usersList()->checkIfNicknameExists($nickname);
            return $userWanted if defined $userWanted;
        }
    }
    return $self->usersList()
        if !defined $nickname
        or length($nickname) == 0;
    return;
}

1;

