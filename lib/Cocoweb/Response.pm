# @created 2012-03-29
# @date 2012-03-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# Id: $Id$
# Revision$
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
package Cocoweb::Response;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Encode;
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use Time::HiRes qw(usleep nanosleep);
use utf8;
no utf8;

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
}

##@method void process1($user, $urlu)
#@brief Method called back after an HTTP request to the server
#@param object $user An 'Cocoweb::User::Connected' object
#@param string $urlu String returned by the server
sub process1 {
    my ( $self, $request, $user, $urlu ) = @_;
    my ($todo) = ('');

    #info($urlu);

    #debug("urlu: $urlu");
    debug( "urlu: " . substr( $urlu, 0, 80 ) );
    my $urlo = $urlu;
    my $hzy = index( $urlo, '#' );
    $urlo = substr( $urlo, $hzy + 1, length($urlo) - $hzy - 1 );

    my $urlw = index( $urlo, '|' );
    if ( $urlw > 0 ) {
        $todo = '#' . substr( $urlo, $urlw + 1, length($urlo) - $urlw - 1 );
    }

    my $firstChar = substr( $urlo, 0, 1 );
    my $molki = ord($firstChar);

    #debug("firstChar: $firstChar; molki = $molki");

    #
    if ( $molki < 58 ) {
        return $self->process1Int( $request, $user, $urlo );
    }
    else {

        #info("process1() $molki code unknown");
    }
}

## @method void process1Int($user, $urlo)
#@param object $user An 'User::Connected' object
sub process1Int {
    my ( $self, $request, $user, $urlo ) = @_;

    #debug("urlo: $urlo");
    my $olko = parseInt( substr( $urlo, 0, 2 ) );

    #debug("olko: $olko");
    #if ( $olko != 12 and $olko != 34 and $olko != 89 and $olko != 48 ) {
    #    info("olko: $olko / urlo = $urlo");
    #}

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
        $request->agir( $user,
            '51' . $request->convert()->writo( $request->agent()->{'agent'} ) );
    }

    if ( $olko == 99 ) {
        my $bud = parseInt( substr( $urlo, 2, 3 ) );
        debug("bud: $bud");

        if ( $bud == 444 ) {
            my $urlu =
              $request->convert()->transformix( substr( $urlo, 5 ), -1, 0 );
            return $urlu;
        }

        if ( $bud == 447 or $bud == 445 ) {
            die error( substr( $urlo, 5 ) );
        }

        # Retrieves information about an user, for Premium subscribers only
        if ( $bud == 555 ) {
            my $urlu =
              $request->convert()->transformix( substr( $urlo, 5 ), -1, 0 );
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
  #          $request->{'urlav'}
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
        if ( $yyg > 0 ) {
            for ( my $i = 0 ; $i < $yyg ; $i++ ) {
                my $qqb = parseInt( substr( $urlo, 2 + 7 * $i, 1 ) );
                my $qqk = parseInt( substr( $urlo, 3 + 7 * $i, 6 ), 10 );
                my $userWanted = $request->usersList()->getUser($qqk);
                if ( defined $userWanted ) {
                    if ( $qqb == 0 ) {
                        info(   "(!!!) The user '"
                              . $userWanted->mynickname()
                              . "' has disconnected." );
                        $request->usersList()->removeUser($userWanted);
                    }
                    else {
                        info(   "The user '"
                              . $userWanted->mynickname()
                              . "' is still connected." );
                    }
                }
            }
        }
    }

    # Retrieves the list of pseudonyms
    if ( $olko == 34 ) {
        $self->populate( $user, $request->usersList(), $urlo );
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
#       and call a method of object passed as parameter
#@param object $user         An 'User::Connected' object
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

1;
