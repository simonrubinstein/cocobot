# @created 2012-03-29
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
package Cocoweb::Response;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Encode;
use Cocoweb::User;
use base 'Cocoweb::Object';
use Carp;
use Data::Dumper;
use Time::HiRes qw(usleep nanosleep);
use utf8;
no utf8;

__PACKAGE__->attributes(
    'beenDisconnected',          'isAccountProblem',
    'profileTooNew',             'infuzString',
    'userFound',                 'messageString',
    'userFriends',               'isRestrictedAccount',
    'isUserMustBeAuthenticated', 'isMenAreBlocked',
    'isPrivateAreBlocked',       'convert',
    'isUserWantToWriteIsdisconnects'
);

##@method void init($args)
#@brief Perform some initializations
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults(
        'beenDisconnected'               => 0,
        'isAccountProblem'               => 0,
        'profileTooNew'                  => 0,
        'infuzString'                    => '',
        'userFound'                      => undef,
        'messageString'                  => '',
        'userFriends'                    => undef,
        'isRestrictedAccount'            => 0,
        'isUserMustBeAuthenticated'      => 0,
        'isMenAreBlocked'                => 0,
        'isPrivateAreBlocked'            => 0,
        'convert'                        => Cocoweb::Encode->instance(),
        'isUserWantToWriteIsdisconnects' => 0
    );
}

##@method void process1($user, $urlu)
#@brief Method called back after an HTTP request to the server
#@param object $request An Cocoweb::Request object
#@param object $user An Cocoweb::User::Connected object
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
    # THE CODE IS NO LONGER USED! (replaced by olko == 15)
    if ( $olko == 12 ) {
        my $lebonnick = parseInt( substr( $urlo, 2, 6 ) );
        $user->mynickID( '' . $lebonnick );
        $user->monpass( substr( $urlo, 8, 6 ) );
        $user->mycrypt( parseInt( substr( $urlo, 14, 21 - 14 ) ) );
        info(     'mynickID: '
                . $user->mynickID()
                . '; monpass: '
                . $user->monpass()
                . '; mycrypt: '
                . $user->mycrypt() );
        $olko = 51;
    }

    # The first part of authentication was performed successfully
    # The server returns an ID, password for the current session and
    #     and snippet encrypted javascript code
    if ( $olko == 15 ) {
        my $tkt = substring( $urlo, 2, 8 );
        if ( $tkt < 900000 ) {
            $user->mynickID($tkt);
            $user->monpass( substring( $urlo, 8, 14 ) );

            # Decrypts a piece of JavaScript code returned by the server.
            my $res
                = $self->convert()
                ->enxo( substring( $urlo, 14 ), substring( $urlo, 8, 14 ),
                1 );

            # Collect the penultimate value of the 'enxo' function.
            if ( $res =~ m{guw\(enxo\([^,]+,"([^"]+)",0\)\)}xms ) {
                my $y   = $1;
                my $adz = $self->convert()->enxo(
                    $request->magicAuthString() . '*0*'
                        . $request->localIP() . '*'
                        . $request->publicIP(),
                    $y, 0
                );

                #second part of authentication:
                $request->guw( $user, $adz, $self );
            }
        }
    }

    if ( $olko == 51 ) {
        usleep( 1000 * 500 );

        #Second request used for authentication.
        $request->agir( $user, '51', $self );
    }

    if ( $olko == 99 ) {
        my $bud = parseInt( substr( $urlo, 2, 3 ) );
        debug("bud: $bud");

        if ( $bud == 443 ) {
            my $str = 'Restricted account.';
            $self->isRestrictedAccount(1);
            message($str);
        }

        #At least the following two messages:
        # - "You must have an older profile to add friends"
        # - "You have n days before expiration of your premium membership"
        if ( $bud == 444 ) {
            my $urlu = $request->convert()
                ->transformix( substr( $urlo, 5 ), -1, 0 );
            if ( $urlu =~ $request->profilTooNewRegex() ) {
                $self->profileTooNew(1);
            }
            elsif ( $urlu =~ $request->beenDisconnectedRegex() ) {

                #"vous avez ete deconnecte du serveur de messages prives..."
                $self->beenDisconnected(1);
                die error($urlu) if $request->isDieIfDisconnected();
            }
            elsif ( $urlu =~ $request->accountproblemRegex() ) {

                #Probleme avec votre compte . Essayez de vous reconnecter..."
                $self->isAccountProblem(1);
                die error($urlu) if $request->isDieIfDisconnected();
            }
            debug($urlu);
            message($urlu);
            $self->messageString($urlu);
        }

        if ( $bud == 447 or $bud == 445 ) {
            my $urlu = $request->convert()
                ->transformix( substr( $urlo, 5 ), -1, 0 );
            die error($urlu);
        }

        # Retrieves information about an user, for Premium subscribers only
        # i.e.: code: AkL -Free SAS`statut: 0 niveau: 4 depuis 0`Ville: FR- Aubervilliers
        if ( $bud == 555 ) {

            #debug("********* bud: $bud: $urlo **********");
            my $lin = indexOf( $urlo, '`' );
            my $urlu
                = substring( $urlo, 5, $lin )
                . $request->convert()
                ->transformix( substr( $urlo, $lin, length($urlo) ), -1, 0 );
            debug("urlu: $urlu");
            $self->infuzString($urlu);
        }

     # Result of a search query from a 'code de vote' (i.g. "r9x", "Mm9", ...)
     # Return Cocoweb::Request::searchCode() function.
        if ( $bud == 557 ) {

            #urlo i.e.: 9955713461399032501marco0
            #urlo i.e.: 99557099null0null
            if ( $urlo =~ m{\d{8}null\dnull$} ) {
                error("Cocoweb::Request::searchCode() return $urlo");
                $self->userFound(undef);
            }
            else {
                my $userFound = new Cocoweb::User(
                    'mynickname' => substr( $urlo, 19 ),
                    'myage'      => substr( $urlo, 11, 2 ),
                    'citydio'    => substr( $urlo, 13, 5 ),
                    'mysex'      => substr( $urlo, 18, 1 ),
                    'mynickID'   => substr( $urlo, 5, 6 ),
                    'myver'  => 0,
                    'mystat' => 5,
                    'myXP'   => 0
                );
                $self->userFound($userFound);
            }
        }

        # The second part of the authentication is completed successfully
        # The server returns some information about the user account.
        if ( $bud == 556 ) {

            $user->mystat( parseInt( substr( $urlo, 6, 1 ) ) );
            $user->myXP( parseInt( substr( $urlo, 5, 1 ) ) );
            $user->myver( parseInt( substr( $urlo, 7, 1 ) ) );
            info(     'mystat: '
                    . $user->mystat()
                    . '; myXP:'
                    . $user->myXP()
                    . '; myver: '
                    . $user->myver() );

            my ( $ind, $ind2, $ind3, $tro, $hzy ) = ( 0, 0, 0, 1, 9 );
            my $mycrypt3;
            while ($tro) {
                $ind  = indexOf( $urlo, '#', $hzy );
                $ind2 = indexOf( $urlo, '{', $hzy );
                $ind3 = indexOf( $urlo, '}', $hzy );
                if ( $ind2 > 0 and $ind2 < $ind ) {
                    $ind = $ind2;
                }
                if ( $ind3 > 0 and $ind3 < $ind ) {
                    $ind = $ind3;
                }
                if ( $ind > 0 ) {
                    $hzy = $ind + 1;
                }
                else {
                    $tro = 0;
                    my $fdl = indexOf( $urlo, '*', $hzy );
                    my $mymail = substring( $urlo, $hzy, $fdl );
                    $mycrypt3 = substring( $urlo, $fdl + 1, $fdl + 13 );
                    my $nbsms
                        = parseInt( substring( $urlo, $fdl + 13, $fdl + 17 ) )
                        - 1000;
                    my $dpy = indexOf( $urlo, '$', $fdl );
                    my $mysms = substring( $urlo, $fdl + 17, $dpy );
                    my $dpx = indexOf( $urlo, '!', $fdl );
                    my $mytime = substring( $urlo, $dpy + 2, $dpx );
                    my $neutri = substring( $urlo, $dpy + 1, $dpy + 2 );
                    my $myblog = substring( $urlo, $dpx + 1 );
                    $mymail = '' if !defined $mymail;
                    debug("mymail: $mymail; mycrypt3: $mycrypt3");
                }
            }

            #HTTP request to load the avatar image.
            if ( $request->isAvatarRequest() ) {
                eval {
                    $request->agix(
                        $user,
                        $request->{'urlav'}
                            . $user->myage()
                            . $user->mysex()
                            . $user->citydio()
                            . $user->myavatar()
                            . $user->mynickID()
                            . $user->monpass()
                            . $mycrypt3,
                        undef,
                        $self
                    );
                };
            }
        }

        if ( $bud == 148 ) {
            die error( 'This account has been permanently banned: '
                    . substr( $urlo, 14 ) );
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
            $user->mypass( substring( $urlo, 2 ) );
            info(
                'The password "' . $user->mypass() . '" has been recovered' );
        }
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
        my @usersStillConnected = ();
        my $disconnectedUsers   = '';
        my $countDiscUsers      = 0;
        my $yyg                 = ( length($urlo) - 2 ) / 7;
        if ( $yyg > 0 ) {
            for ( my $i = 0; $i < $yyg; $i++ ) {
                my $qqb = parseInt( substr( $urlo, 2 + 7 * $i, 1 ) );
                my $qqk = parseInt( substr( $urlo, 3 + 7 * $i, 6 ), 10 );
                my $userWanted = $request->usersList()->getUser($qqk);
                if ( defined $userWanted ) {
                    if ( $qqb == 0 ) {
                        $disconnectedUsers
                            .= $userWanted->mynickname() . '; ';
                        $countDiscUsers++;
                        $request->usersList()->removeUser($userWanted);
                    }
                    else {
                        push @usersStillConnected, $userWanted;
                    }
                }
            }
        }
        if ( scalar(@usersStillConnected) > 0 ) {
            my $usersStr = '';
            foreach my $user (@usersStillConnected) {
                $usersStr .= $user->mynickname() . '; ';
            }
            info(
                      scalar(@usersStillConnected)
                    . ' user(s) are still connected: '
                    . $usersStr );
            undef @usersStillConnected;
        }
        if ( $countDiscUsers > 0 ) {
            info(     $countDiscUsers
                    . ' user(s) have disconnected: '
                    . $disconnectedUsers );
        }
    }

    if ( $olko == 94 ) {
        my $str = 'This user requires that you be authenticated.';
        debug($str);
        message($str);
        $self->isUserMustBeAuthenticated(1);
        $olko = 967;
    }

    # Retrieves the list of pseudonyms
    if ( $olko == 34 ) {
        $self->populate( $user, $request->usersList(), $urlo );
    }
    elsif ( $olko == 13 ) {
        die error("You have been disconnected. Log back on Coco.fr");
    }
    elsif ( $olko == 10 ) {
        die error('You are disconnected because someone with the'
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

    #The response to the first HTTP request to load the avatar image.
    if ( $olko == 23 ) {
        my $mysex = $user->mysex();
        if ( $mysex < 5 ) {
            $mysex += 5;
            $user->mysex($mysex);

            #Second HTTP request to load the avatar image.
            $request->agir( $user, '60', $self );
        }
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
        $self->isPrivateAreBlocked(1);
        $olko = 967;
    }

    # No more male user message is accepted
    if ( $olko == 96 ) {
        info("No more male user message is accepted.");
        $self->isMenAreBlocked(1);
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
        $self->userFriends( $user->amiz() );
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
                        warning(
                            "The $idgars user you want to write is disconnected"
                        );
                        $self->isUserWantToWriteIsdisconnects(1);
                    }
                    else {
                        my $zami = parseInt( substr( $urlo, $hzq, 6 ) );
                        if ( ( $diase - $hzq ) == 7 ) {
                            message( 'The user "'
                                    . $request->usersList()
                                    ->nickIdToNickname($zami)
                                    . '" writing...' );
                        }
                    }
                }
                else {
                    my $toilo = indexOf( $urlo, '#', $hzq );
                    my $mokage
                        = parseInt( substring( $urlo, $hzq, 2 + $hzq ) );
                    my $moksex
                        = parseInt( substring( $urlo, 2 + $hzq, 3 + $hzq ) );
                    my $mokville
                        = parseInt( substring( $urlo, 3 + $hzq, 8 + $hzq ) );
                    my $moknickID
                        = parseInt( substring( $urlo, 8 + $hzq, 14 + $hzq ) );
                    my $statq = parseInt( substring( $urlo, 15 + $hzq, 16 ) );
                    my $okb   = parseInt( substring( $urlo, 16 + $hzq, 17 ) );
                    my $mokpseudo = substring( $urlo, 17 + $hzq, $toilo );
                    $diase = indexOf( $urlo, '#', $toilo + 1 ) + 1;
                    my $mokmess = substring( $urlo, $toilo + 1, $diase - 1 );

                   #eval {
                   #    $mokmess = $request->convert()->transformix($mokmess);
                   #};
                    my $user = $request->usersList()->getUser($moknickID);

                    if ( !defined $user ) {
                        debug("Create user $moknickID/$mokpseudo");
                        $user = Cocoweb::User->new(
                            'mynickID'   => $moknickID,
                            'myage'      => $mokage,
                            'mysex'      => $moksex,
                            'citydio'    => $mokville,
                            'mynickname' => $mokpseudo,
                            'myXP'       => 0,
                            'mystat'     => $statq,
                            'myver'      => $okb
                        );
                        if ( $request->isAddNewWriterUserIntoList() ) {
                            debug(
                                "Add new user $moknickID/$mokpseudo in the list"
                            );
                            $request->usersList()->addUser($user);
                        }
                    }

                    #$user->hasSentMessage($mokmess);

                    $self->incomingMessage( $request, $user, $mokmess );

                    #message('code: '
                    #      . $user->code()
                    #      . '; town: '
                    #      . $user->town()
                    #      . '; ISP: '
                    #      . $user->ISP()
                    #      . '; mysex: '
                    #      . $user->mysex()
                    #      . '; myage: '
                    #      . $user->myage() . ' / '
                    #      . $mokpseudo . ' : '
                    #      . $mokmess );
                }
                $hzq = $diase;
                $kopo = 1 if $hzq > $lengus - 3;
            }

        }
        else {
            if ( $lengus == 5 ) {
                if ( index( $urlo, '111' ) > -1 ) {
                    die error('The servers are being restarted.'
                            . ' Log back in a moment' );
                }
            }
        }

    }

}

sub incomingMessage {
    my ( $self, $request, $user, $makmessage ) = @_;
    my ( $chp, $hys, $message ) = ( 1, 0, '' );
    if ( indexOf( $makmessage, '&' ) > -1 ) {
        $hys = indexOf( $makmessage, '&9' );
        if ( $hys > -1 ) {
            $chp = 0;
            my $infor = substring( $makmessage, $hys + 3 );
            $message
                = 'Your profile has been successfully recovered: (infor = '
                . $infor . ')';
            die warning($message);
        }
        $hys = indexOf( $makmessage, '&7' );
        if ( $hys > -1 ) {
            $chp     = 0;
            $message = substring( $makmessage, $hys + 3 );
            $message = $self->transformix( $request, $message );
            error($message);
        }
        $hys = indexOf( $makmessage, '&4' );
        if ( $hys > -1 ) {
        }
        $hys = indexOf( $makmessage, '&B' );
        if ( $hys > -1 ) {
        }

        #Time remaining before the end of the subscription.
        $hys = indexOf( $makmessage, '&P' );
        if ( $hys > -1 ) {
            $chp = 0;
            $message = substring( $makmessage, $hys + 3 );
            warning($message);
        }
        $hys = indexOf( $makmessage, '&G' );
        if ( $hys > -1 ) {
            $chp = 0;
            my $nbsms = substring( $makmessage, $hys + 3 );
            $message = 'You have ' . $nbsms . ' SMS on your account.';
            warning($message);
        }

    }
    return if $chp == 0;
    my $s1 = $makmessage;

    my $s2 = '';
    if ( $chp != 3 and $chp > 0 ) {
        $s2 = $self->transformix( $request, $s1 );
    }
    else {
        $s2 = $s1;
    }
    my $mimiz = indexOf( $s2, '{5' );
    if ( $mimiz > -1 ) {
        $s2 = 'Will you accept ' . $user->mynickname() . ' as a friend?';
    }
    $mimiz = indexOf( $s2, '{6' );
    if ( $mimiz > -1 ) {
        $s2 = $user->mynickname() . 'Bob accepted you as a friend.';
    }
    $user->hasSentMessage($s2);
    info( $user->mynickname() . '> ' . $s2 );

}

sub transformix {
    my ( $self, $request, $message ) = @_;
    my $string = '';
    eval { $string = $request->convert()->transformix($message); };
    return $string;
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
