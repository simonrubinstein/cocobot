# @brief
# @created 2012-02-26
# @date 2011-03-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2012
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
package Cocoweb::CLI;
use Cocoweb;
use Cocoweb::Bot;
use Cocoweb::User::Wanted;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use Data::Dumper;
use Term::ANSIColor;
$Term::ANSIColor::AUTORESET = 1;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use strict;
use warnings;
__PACKAGE__->attributes(
    'mynickname',     'myage',
    'mysex',          'myavatar',
    'mypass',         'searchId',
    'searchNickname', 'maxOfLoop',
    'enableLoop',     'avatarAndPasswdRequired',
    'searchEnable'
);

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->attributes_defaults(
        'mynickname'              => undef,
        'myage'                   => undef,
        'mysex'                   => undef,
        'myavatar'                => undef,
        'mypass'                  => undef,
        'searchId'                => undef,
        'searchNickname'          => undef,
        'maxOfLoop'               => undef,
        'enableLoop'              => 0,
        'avatarAndPasswdRequired' => 0,
        'searchEnable'            => 0
    );
    return $instance;
}

##@method hashref getOpts($argumentative)
#@brief Processes single-character switches with switch clustering.
#@param string $argumentative
#@return hashref The values found in arguments
sub getOpts {
    my ( $self, %argv ) = @_;
    foreach my $name ( 'searchEnable', 'enableLoop', 'avatarAndPasswdRequired' )
    {
        next if !exists $argv{$name};
        $self->$name( $argv{$name} );
    }
    my $argumentative = '';
    $argumentative = $argv{'argumentative'} if exists $argv{'argumentative'};
    $argumentative .= 'dvDu:s:y:a:p:';
    $argumentative .= 'l:i:' if $self->searchEnable();
    $argumentative .= 'x:' if $self->enableLoop();
    my %opt;
    if ( !getopts( $argumentative, \%opt ) ) {
        return;
    }
    $Cocoweb::isVerbose = 1
      if exists $opt{'v'}
          or exists $opt{'d'}
          or exists $opt{'D'};
    $Cocoweb::isDebug = 1 if exists $opt{'d'} or exists $opt{'D'};
    $Cocoweb::isMoreDebug = 1 if exists $opt{'D'};
    $self->mynickname( $opt{'u'} )     if exists $opt{'u'};
    $self->myage( $opt{'y'} )          if exists $opt{'y'};
    $self->mysex( $opt{'s'} )          if exists $opt{'s'};
    $self->myavatar( $opt{'a'} )       if exists $opt{'a'};
    $self->mypass( $opt{'p'} )         if exists $opt{'p'};
    $self->searchId( $opt{'i'} )       if exists $opt{'i'};
    $self->searchNickname( $opt{'l'} ) if exists $opt{'l'};
    $self->maxOfLoop( $opt{'x'} )      if exists $opt{'x'};

    if ( defined $self->mysex() ) {
        if ( $self->mysex() eq 'M' ) {
            $self->mysex(1);
        }
        elsif ( $self->mysex() eq 'W' ) {
            $self->mysex(2);
        }
        else {
            error(  'The sex argument value must be either M or W.'
                  . ' (-s option)' );
            return;
        }
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
        error(  'An avatar identifier and password'
              . ' are required for this script' );

        return;
    }

    if ( $self->enableLoop() ) {
        if ( defined $self->maxOfLoop() ) {
            if ( $self->maxOfLoop() !~ m{^\d+$} ) {
                error(
                    'The max of loop should be an integer.' . ' (-x option)' );
                return;
            }
        }
        else {
            $self->maxOfLoop(1);
        }
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
    foreach my $name ( 'mynickname', 'myage', 'mysex', 'myavatar', 'mypass' ) {
        push @params, $name, $self->$name() if defined $self->$name();
    }
    my $bot = Cocoweb::Bot->new(@params);
    return $bot;
}

##@method object getUserWanted($bot)
sub getUserWanted {
    my ( $self, $bot ) = @_;
    $bot->requestAuthentication() if !$bot->isAuthenticated();
    my $userWanted;
    if ( defined $self->searchNickname() ) {
        $userWanted =
          Cocoweb::User::Wanted->new( 'mynickname' => $self->searchNickname() );
        $userWanted = $bot->searchNickname($userWanted);
        if ( !defined $userWanted ) {
            print STDOUT 'The pseudonym "'
              . $self->searchNickname()
              . '" was not found.' . "\n";
            return;
        }
    }
    elsif ( defined $self->searchId() ) {
        $userWanted =
          Cocoweb::User::Wanted->new( 'mynickID' => $self->searchId() );
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
    $args .= '-x maxOfLoop '                  if $self->enableLoop();
    $args .= '(-l nickname | -i nicknameId) ' if $self->searchEnable();
    $args .= '[' if !$self->avatarAndPasswdRequired();
    $args .= '-a myavatar -p mypass ';
    $args .= '[' if $self->avatarAndPasswdRequired();
    $args .= '-u mynickname -y myage -s mysex -v -d -D]';
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
      if $self->enableLoop();

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
  -v                Verbose mode
  -d                Debug mode
  -D                More debug messages
ENDTXT
}

##@method void VERSION_MESSAGE($date, $version)
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    my ( $self, $date, $version ) = @_;
    $version = $Cocoweb::VERSION if !defined $version;
    print STDOUT <<ENDTXT;
    $Script $version ($date) 
    Copyright (C) 2010-2012 Simon Rubinstein 
    Written by Simon Rubinstein 
ENDTXT
}

1;

