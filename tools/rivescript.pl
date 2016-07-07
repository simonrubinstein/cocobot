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
use Cocoweb::RiveScript;
my $CLI;
my $rs;
my $isCheckAllAnswers;
my $maxFailsCheck;

init();
run();

sub run {
    $rs->loadDirectory('rivescript/replies');
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
    my $fileCounter = 0;
    my $errCount    = 0;
    my $okCount     = 0;
    my $totalCount  = 0;
    my $fh;

    my $regex = qr{^(\d{2}):(\d{2}):(\d{2})
                        \s+([A-Za-z0-9]{3})?
                        \s+town:\s([A-Z]{2}-\s[A-Za-z-\s]*)?
                        \s+ISP:\s([A-Za-z-\s\.\/\)\(,\{\}]+)?
                        \s+sex:\s(\d)
                        \s+age:\s(\d{2})
                        \s+nick:\s([0-9A-Za-z\(\)]+)
                        \s*:\s(.*)$}xms;
 

    FILELOOP:
    for my $file (@$files_ref) {
        next if $file !~ m{\.log$};
        my $filename = $path . '/' . $file;
        $fh = IO::File->new( $filename, 'r' );
        die error("open($filename) was failed: $!")
            if !defined $fh;
        my $lineCounter = 0;
        while ( defined( my $line = $fh->getline() ) ) {
            chomp($line);
            $lineCounter++;
            next if length($line) == 0;
            if ( $line !~ $regex ) {

                die "bad  $line ($filename)";
            }
            my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
                = ( $4, $5, $6, $7, $8, $9, $10 );
            next if $mysex eq 1 or $mysex eq 6;
            $totalCount++;
            my $reply = $rs->reply( "user", $message );

            if ( $reply eq 'ERR: No Reply Matched' ) {
                print "\n$mynickname> $message\n";
                print "Bot> $reply\n";
                $errCount++;
                last FILELOOP if $maxFailsCheck > 0 and $errCount >= $maxFailsCheck;
            } else {
                $okCount++;
            }
        }
        $fh->close();
        $fileCounter++;
        last;
    }

    $fh->close();
    print STDOUT "failures: $errCount; success: $okCount; total: $totalCount\n"; 
    return;
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
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 'cm:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $isCheckAllAnswers = $opt_ref->{'c'} if exists $opt_ref->{'c'};
    $maxFailsCheck     = $opt_ref->{'m'} if exists $opt_ref->{'m'};
    if ( defined $maxFailsCheck ) {
        if ( !defined $isCheckAllAnswers ) {
            error("The option m works only with the option c");
            return;
        }
        if ( $maxFailsCheck !~m{\d+} ) {
            error("The m option must be an integer");
            exit;
        }
    } else {
        $maxFailsCheck = 10 if defined $isCheckAllAnswers; 
    }

    # Create a new RiveScript interpreter object.
    $rs = new Cocoweb::RiveScript();
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
  -m  Maximum number of checks in failure.

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2016-07-03');
}

