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
