# @created 2012-02-17 
# @date 2012-02-17
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
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
package Cocoweb::Request;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Config;
use base 'Cocoweb::Object';
use Carp;
use LWP::UserAgent;
 
 __PACKAGE__->attributes('myport', 'url1');

my $hostname;
my $urly0;
my $urlprinc;
my $currentUrl;
my $avatarUrl;
my $avaref;


## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    if (!defined $hostname) {
        my $config  = Cocoweb::Config->instance();
        my $conf    = $config->getConfigFile('request.conf');
        $hostname   = $conf->getString('hostname');
        $urly0      = $conf->getString('urly0');
        $urlprinc   = $conf->getString('urlprinc');
        $currentUrl = $conf->getString('current-url');
        $avatarUrl  = $conf->getString('avatar-url');
        $avaref     = $conf->getString('avaref');
    }

    $self->attributes_defaults(
       'myport'    => 0, 
    );

}

1;
 


