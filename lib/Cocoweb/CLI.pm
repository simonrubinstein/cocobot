# @brief
# @created 2012-02-26
# @date 2018-08-05
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2016
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
package Cocoweb::CLI;
use Cocoweb;
use Cocoweb::MyAvatar::File;
use Cocoweb::Bot;
use Cocoweb::File;
use Cocoweb::Logger;
use Cocoweb::User::Wanted;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use List::Util qw( first );
use Data::Dumper;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use strict;
use warnings;
__PACKAGE__->attributes(
    'mynickname',          'myage',
    'mysex',               'myavatar',
    'mypass',              'searchId',
    'searchNickname',      'maxOfLoop',
    'enableLoop',          'avatarAndPasswdRequired',
    'searchEnable',        'pidHandle',
    'writeLogInFile',      'isAvatarRequest',
    'delay',               'zip',
    'myavatarsListEnable', 'myavatarsListRequired',
    'myavatarsList',       'riveScriptDir',
    'riveScriptGenderAnswer'
);

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->attributes_defaults(
        'mynickname'              => undef,
        'myage'                   => undef,
        'mysex'                   => undef,
        'zip'                     => undef,
        'myavatar'                => undef,
        'mypass'                  => undef,
        'searchId'                => undef,
        'searchNickname'          => undef,
        'maxOfLoop'               => undef,
        'enableLoop'              => 0,
        'avatarAndPasswdRequired' => 0,
        'searchEnable'            => 0,
        'pidHandle'               => undef,
        'writeLogInFile'          => 1,
        'isAvatarRequest'         => 0,
        'delay'                   => 1,
        'myavatarsListEnable'     => 0,
        'myavatarsListRequired'   => 0,
        'myavatarsList'           => 0,
        'riveScriptDir'           => undef,
        'riveScriptGenderAnswer'  => undef
    );
    return $instance;
}

##@method void lockSingleInstance()
#@brief Ensure application is running as a single instance
sub lockSingleInstance {
    my ($self) = @_;
    $self->pidHandle( writeProcessID() );
}

##@method hashref getOpts($argumentative)
#@brief Processes single-character switches with switch clustering.
#@param string $argumentative
#@return hashref The values found in arguments
sub getOpts {
    my ( $self, %argv ) = @_;
    my $writeLogInFile = 0;
    foreach my $name (
        'searchEnable',            'enableLoop',
        'avatarAndPasswdRequired', 'myavatarsListEnable'
        )
    {
        next if !exists $argv{$name};
        $self->$name( $argv{$name} );
    }
    my $argumentative = '';
    $argumentative = $argv{'argumentative'} if exists $argv{'argumentative'};
    $argumentative .= 'wdvDu:s:y:z:a:p:gV:G:';
    $argumentative .= 'l:i:' if $self->searchEnable();
    $argumentative .= 'x:S:' if $self->enableLoop();
    $argumentative .= 'M' if $self->myavatarsListEnable();
    my %opt;

    if ( !getopts( $argumentative, \%opt ) ) {
        return;
    }
    $Cocoweb::isVerbose = 1
        if exists $opt{'v'}
        or exists $opt{'d'}
        or exists $opt{'D'};
    $Cocoweb::isDebug     = 1 if exists $opt{'d'} or exists $opt{'D'};
    $Cocoweb::isMoreDebug = 1 if exists $opt{'D'};
    $writeLogInFile       = 1 if exists $opt{'w'};
    Cocoweb::Logger->instance()->writeLogInFile($writeLogInFile);
    $self->mynickname( $opt{'u'} )             if exists $opt{'u'};
    $self->myage( $opt{'y'} )                  if exists $opt{'y'};
    $self->mysex( $opt{'s'} )                  if exists $opt{'s'};
    $self->zip( $opt{'z'} )                    if exists $opt{'z'};
    $self->myavatar( $opt{'a'} )               if exists $opt{'a'};
    $self->mypass( $opt{'p'} )                 if exists $opt{'p'};
    $self->searchId( $opt{'i'} )               if exists $opt{'i'};
    $self->searchNickname( $opt{'l'} )         if exists $opt{'l'};
    $self->maxOfLoop( $opt{'x'} )              if exists $opt{'x'};
    $self->delay( $opt{'S'} )                  if exists $opt{'S'};
    $self->isAvatarRequest(1)                  if exists $opt{'g'};
    $self->myavatarsListRequired(1)            if exists $opt{'M'};
    $self->riveScriptDir( $opt{'V'} )          if exists $opt{'V'};
    $self->riveScriptGenderAnswer( $opt{'G'} ) if exists $opt{'G'};

    info( "isAvatarRequest: " . $self->isAvatarRequest() );

    if ( defined $self->mysex() ) {
        if ( $self->mysex() eq 'M' ) {
            $self->mysex(1);
        }
        elsif ( $self->mysex() eq 'W' ) {
            $self->mysex(2);
        }
        else {
            error(    'The sex argument value must be either M or W.'
                    . ' (-s option)' );
            return;
        }
    }
    if (    defined $self->riveScriptGenderAnswer()
        and $self->riveScriptGenderAnswer() ne 'W'
        and $self->riveScriptGenderAnswer() ne 'M' )
    {
        error(    'The gender argument value must be either M or W.'
                . ' (-G option)' );
        return;
    }
    if ( defined $self->riveScriptGenderAnswer()
        and !defined $self->riveScriptDir() )
    {
        error('Option -G only works with option -V');
        return;
    }

    if ( defined $self->myage() and $self->myage() !~ m{^\d+$} ) {
        error("The age should be an integer. (-y option)");
        return;
    }
    if ( defined $self->searchId() and $self->searchId() !~ m{^\d+$} ) {
        error("searchId value must be an integer. (-i option)");
        return;
    }

    # The search for a nickname or nickmae id is enabled
    if (    $self->searchEnable()
        and !defined $self->searchNickname()
        and !defined $self->searchId() )
    {
        error("You must specify an username (-l) or ID (-i)");
        return;
    }
    if (    $self->searchEnable()
        and defined $self->searchNickname()
        and defined $self->searchId() )
    {
        error('You must specify either a user or an id (-l) or ID -i');
        return;
    }

    # An avatar identifier and password are required
    if ( $self->avatarAndPasswdRequired()
        and ( !defined $self->myavatar or !defined $self->mypass() ) )
    {
        error(    'An avatar identifier and password'
                . ' are required for this script' );

        return;
    }

    if ( $self->enableLoop() ) {
        if ( defined $self->maxOfLoop() ) {
            if ( $self->maxOfLoop() !~ m{^\d+$} ) {
                error(    'The max of loop should be an integer.'
                        . ' (-x option)' );
                return;
            }
        }
        else {
            $self->maxOfLoop(1);
        }
        if ( $self->delay() !~ m{^\d+$} ) {
            error( 'The delay should be an integer.' . ' (-S option)' );
            return;
        }
    }

    if ( $self->myavatarsListRequired() ) {
        my $myavatarFiles = Cocoweb::MyAvatar::File->instance();
        $myavatarFiles->initList();
        $self->myavatarsList($myavatarFiles);
    }
    return \%opt;
}

##@method hashref getMinimumOpts($argumentative)
#@brief Processes single-character switches with switch clustering.
#@param string $argumentative
#@return hashref The values found in arguments
sub getMinimumOpts {
    my ( $self, %argv ) = @_;
    my $argumentative = '';
    $argumentative = $argv{'argumentative'} if exists $argv{'argumentative'};
    $argumentative .= 'dv';
    my %opt;
    if ( !getopts( $argumentative, \%opt ) ) {
        return;
    }
    $Cocoweb::isVerbose = 1 if exists $opt{'v'};
    $Cocoweb::isDebug   = 1 if exists $opt{'d'};
    return \%opt;
}

##@method object getBot()
#@brief Creates an instance of an Cocoweb::Bot object.
#@return object A Cocoweb::Bot object
sub getBot {
    my ( $self, @params ) = @_;
    my %param = @params;
    my ( $myavatar, $mypass );
    if ( !exists $param{'myavatar'} and $self->myavatarsListRequired() ) {
        my $myavatarFiles = $self->myavatarsList();
        if ( defined $myavatarFiles ) {
            ( $myavatar, $mypass ) = $myavatarFiles->getNextMyavatar();
        }
    }
    foreach my $name (
        'mynickname',      'myage',
        'mysex',           'zip',
        'myavatar',        'mypass',
        'isAvatarRequest', 'riveScriptDir',
        'riveScriptGenderAnswer'
        )
    {
        next if exists $param{$name};
        if ( defined $self->$name() ) {
            push @params, $name, $self->$name();
            next;
        }
        if ( $name eq 'myavatar' and defined $myavatar ) {
            push @params, $name, $myavatar;
            next;
        }
        if ( $name eq 'mypass' and defined $mypass ) {
            push @params, $name, $mypass;
            next;
        }
    }
    my $bot = Cocoweb::Bot->new(@params);

    #print Dumper \%param;
    return $bot;
}

##@method object getUserWanted($bot)
sub getUserWanted {
    my ( $self, $bot ) = @_;
    $bot->requestAuthentication() if !$bot->isAuthenticated();
    my $userWanted;
    if ( defined $self->searchNickname() ) {
        $userWanted = Cocoweb::User::Wanted->new(
            'mynickname' => $self->searchNickname() );
        $userWanted = $bot->searchNickname($userWanted);
        if ( !defined $userWanted ) {
            print STDOUT 'The pseudonym "'
                . $self->searchNickname()
                . '" was not found.' . "\n";
            return;
        }
    }
    elsif ( defined $self->searchId() ) {
        $userWanted
            = Cocoweb::User::Wanted->new( 'mynickID' => $self->searchId() );
    }
    else {
        croak error('No nickname or nickname id were found');
    }
    return $userWanted;
}

##@method string getLineOfArgs($addArgs)
sub getLineOfArgs {
    my ( $self, $addArgs ) = @_;
    my $args = 'Usage: ' . $Script . ' ';
    $args .= $addArgs . ' '                   if defined $addArgs;
    $args .= '-x maxOfLoop -S seconds '       if $self->enableLoop();
    $args .= '(-l nickname | -i nicknameId) ' if $self->searchEnable();
    $args .= '[' if !$self->avatarAndPasswdRequired();
    $args .= '-a myavatar -p mypass ';
    $args .= '[' if $self->avatarAndPasswdRequired();
    $args .= '-u mynickname -y myage -s mysex -v -d -D -w]';
    return $args;
}

##@method void printLineOfArgs($addArgs)
sub printLineOfArgs {
    my ( $self, $addArgs ) = @_;
    print STDOUT $self->getLineOfArgs($addArgs) . "\n";
}

##@void HELP()
#@brief Displays help standard used by all scripts.
sub HELP {
    my ($self) = @_;
    print STDOUT "  -l nickname       The nickname wanted.\n"
        if $self->searchEnable();
    print STDOUT "  -i nicknameId     The nickmane ID wanted.\n"
        if $self->searchEnable();
    print STDOUT
        "  -x maxOfLoop      A maximum number of iterations to perform.\n"
        . "  -S seconds        Delays the loop execution for the given number of seconds.\n"
        if $self->enableLoop();
    print STDOUT
        "  -M                Uses the pre-created myavatars list from \"var/myavatar/list.txt\" file\n"
        if $self->myavatarsListEnable();

    print STDOUT <<ENDTXT;
  -a myavatar       A unique identifier for your account 
                    The first 9 digits of cookie "samedi".
  -p mypass         The password for your account
                    The last 20 alphabetic characters of cookie "samedi".
  -u mynickname     A nickname will be used by the bot.
                    Otherwise a nickname will be randomly generated.
  -y myage          An age in years that will be used by the bot. 
                    Otherwise an age will be randomly generated.
  -s mysex          M for man or W for women
  -z zipCode        A postal code (i.e. 75001). 
                    If a code "00000" then entered a zip code
                      is chosen randomly over the entire France.
                    A postal code is randomly chosen on Paris
                      if no code is entered.
  -g                Request to load the avatar.
                    By default avatar image is not loaded. 
  -v                Verbose mode
  -d                Debug mode
  -D                More debug messages
  -w                Written logs to a file 
  -V dirname        RiveScript directory
  -G gender         Limits  RiveScript anwsers to male "M"
                    or female "F" gender profiles.
ENDTXT
}

##@method void VERSION_MESSAGE($date, $version)
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    my ( $self, $date, $version ) = @_;
    $version = $Cocoweb::VERSION if !defined $version;
    print STDOUT <<ENDTXT;
    $Script $version ($date) 
    Copyright (C) 2010-2018 Simon Rubinstein 
    Written by Simon Rubinstein 
ENDTXT
}

1;

