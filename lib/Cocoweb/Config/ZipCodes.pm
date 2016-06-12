# @created 2012-04-28
# @date 2014-03-06 
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

__PACKAGE__->attributes('citydio2zip');

## @method void init($args)
sub init {
    my ( $self, %args ) = @_;
    $self->attributes_defaults(
        'all'         => {},
        'pathname'    => $args{'pathname'},
        'mtime'       => 0,
        'citydio2zip' => {}
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
    my $zip2Cityco_ref = $self->all();
    die error( 'Error: cityco have not been found! Zip code: ' . $zip )
      if !exists $zip2Cityco_ref->{$zip};
    return $zip2Cityco_ref->{$zip};
}

##@method string getZipRandom()
#@brief Returns a random zip code 
#@return integer $zip A zip code (i.e. 75018)
sub getZipRandom {
    my ($self) = @_;
    my $zip2Cityco_ref = $self->all();
    my @zipCodes = keys %$zip2Cityco_ref;
    my $i        = randum( scalar @zipCodes ) - 1;
    my $zipCode = $zipCodes[$i];
    return $zipCode; 
}

##@method void extract()
#@brief Builds a hash table citydio => zip code and townzz
sub extract {
    my ($self) = @_;
    my $citydio2zip_ref = $self->citydio2zip();
    return if scalar( keys %$citydio2zip_ref ) > 0;
    my $zip2Cityco_ref = $self->all();
    foreach my $zip ( keys %$zip2Cityco_ref ) {
        my $cityco = $zip2Cityco_ref->{$zip};
        my @citycoList = split( /\*/, $cityco );
        my ( $citydio, $townzz );
        my $count = scalar @citycoList;
        die error("Error: The cityco is not valid (cityco: $cityco)")
          if $count % 2 != 0
              or $count == 0;
        for ( my $i = 0 ; $i < scalar(@citycoList) ; $i += 2 ) {
            my $citydio = $citycoList[$i];
            my $townzz  = $citycoList[ $i + 1 ];
            die error( 'Error: the ' . $citydio . ' citydio already exists!' )
              if exists $citydio2zip_ref->{$citydio};
            $townzz = lc($townzz);
            $townzz =~ s{\b(\w+)\b}{ucfirst($1)}ge;
            $citydio2zip_ref->{$citydio} = $zip . ' ' . $townzz;
        }
    }
    debug( 'Extract ' . scalar( keys %$citydio2zip_ref ) . ' citydio' );
}

##@method string getZipAndTownFromCitydio($citydio)
#@brief Returns the zip code and town name that matches the code citydio.
#@param integer $citydio A citydio (i.e. 30919)
#@return string zip code and town name (i.e. '75005 Paris')
sub getZipAndTownFromCitydio {
    my ( $self, $citydio ) = @_;
    $self->extract();
    my $citydio2zip_ref = $self->citydio2zip();
    if ( !exists $citydio2zip_ref->{$citydio} ) {
        error( 'The code ' . $citydio . ' has not been found.' );
        return $citydio . '?';
    }
    return $citydio2zip_ref->{$citydio};
}

1;
