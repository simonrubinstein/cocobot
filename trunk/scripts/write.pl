#!/usr/bin/perl
use strict;
use Data::Dumper;
use lib "../lib";
use Cocoweb;
use Cocoweb::Bot;

my $bot = Cocoweb::Bot->new('pseudonym' => 'Simon');

$bot->process();
$bot->writeMessage("Hello!", 263281);
$bot->show();

info("The script was completed successfully.");
