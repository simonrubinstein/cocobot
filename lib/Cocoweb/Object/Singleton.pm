# @brief This class is a root class for singleton objects
#        It provides basic OO singleton tools for Perl5
#        It based on Dancer::Object::Singleton
# @created 2012-01-29
# @date 2012-01-30
# @author Alexis Sukrieh
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright 2009-2010 Alexis Sukrieh.
# copyright (c) Simon Rubinstein 2010-2012.
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
package Cocoweb::Object;
package Cocoweb::Object::Singleton;
use strict;
use warnings;
use Carp;
use base qw(Cocoweb::Object);

# Pool of instances (only one per package name)
my %instances;

# constructor
sub new {
    my ($class) = @_;
    die "you can't call 'new' on $class, as it's a singleton. Try to call 'instance'";
}

sub clone {
    my ($class) = @_;
    die "you can't call 'clone' on $class, as it's a singleton. Try to call 'instance'";
}

sub instance {
    my ($class) = @_;
    my $instance = $instances{$class};

    # if exists already
    defined $instance
      and return $instance;

    # create the instance
    $instance = bless {}, $class;
    $class->init($instance);

    # save and return it
    $instances{$class} = $instance;
    return $instance;
}

# accessor code for singleton objects
# (overloaded from Cocoweb::Object)
sub _setter_code {
    my ($class, $attr) = @_;
    sub {
        my ($class_or_instance, $value) = @_;
        my $instance = ref $class_or_instance ?
          $class_or_instance : $class_or_instance->instance;
        if (@_ == 1) {
            return $instance->{$attr};
        }
        else {
            return $instance->{$attr} = $value;
        }
    };
}

1;


