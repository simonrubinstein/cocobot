# @created 2012-02-17
# @date 2012-03-21
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
use Cocoweb::User::HashList;
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use Encode qw(encode FB_PERLQQ);
use LWP::UserAgent;
use Time::HiRes qw(usleep nanosleep);
use utf8;
no utf8;

__PACKAGE__->attributes(
    'myport',
    'url1',
    ## 0 = all; 1 = mens;  womens: 2
    'genru',
    ## 0 = all; 1 = -30 / 2 = 20 to 40 / 3 = 30 to 50 / 4 = 40 and more
    'yearu',
    'usersList',
    'speco',
    'convert'
);

my $conf_ref;
my $agent_ref;
my $userAgent;

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
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
        'myport'    => $myport,
        'url1'      => $conf_ref->{'urly0'} . ':' . $myport . '/',
        'genru'     => 0,
        'yearu'     => 0,
        'usersList' => Cocoweb::User::HashList->new(),
        'speco'     => 0,
        'convert'   => Cocoweb::Encode->instance()
    );

    #debug( "url1: " . $self->url1() );
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

##@method void checkNickId($nickId)
#@brief Checks if the nickname ID value is correct
#@param integer $nickId The nickname ID which information is requested
sub checkNickId {
    my ( $self, $nickId ) = @_;
    croak error("The $nickId nickname ID is wrong")
      if !defined $nickId
          or $nickId !~ m{^\d+$};

    croak error("The $nickId nickname ID is wrong")
      if !defined $nickId
          or $nickId !~ m{^\d+$};
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
        info($txt3);
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

    #info( 'function: ' . $function . '; arg: ' . $arg );
    my $process;
    eval( '$process = \&' . $function );
    if ($@) {
        die sayError($@);
    }
    $self->$process( $user, $arg );
}

##@method void process1($user, $urlu)
#@brief Method called back after an HTTP request to the server
#@param object $user An 'Cocoweb::User::Connected' object
#@param string $urlu String returned by the server
sub process1 {
    my ( $self, $user, $urlu ) = @_;
    my ($todo) = ('');

    #info($urlu);

    debug("urlu: $urlu");
    my $urlo = $urlu;
    my $hzy = index( $urlo, '#' );
    $urlo = substr( $urlo, $hzy + 1, length($urlo) - $hzy - 1 );

    my $urlw = index( $urlo, '|' );
    if ( $urlw > 0 ) {
        $todo = '#' . substr( $urlo, $urlw + 1, length($urlo) - $urlw - 1 );
    }

    my $firstChar = substr( $urlo, 0, 1 );
    my $molki = ord($firstChar);

    debug("firstChar: $firstChar; molki = $molki");

    #
    if ( $molki < 58 ) {
        $self->process1Int( $user, $urlo );
    }
    else {
        info("process1() $molki code unknown");
    }
}

## @method void process1Int($user, $urlo)
#@param object $user An 'User::Connected' object object
sub process1Int {
    my ( $self, $user, $urlo ) = @_;

    #debug("urlo: $urlo");
    my $olko = parseInt( substr( $urlo, 0, 2 ) );

    #debug("olko: $olko");
    if ( $olko != 12 and $olko != 34 and $olko != 89 and $olko != 48 ) {
        info("olko: $olko / urlo = $urlo");
    }

    # The first part of authentication was performed successfully
    # The server returns an ID and a password for the current session
    if ( $olko == 12 ) {
        my $lebonnick = parseInt( substr( $urlo, 2, 6 ) );
        $user->mynickID( '' . $lebonnick );
        $user->monpass( substr( $urlo, 8, 6 ) );
        $user->mycrypt( parseInt( substr( $urlo, 14, 21 - 14 ) ) );
        info(   'mynickID: '
              . $user->mynickID()
              . '; monpass: '
              . $user->monpass()
              . '; mycrypt: '
              . $user->mycrypt() );
        $olko = 51;
    }

    if ( $olko == 51 ) {

        #setTimeout("agir('51'+agento)",500);
        usleep( 1000 * 500 );
        $self->agir( $user,
            '51' . $self->convert()->writo( $agent_ref->{'agent'} ) );
    }

    if ( $olko == 99 ) {
        my $bud = parseInt( substr( $urlo, 2, 3 ) );
        debug("bud: $bud");

        if ( $bud == 444 ) {
            my $urlu =
              $self->convert()->transformix( substr( $urlo, 5 ), -1, 0 );
            return $urlu;
        }

        if ( $bud == 447 or $bud == 445 ) {
            die error( substr( $urlo, 5 ) );
        }

        # Retrieves information about an user, for Premium subscribers only
        if ( $bud == 555 ) {
            my $urlu =
              $self->convert()->transformix( substr( $urlo, 5 ), -1, 0 );
            return $urlu;
        }

        #/#9955720289399221011fifilou

        #Result of a search query of a nickname code
        if ( $bud == 557 ) {
            my $userFoud = new Cocoweb::User(
                'mynickname' => substr( $urlo, 19 ),
                'myage'      => substr( $urlo, 11, 2 ),
                'citydio'    => substr( $urlo, 13, 5 ),
                'mysex'      => substr( $urlo, 18, 1 ),
                'mynickID'   => substr( $urlo, 5, 6 ),
                'myver'  => 0,
                'mystat' => 5,
                'myXP'   => 0
            );
            return $userFoud;
        }

        # The second part of the authentication is completed successfully
        # The server returns some information about the user account.
        if ( $bud == 556 ) {

  #agix(urlav+myage+mysex+parami[3]+myavatar+mynickID+monpass+mycrypt,4)
  #agix(url1+"40"+mynickname+"*"+myage+mysex+parami[3]+myavatar+speco+mypass,4);
  #$self->agix( $user,
  #          $conf_ref->{'urlav'}
  #        . $user->myage()
  #        . $user->mysex()
  #        . $user->citydio()
  #        . $user->myavatar()
  #        . $user->mynickID()
  #        . $user->monpass()
  #        . $user->mycrypt() );
            $user->mystat( parseInt( substr( $urlo, 6, 1 ) ) );
            $user->myXP( parseInt( substr( $urlo, 5, 1 ) ) );
            $user->myver( parseInt( substr( $urlo, 7, 1 ) ) );
            info(   'mystat: '
                  . $user->mystat()
                  . '; myXP:'
                  . $user->myXP()
                  . '; myver: '
                  . $user->myver() );

        }
    }

    if ( $olko == 92 ) {
        warning("olko: $olko not implemented");
    }
    if ( $olko == 37 ) {
        info('Successful authentication. Good chat.');
        $user->myver(1);
    }
    if ( $olko == 35 ) {
        warning("olko: $olko not implemented");
    }
    if ( $olko == 29 ) {
        if ( length( $user->mypass() ) != 20 ) {
            warning("olko: $olko not implemented");
        }
    }
    if ( $olko == 39 ) {
        warning("olko: $olko not implemented");
    }
    if ( $olko == 95 ) {
        warning("olko: $olko not implemented");
    }
    if ( $olko == 19 ) {
        warning("olko: $olko not implemented");
    }
    if ( $olko == 24 ) {
        warning("olko: $olko not implemented");
    }

    #A user or users have disconnected the chat.
    if ( $olko == 90 ) {
        my $yyg = ( length($urlo) - 2 ) / 7;
        print "**** $yyg\n";
        if ( $yyg > 0 ) {
            for ( my $i = 0 ; $i < $yyg ; $i++ ) {
            }
        }

    }

    # Retrieves the list of pseudonyms
    if ( $olko == 34 ) {
        $self->populate( $user, $self->usersList(), $urlo );
    }
    elsif ( $olko == 13 ) {
        die error("You have been disconnected. Log back on Coco.fr");
    }
    elsif ( $olko == 10 ) {
        die error( 'You are disconnected because someone with the'
              . ' same IP is already connected to the chat server.'
              . ' Otherwise try to connect in 30 seconds.' );
    }
    elsif ( $olko == 36 ) {
        if ( $user->mystat() < 6 ) {
            $user->mystat( parseInt( substr( $user, 2 ) ) % 10 );
        }
    }

    if ( $olko == 87 ) {
        $olko = 89;
    }

    if ( $olko == 23 ) {

        #$self->yabon();
    }

    # Retrieves the list of rooms
    if ( $olko == 89 ) {
    }

    if ( $olko == 39 ) {
        my $infor = substr( $urlo, 2 );
        die error("cookie bug. infor: $infor ($urlo)");
    }

    # No more private conversation is accepted
    if ( $olko == 98 ) {
        info("No more private conversation is accepted.");
        $olko = 967;
    }

    # No more male user message is accepted
    if ( $olko == 96 ) {
        info("No more male user message is accepted.");
        $olko = 967;
    }

    #A message has been sent to the chat.
    if ( $olko == 97 ) {
        $olko = 967;
    }
    if ( $olko == 66 ) {
        $olko = 967;
    }
    if ( $olko == 48 ) {
        $user->amiz( Cocoweb::User::Friend->new() );
        $self->populate( $user, $user->amiz(), $urlo );
        return $user->amiz();
    }

    # Another user is writing a message
    # A message was received from another user
    # The message that this user has sent has been received or not ???
    if ( $olko == 967 ) {
        my $hzq = 3;
        my $klk = parseInt( substr( $urlo, 2, 1 ) );
        if ( $klk < 9 ) {
        }
        my $lengus = length($urlo);
        if ( $lengus > 8 ) {
            my ( $kopo, $gooi, $coom ) = ( 0, 1, 0 );
            while ( $kopo == 0 ) {
                my $diase = indexOf( $urlo, '#', $hzq ) + 1;
                if ( ( $diase - $hzq ) < 9 ) {
                    if ( $diase < 3 ) {
                        $kopo = 1;
                        my $idgars = parseInt( substr( $urlo, $hzq, 6 ) );
                        warning("The user $idgars is disconnected");
                    }
                    else {
                        my $zami = parseInt( substr( $urlo, $hzq, 6 ) );
                        if ( ( $diase - $hzq ) == 7 ) {
                            message("The user $zami writing");
                        }
                    }
                }
                else {
                    my $toilo = indexOf( $urlo, '#', $hzq );
                    my $mokage = parseInt( substr( $urlo, $hzq,     2 ) );
                    my $moksex = parseInt( substr( $urlo, 2 + $hzq, 3 ) );
                    my $mokville = parseInt( substr( $urlo, 3 + $hzq, 8 ), 10 );
                    my $moknickID = parseInt( substr( $urlo, 8 + $hzq,  14 ) );
                    my $statq     = parseInt( substr( $urlo, 15 + $hzq, 16 ) );
                    my $okb       = parseInt( substr( $urlo, 16 + $hzq, 17 ) );
                    my $mokpseudo = substring( $urlo, 17 + $hzq, $toilo );
                    $diase = indexOf( $urlo, '#', $toilo + 1 ) + 1;
                    my $mokmess = substring( $urlo, $toilo + 1, $diase - 1 );
                    message( "$mokpseudo: " . $mokmess );
                }
                $hzq = $diase;
                $kopo = 1 if $hzq > $lengus - 3;
            }

        }
        else {
            if ( $lengus == 5 ) {
                if ( index( $urlo, '111' ) > -1 ) {
                    die error( 'The servers are being restarted.'
                          . ' Log back in a moment' );
                }
            }
        }

    }

}

##@method void populate($user, $populateList, $urlo, $offsat)
#@brief Extract the pseudonyms of the string returned by the server
#       and call the method passed as parameter
#@param object $user         An 'User::Connected' object object
#@param object $usersList    An user list object
#@param string $urlo         The string returned by the server
sub populate {
    my ( $self, $user, $usersList, $urlo ) = @_;
    if ( length($urlo) > 12 ) {
        my ( $indux, $mopo, $hzy ) = ( 0, 0, 2 );
        while ( $mopo < 1 ) {
            $indux = index( $urlo, '#', $hzy );
            if ( $indux < 2 ) {
                $mopo = 2;
            }
            else {

                $usersList->populate(

                    #'myage'
                    parseInt( substr( $urlo, $hzy, 2 ) ),

                    #'mysex'
                    parseInt( substr( $urlo, 2 + $hzy, 1 ) ),

                    #'citydio'
                    parseInt( substr( $urlo, 3 + $hzy, 5 ), 10 ),

                    #'mynickID'
                    parseInt( substr( $urlo, 8 + $hzy, 6 ) ),

                    #'mynickname'
                    substr( $urlo, 17 + $hzy, $indux - 17 - $hzy ),

                    #'myXP'
                    parseInt( substr( $urlo, 14 + $hzy, 1 ) ),

                    #'myStat'
                    parseInt( substr( $urlo, 15 + $hzy, 1 ) ),

                    #'myver'
                    parseInt( substr( $urlo, 16 + $hzy, 1 ) )
                );
                $hzy = $indux + 1;
            }
        }
    }
}

##@method void searchnow($user)
#@brief Call the remote method to retrieve the list of pseudonyms.
#@param object $user An 'User::Connected' object object
sub searchnow {
    my ( $self, $user ) = @_;
    $self->agir( $user, '10' . $self->genru() . $self->yearu() );
}

##@method void cherchasalon($user)
#@param object $user An 'User::Connected' object object
sub cherchasalon {
    my ( $self, $user ) = @_;
    $self->agir( $user, '89' );
}

##@method void actuam($user)
#@brief Get the list of contacts, nicknamed 'amiz'
#@param object $user An 'User::Connected' object object
#@return string
sub actuam {
    my ( $self, $user ) = @_;
    $self->agir( $user, '48' );
}

##@method void lancetimer($user)
#@brief Method that periodically performs requests to the server
#@param object $user An 'User::Connected' object object
sub lancetimer {
    my ( $self, $user ) = @_;
    $self->agir( $user, $user->camon() . $user->typcam() );
}

##@method void getUserInfo()
#@brief Get the number of days remaining until the end of
#       the Premium subscription.
#       This method works only for user with a Premium subscription
#@param object $user An 'User::Connected' object object
sub getUserInfo {
    my ( $self, $user ) = @_;
    $self->agir( $user, '77369' );
}

##@method void searchCode()
#@brief Search a nickname from his code of 3 characters
#       This method works only for user with a Premium subscription
#@param object $user An 'User::Connected' object object
#@param string $code A nickname code (i.e. WcL)
sub searchCode {
    my ( $self, $user, $code ) = @_;
    $self->agir( $user, '83733000000' . $code );
}

sub isDead {
    my ( $self, $user, $nickIds ) = @_;
    $self->agir( $user, '90' . $nickIds );
}

## @method void writus($user, $s1, $nickId)
#@brief
#@param object $user An 'User::Connected' object object
#@param string $s1
sub writus {
    my ( $self, $user, $s1, $nickId ) = @_;
    $self->checkNickId($nickId);
    return if !defined $s1 or length($s1) == 0;
    my $s2 = '';
    $s2 = $self->convert()->writo($s1);
    my $sendito = '99' . $nickId . $user->roulix() . $s2;
    $self->agir( $user, '99' . $nickId . $user->roulix() . $s2 );
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
#@param object $user       An 'User::Connected' object object
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
#@brief Request and returns the list of connected users
#@param object $user An 'User::Connected' object object
#@return object A 'User::HashList' object
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

##@method object searchNickname($user, $userWanted)
#@brief Search a nickname connected
#@param object $user      An 'User::Connected' object object
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

