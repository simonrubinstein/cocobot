# @created 2012-03-19
# @date 2012-03-19
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
package Cocoweb::User::Base;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use POSIX;

use Cocoweb;
use base 'Cocoweb::Object';

__PACKAGE__->attributes(
    ## A nickname from 4 to 16 characters.
    'mynickname',
    ## Age from 15 to 89 years.
    'myage',
    ## Sex: 1 = male or 2 = female.
    'mysex',
    ## nickname ID for current session
    'mynickID',
    ## Custom code that corresponds to zip code.
    'citydio',
    'mystat',
    'myXP',
    ## 4 = Premium Subscription
    'myver',
);
sub init {
    my ( $self, %args ) = @_;
}

##@method void display()
#@brief Prints on one line some member variables to the console of the user object
sub display {
    my $self  = shift;
    my @names = (
        'mynickname', 'myage',   'mysex',   
        'mynickID',  'citydio',  'mystat', 
        'myXP', 'myver'
    );
    foreach my $name (@names) {
        print STDOUT $name . ':' . $self->$name() . '; ';
    }
    print STDOUT "\n";

}
 
1;
 

