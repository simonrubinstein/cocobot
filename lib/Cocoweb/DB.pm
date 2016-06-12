# @brief Handle SQLite database
# @created 2012-03-11
# @date 2012-04-25
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2012
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
package Cocoweb::DB;
use Cocoweb;
use base 'Cocoweb::Object::Singleton';
use Carp;
use FindBin qw($Script);
use DBI;
use Data::Dumper;
use Term::ANSIColor;
use strict;
use warnings;

#__PACKAGE__->attributes( 'dbh', 'filename', 'ISO3166Regex', 'town2id' );

##@method object init($class, $instance)
sub init {
    #my ( $class, $instance ) = @_;
    #my $config = Cocoweb::Config->instance()->getConfigFile('database.conf', 'File');
    #$instance->attributes_defaults(
    #    'dbh'          => undef,
    #    'filename'     => $config->getString('filename'),
    #    'ISO3166Regex' => $config->getString('ISO-3166-1-alpha-2'),
    #    'town2id'      => {}
    #);
    #return $instance;
    die "This class is no longer used";

}





1;

