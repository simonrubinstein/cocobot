#!/usr/bin/perl
# @created 2016-07-02 
# @date 2016-07-03
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
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
use strict;
use warnings;
use Date::Parse;
use FindBin qw($Script $Bin);
use Data::Dumper;
use RiveScript;
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
my $CLI;
my $rs;
my $isCheckAllAnswers;

init();
run();

sub run {
    my $dirpath
        = Cocoweb::Config->instance()->getDirPath('rivescript/replies');
    $rs->loadDirectory($dirpath);
    $rs->sortReplies();
    if ( !defined $isCheckAllAnswers ) {
        bot();
    }
    else {
        checkAllAnswers();
    }
}

sub checkAllAnswers {
    my $path      = getVarDir() . '/messages';
    my $files_ref = readDirectory($path);
    for my $file (@$files_ref) {
        next if $file !~ m{\.log$};
        my $filename = $path . '/' . $file;
        my $fh = IO::File->new( $filename, 'r' );
        die error("open($filename) was failed: $!")
            if !defined $fh;
        while ( defined( my $line = $fh->getline() ) ) {
            chomp($line);
            next if length($line) == 0;
            if ($line !~ m{^(\d{2}):(\d{2}):(\d{2})
                        \s+([A-Za-z0-9]{3})?
                        \s+town:\s([A-Z]{2}-\s[A-Za-z-\s]*)?
                        \s+ISP:\s([A-Za-z-\s\.\/\)\(,\{\}]+)?
                        \s+sex:\s(\d)
                        \s+age:\s(\d{2})
                        \s+nick:\s([0-9A-Za-z\(\)]+)
                        \s*:\s(.*)$}xms
                )
            {
                die "bad  $line ($filename)";
            }
            my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
                = ( $4, $5, $6, $7, $8, $9, $10 );
            next if $mysex eq 1 or $mysex eq 6;
            $message = unacString($message);
            print "\nYou> $message\n";
            my $reply = $rs->reply( "user", $message );
            utf8::encode($reply);
            print "Bot> $reply\n";

            if ( $reply eq 'ERR: No Reply Matched' ) {

                #$fh->close();
                #return;
            }

        }
        $fh->close();
        last;
    }

}

sub bot {
    while (1) {
        print "You> ";
        chomp( my $message = <STDIN> );

        # Let the user type "/quit" to quit.
        if ( $message eq "/quit" ) {
            exit(0);
        }

        # Fetch a reply from the bot.
        my $reply = $rs->reply( "user", $message );
        utf8::encode($reply);
        print "Bot> $reply\n";
    }

}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 'c' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $isCheckAllAnswers = $opt_ref->{'c'} if exists $opt_ref->{'c'};

    # Create a new RiveScript interpreter object.
    $rs = RiveScript->new( 'utf8' => 1, 'debug' => 0 );
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, RiveScript chatbot 
Usage: 
 $Script [-v -d -c]
  -v  Verbose mode
  -d  Debug mode
  -c  Check all the answers from the files.

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-07-03');
}

