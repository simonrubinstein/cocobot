# @created 2012-02-17 
# @date 2012-02-18
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
 
 __PACKAGE__->attributes('myport', 'url1');


my $conf_ref;
my $agent_ref;
my $userAgent;

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    if (!defined $conf_ref) {
        my $conf    = Cocoweb::Config->instance()->getConfigFile('request.conf');
        $conf_ref = $conf->all();
        foreach my $name ('urly0', 'urlprinc', 'current-url', 'avatar-url', 'avaref') {
            $conf->isString($name);
            debug("$name $conf_ref->{$name}" );
        }
        $agent_ref  = $conf->getHash('user-agent');
        my $uaConf     = Cocoweb::Config::Hash->new('hash' => $agent_ref);
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
       'url1'      => $conf_ref->{'urly0'} . ':' . $myport . '/'
    );
    debug("url1: " . $self->url1());  

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
    my ($self, $string) = @_;
    $string =~ s{([\x00-\x29\x2C\x3A-\x40\x5B-\x5E\x60\x7B-\x7F])}
    {'%' . uc(unpack('H2', $1))}eg;    # XXX JavaScript compatible
    $string = encode( 'ascii', $string, sub { sprintf '%%u%04X', $_[0] } );
    return $string;
}


1;
 


