# @created 2012-03-30
# @date 2012-04-09
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
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
package Cocoweb::File;
use strict;
use warnings;
use FindBin qw($Script $Bin);
use Carp;
use Data::Dumper;
use File::stat;
use File::Temp;
use IO::File;
use base 'Exporter';
my $varDir;

our @EXPORT = qw(
  deserializeHash
  dumpToFile
  fileToVars
  getVarDir
  serializeData
);
use Cocoweb;

##@method array getFileTemp($filename, $open)
#@brief Generates a temporary filename.
#@param string  $filename A filename
#@param boolean 0 does not open the file
sub getFileTemp {
    my ($filename, $open) = @_;
    $open = 1 if !defined $open;
    my @args = ( 'UNLINK' => 0, 'OPEN' => $open );
    my ( $template, $suffix );
    if ( $Script =~ m{^([^.]+)(\..+)}xms ) {
        $template = $1 . '_';
        $suffix   = $2;
    }
    else {
        $template = $Script . '_';
    }
    if ( $filename =~ m{^(.+)/([^/]+)$} ) {
        push @args, 'DIR', $1;
        $template .= $2;
    }
    else {
        $template .= $filename;
    }
    if ( $template =~ m{^(.+)(\..+)$} ) {
        $template = $1;
        $suffix   = $2;
    }
    else {
        $suffix = '.pl' if !defined $suffix;
    }
    $template .= '_XXXXXXXXXXXXXX';
    push @args, 'TEMPLATE', $template, 'SUFFIX', $suffix;
    my $fh          = File::Temp->new(@args);
    my $tmpFilename = $fh->filename();
    debug(  'filename: '
          . $filename
          . '; template: '
          . $template
          . '; tmpFilename: '
          . $tmpFilename );
    if ($open) {
        return ($tmpFilename, $fh);
    } else {
        return $tmpFilename;
    }
}

##@method void serializeData($data, $filename)
#@brief Serialize Perl data structure in a file
#@param hashref $data The data to be serialized
#@param string filename A full pathname of a file
sub serializeData {
    my ( $data, $filename ) = @_;
    my $tmpFilename = getFileTemp($filename, 0);  
    my $res;
    eval {
        $res = Storable::store($data, $tmpFilename);
    };
    croak error("Storable::store($filename) was failed! $! / $@")
        if !defined $res or $@; 
    croak error("rename($tmpFilename, $filename) was failed: $!")
      if !rename( $tmpFilename, $filename );
    debug($filename . ' file successfully serialized');
}

##@method hashref deserializeHash($filename)
#@param string filename A full pathname of a file
#@return hashref The hash contained in the file
sub deserializeHash {
    my ($filename) = @_;
    my $data = \%{Storable::retrieve ($filename)};
    return $data;
}

##@method void dumpToFile($vars, $filename)
#@brief Save a Perl data structure into a file
#@param hashref $vars     A reference to a Perl structure:
#                         an array or a hash table
#@param string  $filename A filename
sub dumpToFile {
    my ( $vars, $filename ) = @_;
    my ($tmpFilename, $fh) = getFileTemp($filename, 1);  
    $Data::Dumper::Purity = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse  = 1;
    print $fh Dumper $vars;
    croak error("close($filename) was failed: $!") if !close($fh);
    croak error("rename($tmpFilename, $filename) was failed: $!")
      if !rename( $tmpFilename, $filename );
}

##@method void fileToVars($filename)
#@param string filename A full pathname of a file
sub fileToVars {
    my ($filename) = @_;
    my $stat = stat($filename);
    croak error("stat($filename) was failed: $!") if !defined $stat;
    my $fh;
    croak error("open($filename) was failed: $!") if !open( $fh, '<', $filename );
    my ( $contentSize, $content ) = ( 0, '' );
    sysread( $fh, $content, $stat->size(), $contentSize );
    close $fh;
    my $vars = eval($content);
    croak error($@) if $@;
    return $vars;
}

##@method string getVarDir()
sub getVarDir {
    return $varDir if defined $varDir; 
    $varDir = $Bin;
    $varDir =~ s{/[^/]+$}{/var};
    confess error("$varDir directory was not found") if !-d $varDir;
    return $varDir;
}




 
