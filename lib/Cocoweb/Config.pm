# @brief
# @created 2012-01-27
# @date 2016-07-02
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
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

##@method string getDirPath(filename)
#@brief Return full pathname of configuration file
#@param string $filename A filename
#@return string A full file pathanme
sub getFilePath {
    my ( $self, $filename ) = @_;
    croak error('Error: Required parameter "filename" is missing!')
        if !defined $filename;
    my $filepath;
    my $pathnames_ref = $self->pathnames();
    foreach my $pathname (@$pathnames_ref) {
        my $path = $pathname . '/' . $filename;
        next if !-f $path;
        $filepath = $path;
    }
    croak error("Error: $filename filename was not found!")
        if !defined $filepath;
    return $filepath;
}

##@method string getDirPath(filename)
#@brief Return full pathname of configuration dir
#@param string $dirname A dirname
#@return string A full dir pathanme
sub getDirPath {
    my ( $self, $dirname ) = @_;
    croak error('Error: Required parameter "dirname" is missing!')
        if !defined $dirname;
    my $dirpath;
    my $pathnames_ref = $self->pathnames();
    foreach my $pathname (@$pathnames_ref) {
        my $path = $pathname . '/' . $dirname;
        next if !-d $path;
        $dirpath = $path;
    }
    croak error("Error: $dirname dirname was not found!")
        if !defined $dirpath;
    return $dirpath;
}

##@method object getConfigFile($class, $filename, $isPlaintext)
#@brief Creates and returns a configuration object.
#@param string $filename   The file name to download.
#@param boolean $className Class handle the configuration file
#                          File for file Apache like,
#                          PlainText for plain text file
#@return object Cocoweb::Config::File or Cocoweb::Config::Plaintext objet
sub getConfigFile {
    my ( $self, $filename, $className ) = @_;
    $className = 'File' if !defined $className;
    return $instances{$filename} if exists $instances{$filename};
    croak error('Error: Required parameter "filename" is missing!')
        if !defined $filename;
    my $configPath = $self->getFilePath($filename);
    debug("The file '$configPath' was found.");
    $className = 'Cocoweb::Config::' . $className;
    my $classPathName = $className;
    $classPathName =~ s{::}{/}g;
    require $classPathName . '.pm';
    my $instance = $className->new( 'pathname' => $configPath );
    return $instances{$filename} = $instance;
}

1;
