# @brief
# @created 2012-01-27
# @date 2012-03-31
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
package Cocoweb::Config;
use strict;
use warnings;
use FindBin qw($Script $Bin);
use base 'Cocoweb::Object::Singleton';
use Cocoweb;
use Cocoweb::Config::File;
use Cocoweb::Config::Plaintext;
use Carp;
use Config::General;
use Data::Dumper;
__PACKAGE__->attributes( 'pathnames', 'varDir' );
my %instances;

##@method object init($class, $instance)
sub init {
    my ( $class, $instance ) = @_;
    $instance->pathnames(
        [ '../conf', './conf', '/etc/cocoweb', $ENV{'HOME'} . '/.cocoweb' ] );
    $instance->varDir('');
    return $instance;
}

##@method object getConfigFile($class, $filename, $isPlaintext)
#@brief Creates and returns a configuration object.
#@param string $filename The file name to download.
#@param boolean $isPlaintext True if file is a plaintext file,
#                            or false if the file is a configuration
#                            file Apache like.
#@return object Cocoweb::Config::File or Cocoweb::Config::Plaintext objet
sub getConfigFile {
    my ( $self, $filename, $isPlaintext ) = @_;
    $isPlaintext = 0 if !defined $isPlaintext;
    return $instances{$filename} if exists $instances{$filename};
    croak error('Error: Required parameter "filename" is missing!')
      if !defined $filename;
    my $pathnames_ref = $self->pathnames();

    my $configPath;
    foreach my $pathname (@$pathnames_ref) {
        my $path = $pathname . '/' . $filename;
        next if !-f $path;
        $configPath = $path;
    }
    croak error("Error: $filename filename was not found!")
      if !defined $configPath;
    debug("The file '$configPath' was found.");
    my $instance;
    if ($isPlaintext) {
        $instance = new Cocoweb::Config::Plaintext( 'pathname' => $configPath );
    }
    else {
        $instance = new Cocoweb::Config::File( 'pathname' => $configPath );
    }
    return $instances{$filename} = $instance;
}

1;
