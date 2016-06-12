# @created 2015-01-02
# @date 2015-01-09
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
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
use File::Basename;
use Data::Dumper;
use POSIX;
use FindBin qw($Script);
use IO::File;
use List::Util qw(shuffle);

use Cocoweb;
use Cocoweb::File;
use base 'Cocoweb::Object::Singleton';

__PACKAGE__->attributes( 'newDir', 'runDir', 'fileList', 'myavatarsList', 'myavatarsListIndex' );

##@method void init(%args)
sub init {
    my ( $class, $instance ) = @_;
    my $conf = Cocoweb::Config->instance()
        ->getConfigFile( 'myavatar.conf', 'File' );
    my $path   = getVarDir();
    my $newDir = $path . '/' . $conf->getString('new');
    my $runDir = $path . '/' . $conf->getString('run');
    my $listFilename = $path . '/' . $conf->getString('fileList');
    $instance->attributes_defaults(
        'newDir' => $newDir,
        'runDir' => $runDir,
        'fileList' => $listFilename,
        'myavatarsList' => undef,
        'myavatarsListIndex' => 0
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

##@method sting getAvatarPathname($baseDir, $myavatar, $mypass)
sub getAvatarPathname {
    my ( $self, $baseDir, $myavatar, $mypass ) = @_;
    return
          $baseDir . '/'
        . $self->myAvatar2Dirs($myavatar) . '/'
        . $myavatar
        . $mypass;
}

##@method void createNewFile($myavatar, $mypass)
sub createNewFile {
    my ( $self, $myavatar, $mypass ) = @_;
    croak Cocoweb::error("The value $mypass is a bad value for mypass")
        if $mypass !~ m{[A-Z]{20}};
    my $path
        = $self->getAvatarPathname( $self->newDir(), $myavatar, $mypass );
    my $dir = File::Basename::dirname($path);
    mkdirp($dir);
    croak Cocoweb::error("The file $path already exists") if -f $path;
    my $dateStr = timeToDate(time);
    $self->writeFile( $path, $dateStr, $dateStr, 1 );
}

##@method void moveNewToRun($myavatar, $mypass)
sub moveNewToRun {
    my ( $self, $myavatar, $mypass ) = @_;
    my $pathNew
        = $self->getAvatarPathname( $self->newDir(), $myavatar, $mypass );
    croak Cocoweb::error("The file $pathNew path was not found.")
        if !-f $pathNew;
    my $pathRun
        = $self->getAvatarPathname( $self->runDir(), $myavatar, $mypass );
    croak Cocoweb::error("The file $pathRun already exists") if -f $pathRun;
    mkdirp( File::Basename::dirname($pathRun) );
    croak Cocoweb::error("rename ($pathNew, $pathRun) return $!")
        if !rename( $pathNew, $pathRun );
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
        = $self->getAvatarPathname( $self->newDir(), $myavatar, $mypass );
    $self->updateFile($path);
}

##@method void updateRun($myavatar, $mypass)
sub updateRun {
    my ( $self, $myavatar, $mypass ) = @_;
    my $path
        = $self->getAvatarPathname( $self->runDir(), $myavatar, $mypass );
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

##@method array_ref getNew()
sub getNew {
    my ($self) = @_;
    return $self->getMyAvatars( $self->newDir() );
}

##@method array_ref getRun()
sub getRun {
    my ($self) = @_;
    return $self->getMyAvatars( $self->runDir() );
}

##@method array_ref getMyAvatars()
sub getMyAvatars {
    my ( $self, $path ) = @_;
    my @myavatars  = ();
    my $level1_ref = readDirectory($path);
    info("Read $path directory");
    foreach my $file1 (@$level1_ref) {
        next if $file1 eq '..' or $file1 eq '.';
        my $path2 = $path . '/' . $file1;
        next if !-d $path2;
        my $level2_ref = readDirectory($path2);
        foreach my $file2 (@$level2_ref) {
            next if $file2 eq '..' or $file2 eq '.';
            my $path3 = $path2 . '/' . $file2;
            next if !-d $path3;
            my $level3_ref = readDirectory($path3);
            foreach my $file3 (@$level3_ref) {
                next if $file3 eq '..' or $file3 eq '.';
                my $path4 = $path3 . '/' . $file3;
                next if !-d $path4;
                my $level4_ref = readDirectory($path4);
                foreach my $file4 (@$level4_ref) {
                    next if $file4 eq '..' or $file4 eq '.';
                    my $zepath = $path4 . '/' . $file4;
                    croak Cocoweb::error("$zepath if bad")
                        if $zepath !~ m{/(\d{9}[A-Z]{20})$};
                    push @myavatars, $1;
                }
            }
        }
    }
    info( "Number of myavatars in $path: " . scalar(@myavatars) );
    return \@myavatars;
}

#@method vois initList()
sub initList {
    my ($self) = @_;
    my $filename = $self->fileList();
    my $fh = IO::File->new( $filename, 'r' );
    confess Cocoweb::error("open($filename) was failed: $!")
        if !defined $fh;
    my @myavatarsList = ();
    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        push @myavatarsList, $line;
    }
    $fh->close();
    @myavatarsList = List::Util::shuffle @myavatarsList;
    $self->myavatarsList(\@myavatarsList);
    $self->myavatarsListIndex(0);
    croak Cocoweb::error("The list is empty.") if scalar (@myavatarsList) < 1;
}

##@method array getNextMyavatar()
sub getNextMyavatar {
    my ($self) = @_;
    my $myavatarsList_ref = $self->myavatarsList();
    croak Cocoweb::error("The list has not been initialized.")
        if !defined $myavatarsList_ref;
    my $count = scalar (@$myavatarsList_ref);
    my $index = $self->myavatarsListIndex();
    $index = 0 if $index >= $count;
    my $value = $myavatarsList_ref->[$index];
    $index++;
    $self->myavatarsListIndex($index);
    croak Cocoweb::error("$value if bad") if $value !~m{^(\d{9})([A-Z]{20})$};
    my ($myavatar, $mypass) = ($1, $2);
    debug("myavatar: $myavatar; mypass: $mypass");
    return ($myavatar, $mypass); 
}

1;
