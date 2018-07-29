# @created 2012-02-24
# @date 2107-07-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot 
#
# copyright (c) Simon Rubinstein 2010-2018
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
package Cocoweb::Config::Plaintext;
use strict;
use warnings;
use Cocoweb;
use Carp;
use Data::Dumper;
use IO::File;
use File::stat;

use Cocoweb;
use base 'Cocoweb::Object';

__PACKAGE__->attributes( 'all', 'pathname', 'mtime' );

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults(
        'all'      => {},
        'pathname' => $args{'pathname'},
        'mtime'    => 0
    );
    $self->readFile();
}

##@method void readFile()
#@brief Reads the configuration file.
#       If the configuration file has been modified it is read again.
sub readFile {
    my ($self) = @_;
    my $fh;
    my $filename = $self->pathname();
    my @file     = ();
    $fh = IO::File->new( $filename, 'r' );
    die error("open($filename) was failed: $!")
      if !defined $fh;
    my $stat = stat($fh);
    die error("stat($filename) was failed: $!")
      if !defined $stat;
    my $mtime = $stat->mtime();

    if ( $stat->mtime() == $self->mtime() ) {
        debug("The file $filename was not changed");
        close $fh;
        return 0;
    }
    $self->mtime( $stat->mtime() );
    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        next if substr( $line, 0, 1 ) eq '#' or $line =~ m{^\s*$};
        push @file, $line;
    }
    close $fh;
    $self->all( \@file );
    debug( $filename . ' file was read successfully' );
    return 1;
}

##@method arrayref getAll()
#@brief Returns the entire file read into an array.
#@return @array The file that was read in a array
#               with one line per element.
sub getAll {
    my ($self) = @_;
    return $self->all();
}

##@method hashref getAsHash()
#@brief Returns the entire file into a hash table.
#       Each line corresponds to a key.
#@return hashref The contents of the file in a hash table.
sub getAsHash {
    my ($self) = @_;
    $self->readFile();
    my $file_ref  = $self->all();
    my %hashtable = ();
    my %ctrl      = ();
    my $count     = 1;
    foreach my $line (@$file_ref) {
        $line =~ s{^\s+}{}g;
        $line =~ s{\s+$}{}g;
        die error("The key $line exists") if exists $hashtable{$line};
        $hashtable{$line} = $count;
        #my $check = lc($line);
        my $check = $line;
        die error("The key '$check' exists") if exists $ctrl{$check};
        $ctrl{$check} = 1;
        $count++;
    }
    return \%hashtable;
}

##@method string getRandomLine()
#@brief Returns a random line
#@return string A randomly chosen line in the file.
sub getRandomLine {
    my ($self)   = @_;
    my $file_ref = $self->all();
    my $i        = randum( scalar @$file_ref ) - 1;
    return $file_ref->[$i];
}

1;

