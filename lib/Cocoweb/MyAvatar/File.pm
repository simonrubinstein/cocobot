# @created 2015-01-02
# @date 2015-01-02
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2014
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
package Cocoweb::MyAvatar::File;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;
use FindBin qw($Script);
use IO::File;

use Cocoweb;
use Cocoweb::File;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes( 'newDir', 'runDir' );

##@method void init(%args)
sub init {
    my ( $class, $instance ) = @_;
    my $conf = Cocoweb::Config->instance()
        ->getConfigFile( 'myavatar.conf', 'File' );
    my $path   = getVarDir();
    my $newDir = $path . '/' . $conf->getString('new');
    my $runDir = $path . '/' . $conf->getString('run');
    $instance->attributes_defaults(
        'newDir' => $newDir,
        'runDir' => $runDir
    );
    mkdirp( $instance->newDir() );
    mkdirp( $instance->runDir() );
    return $instance;
}

##@method string myAvatar2Dirs($myavatar)
sub myAvatar2Dirs {
    my ( $self, $myavatar ) = @_;
    croak Cocoweb::error("$myavatar is bad")
        if $myavatar !~ m{^(\d{3})(\d{3})(\d{3})$};
    return "$1/$2/$3";
}

##@method void createNewFile($myavatar, $mypass)
sub createNewFile {
    my ( $self, $myavatar, $mypass ) = @_;
    croak Cocoweb::error("The value $mypass is a bad value for mypass") if $mypass !~m{[A-Z]{20}};
    my $path = $self->newDir() . '/' . $self->myAvatar2Dirs($myavatar);
    mkdirp($path);
    $path .= '/' . $myavatar . $mypass;
    croak Cocoweb::error("The file $path already exists") if -f $path;
    my $dateStr = timeToDate(time);
    $self->writeFile( $path, $dateStr, $dateStr, 1 );
}

##@method vois writeFile($filename, $creationDate, $updateDate, $counter)
sub writeFile {
    my ( $self, $filename, $creationDate, $updateDate, $counter ) = @_;
    my $fh = IO::File->new( $filename, 'w' );
    confess Cocoweb::error("open($filename) was failed: $!")
        if !defined $fh;
    print $fh <<ENDTXT;
$creationDate
$updateDate
$counter
ENDTXT
    confess Cocoweb::error("close() return $!") if !$fh->close();
    debug("The file $filename has been successfully written.");
}

##@method void updateNew($myavatar, $mypass)
sub updateNew {
    my ( $self, $myavatar, $mypass ) = @_;
    my $path
        = $self->newDir() . '/'
        . $self->myAvatar2Dirs($myavatar) . '/'
        . $myavatar
        . $mypass;
    $self->updateFile($path);
}

##@method void updateFile($filename)
sub updateFile {
    my ( $self, $filename ) = @_;
    my $fh = IO::File->new( $filename, 'r' );
    confess Cocoweb::error("open($filename) was failed: $!")
        if !defined $fh;
    my @values = ();
    my $count  = 0;
    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        push @values, $line;
        last if ++$count >= 3;
    }
    $fh->close();
    $self->writeFile( $filename, $values[0], timeToDate(time), ++$values[2] );
}

sub getNew {
    my ($self) = @_;
    return $self->getMyAvatars($self->newDir());
}

sub getMyAvatars {
    my ( $self, $path ) = @_;
    my @myavatars = ();
    my $level1_ref = readDirectory($path);
    info("Read $path directory");
    foreach my $file1 (@$level1_ref) {
        next if $file1 eq '..' or $file1 eq '.';
        my $path2 = $path . '/' . $file1;
        next if ! -d $path2;
        my $level2_ref = readDirectory($path2);
        foreach my $file2 (@$level2_ref) {
            next if $file2 eq '..' or $file2 eq '.';
            my $path3 = $path2 . '/' . $file2;
            next if ! -d $path3;
            my $level3_ref = readDirectory($path3);
            foreach my $file3 (@$level3_ref) {
                 next if $file3 eq '..' or $file3 eq '.';
                 my $path4 = $path3 . '/' . $file3;
                 next if ! -d $path4;
                 my $level4_ref = readDirectory($path4);
                 foreach my $file4 (@$level4_ref) {
                     next if $file4 eq '..' or $file4 eq '.';
                     my $zepath = $path4 . '/' . $file4;
                     croak Cocoweb::error("$zepath if bad") if $zepath!~m{/(\d{9}[A-Z]{20})$};
                     push @myavatars, $1;
                 }
            }
        }
    }
    info("Number of myavatars in $path: " . scalar(@myavatars) );
    return \@myavatars;
}




1;
