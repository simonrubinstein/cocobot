#!/usr/bin/perl
# @author
# @created 2010-07-31
# @date 2010-09-19
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010
# $Id$
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

use strict;
use Data::Dumper;
use Encode qw(encode FB_PERLQQ);
use FindBin qw($Script $Bin);
use Config::General;
use Getopt::Std;
use LWP::UserAgent;
use POSIX;

#use Encode qw( from_to is_utf8 );
use utf8;
no utf8;
use vars qw($VERSION);
$VERSION                            = '0.1.2';
$Getopt::Std::STANDARD_HELP_VERSION = 1;
my $isVerbose    = 0;
my $isDebug      = 0;
my $isTest       = 0;
my $agent_ref    = {};
my $coco_ref     = {};
my %user         = ();
my $boyname_ref  = [];
my $girlname_ref = [];
my $zipCode_ref  = [];
## 0 = all; 1 = mens;  womens: 2
my $genru = 0;
## 1 = -30 / 2 = 20 to 40 / 3 = 30 to 50 / 4 = 40 and more
my $yearu = 0;
my $action;
my %actions = (
    'idiot'  => \&actionIdiot,
    'pb'     => \&actionPb,
    'search' => \&actionSearch,
    'list'   => \&actionList,
    'write'  => \&actionWrite,
    'hello'  => \&actionHello,
    'alert'  => \&actionAlert,
    'login'  => \&actionLogin
);

my $ua;
my %userFound = ();
my $loginName;
my %dememeMatch = ();
my $searchUser;
my $searchId;
my $sex;
my $maxOfUsers = 1;
my %sentences  = ();
my $maxOfLoop  = 1;
my $maxOfWrite = 1;
my $message;
my $inputZipCode;
my $currentYear;

init();

#print writo("123é5à7") . "\n"; exit;
run();

## @method void run()
sub run {
    sayDebug("Run '$action' action");
    my $subAction = $actions{$action};
    $subAction->();
}

## @method void actionPb()
sub actionPb {
    for ( my $i = 0 ; $i < 3 ; $i++ ) {
        postSentences( $sentences{'pb'} );
        sleep 60;
    }
}

## @method void actionIdiot()
sub actionIdiot {
    postSentences( $sentences{'idiot'} );
}

## @method void postSentences()
sub postSentences {
    my ($sentences_ref) = @_;

    for ( my $i = 0 ; $i < $maxOfUsers ; $i++ ) {
        my $sentence = $sentences_ref->[ randum( scalar @$sentences_ref ) ];
        print "$sentence \n";
    }

    if ( !defined $searchUser and !defined $searchId ) {
        sayError("You must specify either a username or ID");
    }
    my @users;
    for ( my $i = 0 ; $i < $maxOfUsers ; $i++ ) {
        $users[$i] = getRandomLogin($sex);
    }
    for ( my $i = 0 ; $i < $maxOfUsers ; $i++ ) {
        process( $users[$i] );
    }
    my $login_ref;
    if ( !defined $searchId ) {
        $login_ref = searchLogin( $users[0], $searchUser );
        if ( !defined $login_ref ) {
            die sayError("$searchUser user was not found");
        }
        print Dumper $login_ref;
        $searchId = $login_ref->{'id'};
    }

    for ( my $i = 0 ; $i < $maxOfUsers ; $i++ ) {
        my $sentence = $sentences_ref->[ randum( scalar @$sentences_ref ) ];
        writus( $users[$i], $sentence, $searchId );

        #sleep 2;
    }
}

## @method void actionWrite
sub actionWrite {
    if ( !defined $searchUser and !defined $searchId ) {
        die sayError("You must specify a username (-u option)");
    }
    for ( my $i = 0 ; $i < $maxOfLoop ; $i++ ) {
        my $user_ref = getRandomLogin($sex);
        process($user_ref);
        if ( !defined $searchId ) {
            my $login_ref = searchLogin( $user_ref, $searchUser );
            if ( !defined $login_ref ) {
                die sayError("$searchUser user was not found");
            }
            $searchId = $login_ref->{'id'};
        }
        for ( my $i = 0 ; $i < $maxOfWrite ; $i++ ) {
            writus( $user_ref, $message, $searchId );
        }
        sleep 15;
    }
}

sub actionLogin {
    for ( my $i = 0 ; $i < $maxOfLoop ; $i++ ) {
        my $user_ref = getRandomLogin($sex);
    }
}

## @method void actionHello()
# @brief Send a random greeting in loop to a nickname
sub actionHello {
    my $sentences_ref = $sentences{'hi'};
    if ( !defined $searchUser and !defined $searchId ) {
        die sayError("You must specify a username (-u option)");
    }
    my $username = '';
    for ( my $i = 0 ; $i < $maxOfLoop ; $i++ ) {
        my $user_ref = getRandomLogin($sex);
        process($user_ref);
        if ( !defined $searchId ) {
            my $login_ref = searchLogin( $user_ref, $searchUser );
            if ( !defined $login_ref ) {
                die sayError("$searchUser user was not found");
            }
            $searchId = $login_ref->{'id'};
            if ( defined $loginName ) {
                $username = $loginName;
            }
            else {
                $username = $login_ref->{'login'};
            }
            $username =~ s{[^a-zA-Z]+.*$}{};
        }
        my $sentence = $sentences_ref->[ randum( scalar @$sentences_ref ) ];
        my @phrases = split( /\*n\*r/, $sentence );
        for ( my $i = 0 ; $i < $maxOfWrite ; $i++ ) {
            my $r = randum(10);
            my $user;
            if ( $r < 4 ) {
                $user = $username;
                $r    = randum(10);
                if ( $r < 3 ) {
                    $user = ucfirst($user);
                }
                elsif ( $r >= 3 and $r < 8 ) {
                    $user = lc($user);
                }
                else {
                    $user = uc($user);
                }
            }
            else {
                $user = '';
            }
            foreach my $phrase (@phrases) {
                $phrase =~ s{\[% LOGIN %\]}{$user}g;
                writus( $user_ref, $phrase, $searchId );
            }
        }
        next if $isTest;
        sleep 17 if $i < $maxOfLoop - 1;
    }
}

## @method void actionAlert()
sub actionAlert {
    my $user_ref = getRandomLogin(2);
    process($user_ref);
    my $login_ref = searchLogin( $user_ref, '' );
    foreach my $id ( keys %userFound ) {
        my $login_ref = $userFound{$id};
        if ( defined $sex ) {
            if ( $sex == 1 ) {
                next if $login_ref->{'sex'} != 1 and $login_ref->{'sex'} != 6;
            }
            elsif ( $sex == 2 ) {
                next if $login_ref->{'sex'} != 2 and $login_ref->{'sex'} != 7;
            }
            else {
                next;
            }
        }
        writus( $user_ref, $message, $id );
    }
}

## @method void actionSearch()
sub actionSearch {
    if ( !defined $searchUser and !defined $searchUser ) {
        die sayError("You must specify a username (-u option)");
    }
    my $user_ref = getRandomLogin();
    process($user_ref);

    #print Dumper $user_ref;
    my $login_ref = searchLogin( $user_ref, $searchUser );

    my $max = 1;
    foreach my $k ( keys %$login_ref ) {
        $max = length($k) if length($k) > $max;
    }
    foreach my $k ( sort keys %$login_ref ) {
        printf( '%-' . $max . 's: ' . $login_ref->{$k} . "\n", $k );
    }
}

## @method void actionList()
sub actionList {
    my $user_ref = getRandomLogin(2);
    process($user_ref);
    my $login_ref = searchLogin( $user_ref, '' );

    my @codes = ( 'login', 'sex', 'old', 'city', 'id', 'niv', 'ok', 'stat' );
    my %max = ();
    foreach my $k (@codes) {
        $max{$k} = 0;
    }
    my %sexCount = ();
    foreach my $id ( keys %userFound ) {
        my $login_ref = $userFound{$id};
        foreach my $k ( keys %$login_ref ) {
            my $l = length( $login_ref->{$k} );
            if ( $l > $max{$k} ) {
                $max{$k} = $l;
            }
        }
        $sexCount{ $login_ref->{'sex'} }++;
    }

    my $count = 0,;
    foreach my $id ( keys %userFound ) {
        my $login_ref = $userFound{$id};
        if ( defined $sex ) {
            if ( $sex == 1 ) {
                next if $login_ref->{'sex'} != 1 and $login_ref->{'sex'} != 6;
            }
            elsif ( $sex == 2 ) {
                next if $login_ref->{'sex'} != 2 and $login_ref->{'sex'} != 7;
            }
            else {
                next;
            }
        }
        my $line = '';
        foreach my $k (@codes) {
            $line .=
              '! ' . sprintf( '%-' . $max{$k} . 's', $login_ref->{$k} ) . ' ';
        }
        $line .= '!';
        print $line . "\n";
        $count++;
    }
    print Dumper \%sexCount;
    print "$count users displayed\n;";
}

## @method void process()
sub process {
    my ($user_ref) = @_;
    initUser($user_ref);
    return if $isTest;
    getCityco($user_ref);
    validatio($user_ref);
    initial($user_ref);
    agir( $user_ref,
            '40'
          . $user_ref->{'login'} . '*'
          . $user_ref->{'old'}
          . $user_ref->{'sex'}
          . $user_ref->{'citydio'}
          . $user_ref->{'myavatar'}
          . $user_ref->{'mypass'} );
}

## @method void initUser($user_ref)
sub initUser {
    my ($user_ref) = @_;
    $user_ref->{'login'} = 'Laurent' if !exists $user_ref->{'login'};
    $user_ref->{'old'}   = 40        if !exists $user_ref->{'old'};
    $user_ref->{'sex'}   = 1         if !exists $user_ref->{'sex'};
    $user_ref->{'zip'}   = '75001'   if !exists $user_ref->{'zip'};
    $user_ref->{'cookav'}   = floor( rand(890000000) + 100000000 );
    $user_ref->{'referenz'} = 0;
    $user_ref->{'speco'}    = 0;
    $user_ref->{'mynickID'} = '999999';
    $user_ref->{'monpass'}  = 0;
    $user_ref->{'roulix'}   = 0;
    $user_ref->{'sauvy'}    = '';
    $user_ref->{'cookies'}  = {};
    chang( $user_ref, 10000 + randum(3000) );
}

## @method void agir($user_ref, $txt1);
sub agir {
    my ( $user_ref, $txt1 ) = @_;
    my $url = $user_ref->{'url1'} . $txt1;
    if ($isTest) {
        sayDebug("agir() url = $url");
        return;
    }
    sayInfo("agir() url = $url");
    my $response = HttpRequest( 'GET', $url );
    my $res = $response->content();
    sayDebug($res);
    die sayError("$res: function not found")
      if $res !~ m{^([^\(]+)\('([^\)]*)'\)}xms;
    my $function = $1;
    my $arg      = $2;

    #sayInfo('function: '. $function . '; arg: ' . $arg);
    my $process;
    eval( '$process = \&' . $function );
    if ($@) {
        die sayError($@);
    }
    $process->( $user_ref, $arg );
}

## @method void process1()
# @brief
sub process1 {
    my ( $user_ref, $urlu ) = @_;
    my ($todo) = ('');

    #sayDebug("process1($urlu)");
    my $urlo = $urlu;
    my $hzy = index( $urlo, '#' );
    $urlo = substr( $urlo, $hzy + 1, length($urlo) - $hzy - 1 );

    my $urlw = index( $urlo, '|' );
    if ( $urlw > 0 ) {
        $todo = '#' . substr( $urlo, $urlw + 1, length($urlo) - $urlw - 1 );
    }

    my $firstChar = substr( $urlo, 0, 1 );
    my $molki = ord($firstChar);

    sayDebug("firstChar: $firstChar; molki = $molki");

    #
    if ( $molki < 58 ) {
        process1Int( $user_ref, $urlo );
    }
    else {
        sayInfo("process1() $molki code unknown");
    }
}

## @method hashref searchLogin($user_ref, $login)
sub searchLogin {
    my ( $user_ref, $login ) = @_;
    return {
        'sex'   => 6,
        'stat'  => 0,
        'login' => $login,
        'old'   => 37,
        'niv'   => 0,
        'ok'    => 2,
        'city'  => 30926,
        'id'    => 174135
      }
      if $isTest;
    sayDebug("searchLogin() login = $login");
    my $login_ref;
    $login_ref = checkIfLoginExists($login);
    return $login_ref if defined $login_ref;
    foreach my $g ( 1, 2 ) {
        $genru = $g;
        foreach my $y ( 1, 2, 3, 4 ) {
            $yearu = $y;
            searchnow($user_ref);
            $login_ref = checkIfLoginExists($login);
            return $login_ref if defined $login_ref;
        }
    }
    sayDebug("$login was not found");
}

## @method hashref checkIfLoginExists($login)
sub checkIfLoginExists {
    my ($login) = @_;
    foreach my $id ( keys %userFound ) {
        my $name = $userFound{$id}->{'login'};
        if ( lc($name) eq lc($login) ) {
            sayDebug("$login login was found");
            return $userFound{$id};
        }
    }

    #sayDebug("checkIfLoginExists() $login login not found");
    return;
}

## @method void process1Int($user_ref, $urlo)
sub process1Int {
    my ( $user_ref, $urlo ) = @_;
    my $olko = parseInt( substr( $urlo, 0, 2 ) );
    sayInfo("olko: $olko");
    if ( $olko == 12 ) {
        my $lebonnick = parseInt( substr( $urlo, 2, 8 - 2 ) );
        $user_ref->{'mynickID'} = '' . $lebonnick;
        $user_ref->{'monpass'}  = substr( $urlo, 8, 14 - 8 );
        $user_ref->{'mycrypt'}  = parseInt( substr( $urlo, 14, 21 - 14 ) );
        sayDebug( 'mynickID: '
              . $user_ref->{'mynickID'}
              . '; monpass: '
              . $user_ref->{'monpass'}
              . '; mycrypt: '
              . $user_ref->{'mycrypt'} );

        $olko = 51;

    }

    if ( $olko == 51 ) {
        agir( $user_ref,
                '51'
              . $user_ref->{'mynickID'}
              . $user_ref->{'monpass'}
              . $agent_ref->{'agent'} );
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

## @method void populate($urlo, $offsat)
sub populate {
    my ( $urlo, $offsat ) = @_;
    my $countNew = 0;
    if ( length($urlo) > 12 ) {
        my ( $indux, $mopo, $hzy ) = ( 0, 0, 2 );
        while ( $mopo < 1 ) {
            $indux = index( $urlo, '#', $hzy );
            if ( $indux < 2 ) {
                $mopo = 2;
            }
            else {

                my $id = parseInt( substr( $urlo, 8 + $hzy, 6 ) );
                $countNew++ if !exists $userFound{$id};
                $userFound{$id} = {
                    'id'   => $id,
                    'old'  => parseInt( substr( $urlo, $hzy, 2 ) ),
                    'sex'  => parseInt( substr( $urlo, 2 + $hzy, 1 ) ),
                    'city' => parseInt( substr( $urlo, 3 + $hzy, 5 ), 10 ),
                    'login' => substr( $urlo, 17 + $hzy, $indux - 17 - $hzy ),
                    'niv'  => parseInt( substr( $urlo, 14 + $hzy, 1 ) ),
                    'stat' => parseInt( substr( $urlo, 15 + $hzy, 1 ) ),
                    'ok'   => parseInt( substr( $urlo, 16 + $hzy, 1 ) )
                };
                $hzy = $indux + 1;
            }
        }
    }
    sayDebug("$countNew new logins was found");
}

## @method void searchnow($user_ref)
sub searchnow {
    my ($user_ref) = @_;
    sayDebug("genru: $genru; yearu: $yearu");
    my $searchito =
      '10' . $user_ref->{'mynickID'} . $user_ref->{'monpass'} . $genru . $yearu;
    agir( $user_ref, $searchito );
}

## @method void chang($user_ref, $myport)
sub chang {
    my ( $user_ref, $myport ) = @_;
    $user_ref->{'myport'} = $myport;
    $user_ref->{'url1'} =
      $coco_ref->{'urly0'} . ':' . $user_ref->{'myport'} . '/';
}

## @method void getCityco($user_ref)
sub getCityco {
    my ($user_ref) = @_;

    #$user_ref->{'citydio'} = '30926';
    #$user_ref->{'townzz'}  = 'PARIS';
    #return;

    my $zip = $user_ref->{'zip'};
    die "$zip zip code is invalide" if length($zip) != 5;
    my $i = index( $zip, '0' );
    if ( $i == 0 ) {
        $zip = substr( $zip, 1, 5 );
    }
    my $url      = 'http://www.coco.fr/cocoland/' . $zip . '.js';
    my $response = HttpRequest( 'GET', $url );
    my $res      = $response->content();

    # var cityco='30926*PARIS*';
    if ( $res !~ m{var\ cityco='([^']+)';}xms ) {
        print "$res\n";
        die sayError("cityco not found");
    }
    my $cityco = $1;
    sayDebug("cityco = $cityco");
    my @tmp = split( /\*/, $cityco );
    my ( $citydio, $townzz );
    my $count = scalar @tmp;
    print $count % 2 . "\n";
    die sayError("cityco has bad length") if $count % 2 != 0 or $count == 0;

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
    sayDebug("citydio = $citydio / townzz = $townzz");
    $user_ref->{'citydio'} = $citydio;
    $user_ref->{'townzz'}  = $townzz;
}

## @method void validatio($user_ref)
sub validatio {
    my ($user_ref) = @_;
    my $nickidol   = $user_ref->{'login'};
    my $ageuq      = $user_ref->{'old'};
    my $typum      = $user_ref->{'sex'};
    my $citydio    = $user_ref->{'citydio'};
    die sayError("bad nickidol value") if length($nickidol) < 3;
    die sayError("bad ageuq") if $ageuq < 15;
    my $citygood = $citydio;
    $citygood = "0" x ( 5 - length($citygood) ) . $citygood
      if length($citygood) < 5;

    # Check if the login name does not contain too many capital letters
    my $sume = 0;
    for ( my $i = 0 ; $i < length($nickidol) ; $i++ ) {
        my $c = substr( $nickidol, $i, 1 );
        my $ujm = ord($c);
        $sume++ if $ujm < 95 && $ujm > 59;
    }
    if ( $sume > 4 ) {
        $user_ref->{'login'} = $nickidol = lc($nickidol);
    }

    my $cookav;
    my $inform =
        $nickidol . '#' 
      . $typum . '#' 
      . $ageuq . '#'
      . $user_ref->{'townzz'} . '#'
      . $citygood . '#0#'
      . $user_ref->{'cookav'} . '#';
    sayDebug("$inform");
    $user_ref->{'inform'} = $inform;

    $user_ref->{'cookies'}->{'coda'} = $inform;

    $user_ref->{'sauvy'} = $user_ref->{'cookav'}
      if length( $user_ref->{'sauvy'} ) < 2;

    my $location =
        $coco_ref->{'urlprinc'} . "#"
      . $nickidol . '#'
      . $typum . '#'
      . $ageuq . '#'
      . $citygood . '#0#'
      . $user_ref->{'sauvy'} . '#'
      . $user_ref->{'referenz'} . '#';
    sayDebug("location: $location");
}

## @method void initial($user_ref)
sub initial {
    my ($user_ref) = @_;
    my ( $infor, $myavatar, $mypass ) = ( '', 0, '' );
    if ( exists $user_ref->{'cookies'}->{'samedi'} ) {
        $infor    = $user_ref->{'cookies'}->{'samedi'};
        $myavatar = substr( $infor, 0, 9 );
        $mypass   = substr( $infor, 9, 29 );
    }
    $myavatar = randum(890000000) + 100000000
      if ( !defined $myavatar
        or $myavatar !~ m{^\d+$}
        or $myavatar < 100000000
        or $myavatar > 1000000000 );

    $user_ref->{'myavatar'}            = $myavatar;
    $user_ref->{'mypass'}              = $mypass;
    $infor                             = $myavatar + $mypass;
    $user_ref->{'cookies'}->{'samedi'} = $infor;
    $user_ref->{'ifravatar'}           = $coco_ref->{'avaref'} . $myavatar;
    sayInfo( "ifravatar: " . $user_ref->{'ifravatar'} );

}

## @method void writus($user_ref, $s1, $destId)
sub writus {
    my ( $user_ref, $s1, $destId ) = @_;
    return if !defined $s1 or length($s1) == 0;

    my $s2 = '';
    $s2 = writo($s1);
    my $sendito = '99'
      . $user_ref->{'mynickID'}
      . $user_ref->{'monpass'}
      . $destId
      . $user_ref->{'roulix'}
      . $s2;
    agir( $user_ref, $sendito );

    #print "$sendito\n";
    sayInfo("writus() sendito: $sendito");
    $user_ref->{'roulix'}++;

    if ( $user_ref->{'roulix'} > 8 ) {
        $user_ref->{'roulix'} = 0;
    }
}

## @method string writo(string)
# @param string $s1
# @return $s1
sub writo {
    my ($s1) = @_;
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
            if (   $numerox < 42
                or ( $numerox > 59 and $numerox < 64 )
                or ( $numerox > 90 and $numerox < 97 )
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

sub transformix {
    my ( $sx, $tyb ) = @_;

}

## @method string dememe($numix)
# @param integer $numix
# @return string
sub dememe {
    my ($numix) = @_;
    return '' if !exists $dememeMatch{$numix};
    return $dememeMatch{$numix};
}

## @method object HttpRequest($url, $cookie_ref)
sub HttpRequest {
    my ( $method, $url, $cookie_ref ) = @_;
    my $req = HTTP::Request->new( $method => $url );
    sayDebug( 'HttpRequest() ' . $url );
    foreach my $field ( keys %{ $agent_ref->{'header'} } ) {
        $req->header( $field => $agent_ref->{'header'}->{$field} );
    }
    if ( defined $cookie_ref and scalar %$cookie_ref > 0 ) {
        my $cookieStr = '';
        foreach my $k ( keys %$cookie_ref ) {
            my $val = jsEscape( $cookie_ref->{$k} );
            $cookieStr .= $k . "=" . $val . ';';
        }
        chop($cookieStr);
        $req->header( 'Cookie' => $cookieStr );
    }
    my $response = $ua->request($req);
    if ( !$response->is_success() ) {
        die sayError( $response->status_line() );
    }
    return $response;
}

## @method integer randum($qxq)
sub randum {
    my ($qxq) = @_;
    return floor( rand($qxq) );
}

## @method void sayError($message)
# @param message Error message
sub sayError {
    my ($message) = @_;
    $message =~ s{(\n|\r)}{}g;
    setlog( 'info', $message );
    print STDERR $message . "\n"
      if $isVerbose;
    return $message;
}

## @method void sayInfo($message)
# @param message Info message
sub sayInfo {
    my ($message) = @_;
    $message =~ s{(\n|\r)}{}g;
    setlog( 'info', $message );
    print STDOUT $message . "\n"
      if $isVerbose;
}

## @method void sayDebug($message)
# @param message Debug message
sub sayDebug {
    return if !$isDebug;
    my ($message) = @_;
    $message =~ s{(\n|\r)}{}g;
    setlog( 'info', $message );
    print STDOUT $message . "\n"
      if $isVerbose;
}

## @method void setlog($priorite, $message)
# @param priorite Level: 'info', 'error', 'debug' or 'warning'
sub setlog {
    my ( $priorite, $message ) = @_;

    #return if !defined $sysLog_ref;
    #Sys::Syslog::syslog( $priorite, '%s', $message );
}

## @method string jsEscape($string)
# @brief works to escape a string to JavaScript's URI-escaped string.
# @author Koichi Taniguchi
sub jsEscape {
    my $string = shift;
    $string =~ s{([\x00-\x29\x2C\x3A-\x40\x5B-\x5E\x60\x7B-\x7F])}
    {'%' . uc(unpack('H2', $1))}eg;    # XXX JavaScript compatible
    $string = encode( 'ascii', $string, sub { sprintf '%%u%04X', $_[0] } );
    return $string;
}

## @method int parseInt($str, $radix)
# @author Father Chrysostomo
sub parseInt {
    my ( $str, $radix ) = @_;
    $str = 'undefined' if !defined $str;
    my $sign =
      $str =~ s/^([+-])//
      ? ( -1, 1 )[ $1 eq '+' ]
      : 1;
    $radix = ( int $radix ) % 2**32;
    $radix -= 2**32 if $radix >= 2**31;
    $radix ||=
      $str =~ /^0x/i
      ? 16
      : 10;
    $radix == 16
      and $str =~ s/^0x//i;

    return if $radix < 2 || $radix > 36;

    my @digits = ( 0 .. 9, 'a' .. 'z' )[ 0 .. $radix - 1 ];
    my $digits = join '', @digits;
    $str =~ /^([$digits]*)/i;
    $str = $1;

    my $ret;
    if ( !length $str ) {
        $ret = 'nan';
    }
    elsif ( $radix == 10 ) {
        $ret = $sign * $str;
    }
    elsif ( $radix == 16 ) {
        $ret = $sign * hex $str;
    }
    elsif ( $radix == 8 ) {
        $ret = $sign * oct $str;
    }
    elsif ( $radix == 2 ) {
        $ret = $sign * eval "0b$str";
    }
    else {
        my ( $num, $place );
        for ( reverse split //, $str ) {
            $num += (
                  $_ =~ /[0-9]/
                ? $_
                : ord(uc) - 55
            ) * $radix**$place++;
        }
        $ret = $num * $sign;
    }
    return $ret;
}

## @method generateLogins()
sub generateLogins {
    for ( my $i = 0 ; $i < 5 ; $i++ ) {
        my ( $login, $sex, $old ) = getRandomLogin();
        sayDebug("login:$login; sex: $sex; old: $old");
        my %u = (
            'login' => $login,
            'old'   => $old,
            'sex'   => $sex
        );
        process( \%u );
        sleep 1;
    }
}

## @method hashref getRandomLogin($sex);
sub getRandomLogin {
    my ($sex) = @_;
    $sex = randum(2) + 1 if !defined $sex;
    my $old = randum(35) + 15;

    my $zip;
    if ( defined $inputZipCode ) {
        $zip = $inputZipCode;
    }
    else {
        $zip = $zipCode_ref->[ randum( scalar @$zipCode_ref ) ]

    }

    # Generate a random nickname.
    my $login_ref;
    if ( $sex == 2 ) {
        $login_ref = $girlname_ref;
    }
    else {
        $login_ref = $boyname_ref;
    }
    my $i     = randum( scalar @$login_ref ) - 1;
    my $login = $login_ref->[$i];

    my $r = randum(11);
    if ( $r >= 0 and $r < 5 ) {
        $login = lc($login);
    }
    elsif ( $r == 6 and length($login) < 5 ) {
        $login = uc($login);
    }

    $r = randum(12);
    if ( $r == 0 ) {
        $r = randum(2);
        if ( $r == 1 ) {
            $login .= $old . 'ans';
        }
        else {
            $login .= $old . 'a';
        }
    }
    elsif ( $r == 1 ) {
        my $birthYear = $currentYear - $old;
        $r = randum(2);
        if ( $r == 1 ) {
            $login .= $birthYear;
        }
        else {
            $login .= substr( $birthYear, 2, 2 );
        }
    }
    elsif ( $r == 2 ) {
        $r = randum(2);
        if ( $r == 1 ) {
            $login .= $zip;
        }
        else {
            $login .= substr( $zip, 0, 2 );
        }

    }

    sayInfo("getRandomLogin() login: $login; sex: $sex, old: $old, zip: $zip");
    return { 'login' => $login, 'sex' => $sex, 'old' => $old, 'zip' => $zip };
}

## @method void init()
sub init {
    getOptions();
    readConfig();
    $ua = LWP::UserAgent->new(
        'agent'   => $agent_ref->{'agent'},
        'timeout' => $agent_ref->{'timeout'}
    );
    initializeTables();
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    $currentYear = $year + 1900;
}

## @method void initializeTables()
sub initializeTables {
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

## @method hashref confGetHash($hashref, $key)
sub confGetHash {
    my ( $hash, $key ) = @_;
    die sayError("$key hash not found or wrong")
      if ( !exists $hash->{$key} or ref $hash->{$key} ne 'HASH' );
    return $hash->{$key};
}

## @method string confIsString($hashref, $key)
sub confIsString {
    my ( $hash, $key ) = @_;
    die sayError("$key string not found or wrong")
      if ( !exists $hash->{$key} or $hash->{$key} !~ m{^.+$}m );
    return $hash->{$key};
}

## @method interger confIsString($hashref, $key)
sub confIsInt {
    my ( $hash, $key ) = @_;
    die sayError("$key integer not found or wrong")
      if ( !exists $hash->{$key} or $hash->{$key} !~ m{^\d+$} );
    return $hash->{$key};
}

## @method arrayref confGetArray($hashref, $key)
sub confGetArray {
    my ( $hash, $key ) = @_;
    die sayError("$key not found")
      if !exists $hash->{$key};
    my $r = ref $hash->{$key};
    my $array_ref;
    if ( $r eq 'ARRAY' ) {
        $array_ref = $hash->{$key};
    }
    elsif ( $r eq '' ) {
        $array_ref = [ $hash->{$key} ];
    }
    else {
        die sayError("$key is wrong");
    }
    return $array_ref;
}

## @method void readConfig()
## @brief Read an parse the configuration file
sub readConfig {
    my $confFound      = 0;
    my $configFileName = $Script;
    $configFileName =~ s{\.pl$}{\.conf}xms;
    my $filename = $Bin . '/' . $configFileName;
    my %config =
      Config::General->new( -ConfigFile => $filename, -CComments => 'off' )
      ->getall();

    # Reads 'user-agent' section
    $agent_ref = confGetHash( \%config, 'user-agent' );
    confIsString( $agent_ref, 'agent' );
    confIsInt( $agent_ref, 'timeout' );
    confGetHash( $agent_ref, 'header' );

    # Reads 'coco' section
    $coco_ref = confGetHash( \%config, 'coco' );
    confIsString( $coco_ref, 'hostname' );
    confIsString( $coco_ref, 'urlprinc' );
    confIsString( $coco_ref, 'urly0' );
    confIsString( $coco_ref, 'avatar-url' );
    confIsString( $coco_ref, 'current-url' );
    confIsString( $coco_ref, 'avaref' );

    file2array( 'nickname-man.txt',   $boyname_ref );
    file2array( 'nickname-women.txt', $girlname_ref );

    my $sentences_ref = confGetHash( \%config, 'sentences' );
    $sentences{'pb'}    = confGetArray( $sentences_ref, 'pb' );
    $sentences{'idiot'} = confGetArray( $sentences_ref, 'idiot' );
    $sentences{'hi'}    = confGetArray( $sentences_ref, 'hi' );

    my $zip_ref = confGetHash( \%config, 'zip-code' );
    $zipCode_ref = confGetArray( $zip_ref, 'code' );
}

## @method void file2array($filename, $array_ref)
# @brief Reads a file and pushes each row in a table.
# @param string $filename
# @param arrayref $array_ref
sub file2array {
    my ( $filename, $array_ref ) = @_;
    $filename = $Bin . '/' . $filename;
    my $fh;
    die sayError("open($filename) was failed: $!")
      if !open( $fh, '<', $filename );
    while ( my $line = <$fh> ) {
        chomp($line);
        push @$array_ref, $line;
    }
    close $fh;
}

## @method void getOptions()
sub getOptions {
    my %opt;
    getopts( 'dvnl:o:s:z:a:u:i:m:x:w:', \%opt ) || HELP_MESSAGE();
    $isVerbose    = 1         if exists $opt{'v'};
    $isTest       = 1         if exists $opt{'n'};
    $isDebug      = 1         if exists $opt{'d'};
    $searchUser   = $opt{'u'} if exists $opt{'u'};
    $searchId     = $opt{'i'} if exists $opt{'i'};
    $loginName    = $opt{'l'} if exists $opt{'l'};
    $user{'old'}  = $opt{'o'} if exists $opt{'o'};
    $sex          = $opt{'s'} if exists $opt{'s'};
    $inputZipCode = $opt{'z'} if exists $opt{'z'};
    $action       = $opt{'a'} if exists $opt{'a'};
    $message      = $opt{'m'} if exists $opt{'m'};
    $maxOfLoop    = $opt{'x'} if exists $opt{'x'};
    $maxOfWrite   = $opt{'w'} if exists $opt{'w'};
    if ( !defined $action ) {
        sayError("Please specify an action (option -a)");
        HELP_MESSAGE();
        exit;
    }
    if ( !exists $actions{$action} ) {
        sayError("The action '$action' is unknown");
        HELP_MESSAGE();
        exit;
    }
    if ( defined $searchId and $searchId !~ m{^\d+$} ) {
        sayError("searchId value must be an integer.");
        HELP_MESSAGE();
        exit;
    }
    if ( defined $sex ) {
        if ( $sex eq 'M' ) {
            $sex = 1;
        }
        elsif ( $sex eq 'W' ) {
            $sex = 2;
        }
        else {
            sayError("The sex argument value must be either M or W");
            HELP_MESSAGE();
            exit;
        }
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    my $lst = join( ', ', keys %actions );
    print <<ENDTXT;
Usage: 
 cocobot.pl -a action [-u searchUser -i searchId -m message 
                       -x writeLoop -w writeRepeat -z zipCode -l loginName -d -v -n]  
  -m message    Message
  -a action       Actions: $lst
  -u searchUser   A username
  -i searchId     A numeric identifiant
  -x writeLoop    Number of loops of the 'write' action
  -w writeRepeat  Number of repetition of the same message
  -s sex          M for man or W for women
  -z zipCode      A postal code (i.g. 75001)
  -l loginName    The name written in the messages
  -v verbose mode
  -d debug mode
  -n test mode
ENDTXT
    exit 0;
}

## @method void VERSION_MESSAGE()
sub VERSION_MESSAGE {
    print STDOUT <<ENDTXT;
    $Script $VERSION (2010-09-19) 
     Copyright (C) 2010 Simon Rubinstein 
     Written by Simon Rubinstein 
ENDTXT
}

