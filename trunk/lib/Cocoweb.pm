# @created 2012-02-17
# @date 2012-02-18
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2012
# $Id$
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
package Cocoweb;

use strict;
use warnings;
use Carp;
use Cocoweb::Logger;

our $VERSION   = '0.2000';
our $AUTHORITY = 'TEST';
my $logger;

use base 'Exporter';
our @EXPORT = qw(
  error
  debug
  info
  message
);

sub info {
    $logger->info(@_);
}

sub message {
    $logger->message(@_);
}

sub error {
    $logger->error(@_);
}

sub debug {
    $logger->debug(@_);
}

sub BEGIN {
    $logger = Cocoweb::Logger->instance();
}

1;
