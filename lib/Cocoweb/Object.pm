# @brief Objects base class for Cocoweb, based on Dancer::Object 
# @created 2012-01-29
# @date 2012-01-29
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
use strict;
use warnings;
use Carp;
use Data::Dumper;

## @method object new()
sub new {
    my ( $class, %args ) = @_;
    my $self = \%args;
    $class = ref ($class) || $class;
    bless $self, $class;
    $self->init(%args);
    return $self;
}

## @method void init()
sub init { 1 }

# meta information about classes
my $_attrs_per_class = {};
sub get_attributes {
    my ($class, $visited_parents) = @_;
    # $visited_parents keeps track of parent classes we already handled, to
    # avoid infinite recursion (in case of dependancies loop). It's not stored as class singleton, otherwise
    # get_attributes wouldn't be re-entrant.
    $visited_parents ||= {};
    my @attributes = @{$_attrs_per_class->{$class} || [] };
    my @parents;
    { no strict 'refs';
      @parents = @{"$class\::ISA"}; }
    foreach my $parent (@parents) {
        # cleanup $parent
        $parent =~ s/'/::/g;
        $parent =~ /^::/
          and $parent = 'main' . $parent;

        # check we didn't visited it already
        $visited_parents->{$parent}++
          and next;

        # check it's a Dancer::Object
        $parent->isa(__PACKAGE__)
          or next;

        # merge parents attributes
        push @attributes, @{$parent->get_attributes($visited_parents)};
    }
    return \@attributes;
}

# accessor code for normal objects
# (overloaded in D::O::Singleton for instance)
sub _setter_code {
    my ($class, $attr) = @_;
    sub {
        my ($self, $value) = @_;
        if (@_ == 1) {
            return $self->{$attr};
        }
        else {
            return $self->{$attr} = $value;
        }
    };
}

# @method void attributes(@attributes)
# @brief Generates attributes for whatever object is
#        extending Cocoweb::Object and saves them in
#        an internal hashref so they can be later
#        fetched using get_attributes.
sub attributes {
    my ($class, @attributes) = @_;

    # save meta information
    $_attrs_per_class->{$class} = \@attributes;

    # define setters and getters for each attribute
    foreach my $attr (@attributes) {
        my $code = $class->_setter_code($attr);
        my $method = "${class}::${attr}";
        { no strict 'refs'; *$method = $code; }
    }
}

## @method void attributes_defaults(%defaults)
# @brief Given a hash (not a hashref), makes sure an object has the
#        given attributes default values. Usually called from within
#        an init function.
# @param %defaults hash
sub attributes_defaults {
    my ( $self, %defaults ) = @_;
    while ( my ( $k, $v ) = each %defaults ) {
        exists $self->{$k} or $self->{$k} = $v;
    }
}

1;
