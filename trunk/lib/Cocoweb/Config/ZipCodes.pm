# @created 2012-04-28
# @date 2012-04-29
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# Id: $Id: Plaintext.pm 143 2012-03-16 20:52:38Z ssimonrubinstein1@gmail.com $
# Revision: $Revision: 143 $
# Date: $Date: 2012-03-16 21:52:38 +0100 (ven, 16 mar 2012) $
# Author: $Author: ssimonrubinstein1@gmail.com $
# HeadURL: $HeadURL: https://cocobot.googlecode.com/svn/trunk/lib/Cocoweb/Config/Plaintext.pm $
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
package Cocoweb::Config::ZipCodes;
use strict;
use warnings;
use Cocoweb;
use Cocoweb::Config::Plaintext;
use Carp;
use Data::Dumper;
use IO::File;
use File::stat;

use Cocoweb;
use base 'Cocoweb::Config::Plaintext';

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

##@method readFile()
sub readFile {
    my ($self) = @_;
    $self->SUPER::readFile();
    my $file_ref  = $self->all();
    my %hashtable = ();
    my %ctrl      = ();
    my $count     = 1;
    foreach my $line (@$file_ref) {
        $line =~ s{^\s+}{}g;
        $line =~ s{\s+$}{}g;
        die error("Bad line: $line") if $line !~ m{(^\d{5})\s+(.*)$};
        my ( $zip, $str ) = ( $1, $2 );
        $hashtable{$zip} = $str;
    }
    debug( scalar( keys %hashtable ) . ' zip codes were read' );
    $self->all( \%hashtable );
}

##@method string requestCityco($zip)
#@brief Performs an HTTP request to retrieve the zip custom code
#       and town corresponding to zip code.
#@param integer $zip A zip code (i.e. 75001)
#@return string cityco and town (i.e. '30915*PARIS*')
sub getCityco {
    my ( $self, $zip ) = @_;
    my $zip2Cityco = $self->all();
    die error( 'Error: cityco have not been found! Zip code: ' . $zip )
      if !exists $zip2Cityco->{$zip};
    return $zip2Cityco->{$zip};

}

1;
