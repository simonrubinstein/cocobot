# @created 2012-02-17
# @date 2012-02-20
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
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use LWP::UserAgent;
use utf8;
no utf8;

__PACKAGE__->attributes( 'myport', 'url1' );

my $conf_ref;
my $agent_ref;
my $userAgent;
my %dememeMatch = ();

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    if ( !defined $conf_ref ) {
        my $conf = Cocoweb::Config->instance()->getConfigFile('request.conf');
        $conf_ref = $conf->all();
        foreach my $name (
            'urly0',  'urlprinc', 'current-url', 'avatar-url',
            'avaref', 'urlcocoland'
          )
        {
            $conf->isString($name);

            #debug("$name $conf_ref->{$name}");
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
        $self->initializeTables();
    }

    my $myport = 3000 + randum(1000);

    $self->attributes_defaults(
        'myport' => $myport,
        'url1'   => $conf_ref->{'urly0'} . ':' . $myport . '/'
    );
    debug( "url1: " . $self->url1() );

}

##@method string getValue($name)
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
sub execute {
    my ( $self, $method, $url, $cookie_ref ) = @_;
    my $req = HTTP::Request->new( $method => $url );
    debug( 'HttpRequest() ' . $url );
    foreach my $field ( keys %{ $agent_ref->{'header'} } ) {
        $req->header( $field => $agent_ref->{'header'}->{$field} );
    }
    if ( defined $cookie_ref and scalar %$cookie_ref > 0 ) {
        my $cookieStr = '';
        foreach my $k ( keys %$cookie_ref ) {
            my $val = $self->jsEscape( $cookie_ref->{$k} );
            $cookieStr .= $k . "=" . $val . ';';
        }
        chop($cookieStr);
        $req->header( 'Cookie' => $cookieStr );
    }
    my $response = $userAgent->request($req);
    if ( !$response->is_success() ) {
        die error( $response->status_line() );
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

## @method void getCityco($user_ref)
sub getCityco {
    my ( $self, $user ) = @_;

    my $zip = $user->zip();
    croak error("Error: The '$zip' zip code is invalid!") if $zip !~ /^\d{5}$/;
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
    debug("cityco: $cityco");
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
    debug("citydio: $citydio; townzz: $townzz");
    $user->citydio($citydio);
    $user->townzz($townzz);
}

## @method void searchnow($user, $genru, $yearu)
sub searchnow {
    my ($self, $user, $genru, $yearu) = @_;
    debug("genru: $genru; yearu: $yearu");
    my $searchito =
      '10' . $user->nickID() . $user->password() . $genru . $yearu;
    $self->agir( $user, $searchito );
}

##@method void agir($user, $txt1)
#@param $user
#@param $txt1
sub agir {
    my ( $self, $user, $txt1 ) = @_;
    my $url = $self->url1() . $txt1;
    info("agir() url = $url");
    my $response = $self->execute( 'GET', $url );
    my $res = $response->content();
    debug($res);
    die error("Error: $res: function not found")
      if $res !~ m{^([^\(]+)\('([^']*)'\)}xms;
    my $function = $1;
    my $arg      = $2;

    #info('function: '. $function . '; arg: ' . $arg);
    my $process;
    eval( '$process = \&' . $function );
    if ($@) {
        die sayError($@);
    }
    $self->$process( $user, $arg );
}

## @method void process1()
# @brief object $user An user objet
# @brief string $urlu
sub process1 {
    my ( $self, $user, $urlu ) = @_;
    my ($todo) = ('');

    #debug("process1($urlu)");
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
        process1Int( $user, $urlo );
    }
    else {
        info("process1() $molki code unknown");
    }
}

## @method void process1Int($user_ref, $urlo)
sub process1Int {
    my ( $self, $user, $urlo ) = @_;
    print STDOUT "OK\n";
    my $olko = parseInt( substr( $urlo, 0, 2 ) );
    info("olko: $olko");
    if ( $olko == 12 ) {
        my $lebonnick = parseInt( substr( $urlo, 2, 8 - 2 ) );
        $user->nickId( '' . $lebonnick);
        $user->password(substr( $urlo, 8, 14 - 8 ));
        $user->{'mycrypt'}  = parseInt( substr( $urlo, 14, 21 - 14 ) );
        debug( 'mynickID: '
              . $user->nickId()
              . '; monpass: '
              . $user->password()
              . '; mycrypt: '
              . $user->mycrypt() );

        $olko = 51;

    }

    if ( $olko == 51 ) {
         $self->agir( $user,
                '51'
              . $user->nickId()
              . $user->password()
              . $self->writo( $agent_ref->{'agent'} ) );
    }

    if ( $olko == 99 ) {
        my $bud = parseInt( substr( $urlo, 2, 3 ) );
        sayInfo("bud: $bud");

        #
        if ( $bud == 556 ) {
        }

        #searchnow($user_ref);
    }

    #A search command was sent
    if ( $olko == 34 ) {
        populate( $urlo, 0 );
    }

    # No more private conversation is accepted
    if ( $olko == 98 ) {
        sayInfo("No more private conversation is accepted.");
        $olko = 967;
    }

    # No more male user message is accepted
    if ( $olko == 96 ) {
        sayInfo("No more male user message is accepted.");
        $olko = 967;
    }

    #A message has been sent to the chat.
    if ( $olko == 97 ) {
        $olko = 967;
    }
    if ( $olko == 66 ) {
        $olko = 967;
    }
    if ( $olko == 967 ) {
    }

}



## @method string writo($s1)
# @param string $s1
# @return string
sub writo {
    my ($self, $s1) = @_;
    utf8::decode($s1);
    my $s2     = '';
    my $toulon = 0;
    for ( my $i = 0 ; $i < length($s1) ; $i++ ) {
        my $c = substr( $s1, $i, 1 );
        my $numerox = ord($c);
        if ( $numerox != 32 ) {
            $toulon++;
        }
        else {
            $toulon = 0;
        }
        if ( $toulon < 24 ) {
            if (   $numerox < 43
                or ( $numerox > 59 and $numerox < 64 )
                or ( $numerox > 90 and $numerox < 96 )
                or $numerox > 122 )
            {
                $s2 .= dememe($numerox);
            }
            else {
                $s2 .= $c;
            }
        }
    }
    return $s2;
}

## @method string dememe($numix)
# @param integer $numix
# @return string
sub dememe {
    my ($self, $numix) = @_;
    return '' if !exists $dememeMatch{$numix};
    return $dememeMatch{$numix};
}


## @method void initializeTables()
sub initializeTables {
    my ($self) = @_;
    %dememeMatch = (
        32   => "~",
        33   => '!',
        36   => "*7",
        37   => "%",
        39   => "*8",
        40   => "(",
        41   => ")",
        42   => "*s",
        61   => "=",
        63   => "?",
        94   => "*l",
        95   => "*0",
        8364 => "*d",
        224  => "*a",    # à
        226  => "*k",    # â
        231  => "*c",    # ç
        232  => "*e",    # è
        233  => "*r",    # é
        234  => "*b",    # ê
        238  => "*i",    # î
        239  => "*k",    # ï
        244  => "*o",    # ô
        249  => "*f",    # ù
        251  => "*u"     # û
    );
}




1;

