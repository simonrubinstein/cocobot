# @brief
# @created 2012-12-09
# @date 2012-12-11
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
package Cocoweb::Alert;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use FindBin qw($Script $Bin);
use base 'Cocoweb::Object::Singleton';
use Cocoweb;
use Cocoweb::Config;
__PACKAGE__->attributes( 'config', 'alertsSender' );

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    my $config =
      Cocoweb::Config->instance()->getConfigFile( 'alert.conf', 'File' );
    $instance->config($config);
    $instance->alertsSender( {} );
    return $instance;
}

sub process {
    my ( $self, $usersList ) = @_;

    #Read the alerts, conditions are transformed in Perl code
    my $config     = $self->config();
    my $alerts_ref = $config->getArray('alert');
    my @alerts     = ();
    foreach my $alert_ref (@$alerts_ref) {
        my $alert = Cocoweb::Config::Hash->new( 'hash' => $alert_ref );
        next if !$alert->getBool('enable');
        $alert_ref->{'found'} = 0;
        $alert_ref->{'users'} = [];
        my $conditions_ref = $alert->getArray('condition');
        foreach my $condition (@$conditions_ref) {
            my $check = $self->getSub($condition);
            push @{ $alert_ref->{'sub'} }, $check;
        }
        push @alerts, $alert;
    }

    # Checks if each user is connected match alarm conditions
    my $user_ref = $usersList->all();
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        foreach my $alert (@alerts) {
            my $allAlert_ref = $alert->all();
            my $sub_ref      = $alert->getArray('sub');
            foreach my $check (@$sub_ref) {
                next if !$check->($user);
                $allAlert_ref->{'found'} = 1;
                push @{ $allAlert_ref->{'users'} }, $user;
            }
        }
    }

    foreach my $alert (@alerts) {
        my $allAlert_ref = $alert->all();
        next if !$allAlert_ref->{'found'};
        my $body = '';
        foreach my $user ( @{ $allAlert_ref->{'users'} } ) {
            $body .=
                $user->mynickname() . "; "
              . $user->myage() . " "
              . $user->mysex() . " "
              . $user->ISP() . "; "
              . $user->citydio() . "; "
              . $user->town() . "\n";
        }
        debug($body);
        my $alertSender = $self->getTransport( $alert->getString('transport'),
            $alert->getString('recipient') );

        $alertSender->messageSend($body);

    }

}

sub getTransport {
    my ( $self, $transport, $recipient ) = @_;
    my $alertsSender_ref = $self->alertsSender();
    my $alertKey         = $transport . '::' . $recipient;
    return $alertsSender_ref->{$alertKey}
      if exists $alertsSender_ref->{$alertKey};
    my $config         = $self->config();
    my $transports_ref = $config->getArray($transport);
    foreach my $transport_ref (@$transports_ref) {
        my $transportConf =
          Cocoweb::Config::Hash->new( 'hash' => $transport_ref );
        next if $transportConf->getString('name') ne $recipient;
        print Dumper $transport_ref;
        require 'Cocoweb/Alert/' . $transport . '.pm';
        my $class = 'Cocoweb::Alert::' . $transport;
        my $alert = $class->new( 'conf' => $transportConf );
        $alertsSender_ref->{$alertKey} = $alert;
        return $alert;
    }
    return;
}

sub getSub {
    my ( $self, $condition ) = @_;
    $condition =~ s{\$([a-zA-z0-9]+)}{\$user\->{$1}}g;
    $condition =
        '$function = sub { my ($user) = @_; if ( '
      . $condition
      . ' ) { return 1; } else { return 0; } }';
    my $function;
    eval $condition;
    croak error("$condition: $@") if $@;
    return $function;
}

1;

