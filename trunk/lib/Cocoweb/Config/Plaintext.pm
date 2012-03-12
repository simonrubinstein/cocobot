# @created 2012-02-24
# @date 2012-03-12
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
package Cocoweb::Config::Plaintext;
use strict;
use warnings;
use Cocoweb;
use Carp;
use Data::Dumper;

use Cocoweb;
use base 'Cocoweb::Object';

__PACKAGE__->attributes( 'all', 'pathname' );

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults( 'pathname' => $args{'pathname'} );
    my $fh;
    my $filename = $self->pathname();
    my @file     = ();
    die sayError("open($filename) was failed: $!")
      if !open( $fh, '<', $filename );
    while ( my $line = <$fh> ) {
        chomp($line);
        next if substr($line, 0, 1) eq '#' or $line =~m{^\s*$};
        push @file, $line;
    }
    close $fh;
    $self->all( \@file );
}

##@method arrayref getAll()
#@brief Returns the entire file read into an array.
#@return @array The file that was read in a array
#               with one line per element.
sub getAll {
    my ($self) = @_;
    return $self->all();
}

sub getAsHash {
    my ($self) = @_;
    my $file_ref = $self->all();
    my %hashtable = ();
    my %ctrl      = ();
    my $count = 1;
    foreach my $line (@$file_ref) {
        $line =~s{^\s+}{}g;
        $line =~s{\s+$}{}g;
        die error("The key $line exists") if exists  $hashtable{$line};
        $hashtable{$line} = $count;
        $line = lc($line);
        die error("The key $line exists") if exists  $ctrl{$line};
        $ctrl{$line} = 1;
        $count++;
    }
    return \%hashtable;
}

##@method string getRandomLine()
#@brief Returns a random line
sub getRandomLine {
    my ($self)   = @_;
    my $file_ref = $self->all();
    my $i        = randum( scalar @$file_ref ) - 1;
    return $file_ref->[$i];
}

1;

