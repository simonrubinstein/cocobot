# @brief
# @created 2012-02-26
# @date 2011-02-28
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
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use Data::Dumper;
use Term::ANSIColor;
use Getopt::Std;
$Getopt::Std::STANDARD_HELP_VERSION = 1;
use strict;
use warnings;
__PACKAGE__->attributes(
    'mynickname', 'myage',    'mysex', 'myavatar',
    'mypass',     'searchId', 'searchNickname'
);

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->attributes_defaults(
        'mynickname'     => undef,
        'myage'          => undef,
        'mysex'          => undef,
        'myavatar'       => undef,
        'mypass'         => undef,
        'searchId'       => undef,
        'searchNickname' => undef
    );
    return $instance;
}

##@method hashref getOptos($argumentative)
#@brief Processes single-character switches with switch clustering.
#@param string $argumentative
#@return hashref The values found in arguments
sub getOpts {
    my ( $self, %argv ) = @_;

    my ( $searchEnable, $argumentative ) = ( 0, '' );

    $searchEnable  = $argv{'searchEnable'}  if exists $argv{'searchEnable'};
    $argumentative = $argv{'argumentative'} if exists $argv{'argumentative'};
    $argumentative .= 'dvu:s:y:a:p:';
    my %opt;
    if ( !getopts( $argumentative, \%opt ) ) {
        return;
    }
    $Cocoweb::isVerbose = 1 if exists $opt{'v'};
    $Cocoweb::isDebug   = 1 if exists $opt{'d'};
    $self->mynickname( $opt{'u'} )     if exists $opt{'u'};
    $self->myage( $opt{'y'} )          if exists $opt{'y'};
    $self->mysex( $opt{'s'} )          if exists $opt{'s'};
    $self->myavatar( $opt{'a'} )       if exists $opt{'a'};
    $self->mypass( $opt{'p'} )         if exists $opt{'p'};
    $self->searchId( $opt{'i'} )       if exists $opt{'i'};
    $self->searchNickname( $opt{'l'} ) if exists $opt{'l'};

    if ( defined $self->mysex() ) {
        if ( $self->mysex() eq 'M' ) {
            $self->mysex(1);
        }
        elsif ( $self->mysex() eq 'W' ) {
            $self->mysex(2);
        }
        else {
            error("The sex argument value must be either M or W. (-s option)");
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
    if (    $searchEnable
        and !defined $self->searchNickname()
        and !defined $self->searchId() )
    {
        error("You must specify an username (-l) or ID (-i)");
        return;
    }
    if (    $searchEnable
        and defined $self->searchNickname()
        and defined $self->searchId() )
    {
        error("You must specify either a user or an id (-l) or ID -i");
        return;
    }

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

1;

