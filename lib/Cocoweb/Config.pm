# @author
# @created 2012-01-27 
# @date 2011-12-31
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
package Cocoweb::Config;
use base 'Cocoweb::Object::Singleton';
use Cocoweb;
use Cocoweb::Config::File;
use Carp;
use Config::General;
use Data::Dumper;
use strict;
use warnings;
 __PACKAGE__->attributes('pathnames');
my %instances;

sub init {
    my ($class, $instance) = @_;
    $instance->pathnames(['../conf', './conf', '/etc/cocoweb', $ENV{'HOME'} . '/.cocoweb']);
    return $instance;
}


sub getConfigFile {
    my ( $self, $filename ) = @_;
    return $instances{$filename} if exists $instances{$filename};
    croak error('Error: Required parameter "filename" is missing!') if !defined $filename; 
    my $pathnames_ref = $self->pathnames();

    my $configPath;
    foreach my $pathname ( @$pathnames_ref ) {
        my $path = $pathname . '/' . $filename;
        next if ! -f $path;
        $configPath = $path;
    }
    croak error("Error $filename filename was not found!") if !defined $configPath;
    debug("$configPath was found");

    my $instance = new Cocoweb::Config::File('pathname' => $configPath);
    return $instances{$filename} = $instance; 

}

1;
