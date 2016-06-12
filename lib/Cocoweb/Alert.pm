# @brief
# @created 2012-12-09
# @date 2014-06-27
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2014
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
__PACKAGE__->attributes( 'config', 'alertsSender', 'alarmCount',
    'enableAlerts' );

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    my $config
        = Cocoweb::Config->instance()->getConfigFile( 'alert.conf', 'File' );
    $instance->config($config);
    $instance->alertsSender( {} );
    $instance->alarmCount(0);
    return $instance;
}

##@method arrayref getAlerts()
sub getAlerts {
    my ($self) = @_;
    my $enableAlerts_ref = $self->enableAlerts();
    if ( !defined $enableAlerts_ref ) {

        #Read the alerts, conditions are transformed in Perl code
        debug('Read the alerts, conditions are transformed in Perl code');
        my $config     = $self->config();
        my $alerts_ref = $config->getArray('alert');
        my @alerts     = ();
        foreach my $alert_ref (@$alerts_ref) {
            $alert_ref->{'found'} = 0;
            $alert_ref->{'users'} = [];
            my $alert = Cocoweb::Config::Hash->new( 'hash' => $alert_ref );
            next if !$alert->getBool('enable');
            my $conditions_ref = $alert->getArray('condition');
            foreach my $condition (@$conditions_ref) {
                my $check = $self->getSub($condition);
                push @{ $alert_ref->{'sub'} }, $check;
            }
            push @$enableAlerts_ref, $alert;
        }
        $self->enableAlerts($enableAlerts_ref);
    }
    else {
        debug('Alerts are objects already instantiated.');
        foreach my $alert (@$enableAlerts_ref) {
            my $alert_ref = $alert->all();
            $alert_ref->{'found'} = 0;
            $alert_ref->{'users'} = [];
        }
    }
    if ( defined $enableAlerts_ref ) {
        debug( 'number of alerts: ' . scalar(@$enableAlerts_ref) . '.' );
    }
    else {
        debug('number of alerts: 0.');
    }
    return $enableAlerts_ref;
}

##@method void process($usersList)
#param object $usersList A Cocoweb::User::List object
sub process {
    my ( $self, $bot, $usersList, $isDryRun ) = @_;
    $isDryRun = 0 if !defined $isDryRun;
    info("Alert: dryrun enabled") if $isDryRun;

    my $enableAlerts_ref = $self->getAlerts();

    #Checks if each user is connected match alarm conditions
    my $user_ref            = $usersList->all();
    my $numOfAlarmsMatching = 0;
    foreach my $id ( keys %$user_ref ) {
        my $user = $user_ref->{$id};
        foreach my $alert (@$enableAlerts_ref) {
            my $allAlert_ref = $alert->all();
            my $sub_ref      = $alert->getArray('sub');
            foreach my $check (@$sub_ref) {
                next if !$check->($user);
                $allAlert_ref->{'found'} = 1;
                push @{ $allAlert_ref->{'users'} }, $user;
                $numOfAlarmsMatching++;
            }
        }
    }
    info( 'Number of alarms matching: ' . $numOfAlarmsMatching );

    #Sending alert messages if needed.
    my $alarmCount = $self->alarmCount();
    foreach my $alert (@$enableAlerts_ref) {
        my $allAlert_ref = $alert->all();
        next if !$allAlert_ref->{'found'};
        $alarmCount++;
        my $alertSender;
        eval {
            $alertSender = $self->getTransport(
                $alert->getString('transport'),
                $alert->getString('recipient')
            );
        };
        if ( $@ or !defined $alertSender ) {
            my $errStr = 'getTransport() was failed';
            $errStr .= ': ' . $@ if $@;
            error($errStr);
            next;
        }
        eval {
            $alertSender->process( $bot, $alarmCount,
                $allAlert_ref->{'users'}, $isDryRun );
        };
        if ($@) {
            my $errStr = 'process() was failed';
            $errStr .= ': ' . $@ if $@;
            error($errStr);
            next;
        }
    }
    $self->alarmCount($alarmCount);
}

##@method object getTransport($transport, $recipient)
#@brief Instantiates an object that sends the alert message.
#@param string $transport Transport used for the message, i.e.: "XMPP"
#@param string $recipient name Destination name, is the name of transport.
#@return An object.
sub getTransport {
    my ( $self, $transport, $recipient ) = @_;
    my $alertsSender_ref = $self->alertsSender();
    my $alertKey         = $transport . '::' . $recipient;
    return $alertsSender_ref->{$alertKey}
        if exists $alertsSender_ref->{$alertKey};
    my $config         = $self->config();
    my $transports_ref = $config->getArray($transport);
    foreach my $transport_ref (@$transports_ref) {
        my $transportConf
            = Cocoweb::Config::Hash->new( 'hash' => $transport_ref );
        next if $transportConf->getString('name') ne $recipient;
        require 'Cocoweb/Alert/' . $transport . '.pm';
        my $class = 'Cocoweb::Alert::' . $transport;
        my $alert = $class->new( 'conf' => $transportConf );
        $alertsSender_ref->{$alertKey} = $alert;
        return $alert;
    }
    error("$transport/$recipient transport have not been found");
    return;
}

##@method function sub getSub($condition)
#@brief Convert a condition from the configuration file in a Perl function.
#@param string $condition A condition i.e.: '$town eq "FR- Paris" and $mysex eq "2"'
#@return A Perl function
sub getSub {
    my ( $self, $condition ) = @_;
    $condition =~ s{\$([a-zA-z0-9]+)}{\$user\->{$1}}g;
    $condition
        = '$function = sub { my ($user) = @_; if ( '
        . $condition
        . ' ) { return 1; } else { return 0; } }';
    my $function;
    eval $condition;
    if ($@) {
        error("$condition: $@");
        $function = sub { return 0; };
    }
    return $function;
}

1;

