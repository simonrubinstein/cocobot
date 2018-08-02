#!/usr/bin/perl
# @created 2016-07-02
# @date  2018-08-02
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# https://github.com/simonrubinstein/cocobot
#
# copyright (c) Simon Rubinstein 2010-2018
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
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
use Cocoweb::RiveScript;
use Cocoweb::Logger;
my $CLI;
my $rs;
my $isCheckAllAnswers;
my $maxFailsCheck;
my $riveScriptDir;
my $filenameFilter;
my $isReplyAll     = 1;
my $matchReply_ref = {};
my $matchReplyFilename;
my $onlyMan   = 0;
my $onlyWoman = 0;

init();
run();

sub run {
    $rs->loadDirectory($riveScriptDir);
    $rs->sortReplies();
    if ( !defined $isCheckAllAnswers ) {
        bot();
    }
    else {
        checkAllAnswers();
    }
}

##@method void checkAllAnswers()
sub checkAllAnswers {
    my $path        = getVarDir() . '/messages';
    my $files_ref   = readDirectory($path);
    my $fileCounter = 0;
    my $errCount    = 0;
    my $okCount     = 0;
    my $totalCount  = 0;
    my $fh;
    my $logger = Cocoweb::Logger->instance();
    my $regex  = $logger->getMessagesLogRegex();

    my %message2count = ();

FILELOOP:
    for my $file (@$files_ref) {
        next if $file !~ m{\.log$};
        next if defined $filenameFilter and $file !~ $filenameFilter;
        my $filename = $path . '/' . $file;
        $fh = IO::File->new( $filename, 'r' );
        debug("open $filename file");
        die error("open($filename) was failed: $!")
            if !defined $fh;
        my $lineCounter = 0;
        while ( defined( my $line = $fh->getline() ) ) {
            chomp($line);
            $lineCounter++;
            next if length($line) == 0;
            if ( $line !~ $regex ) {
                die "bad line $lineCounter: $line ($filename)";
            }
            my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
                = ( $4, $5, $6, $7, $8, $9, $10 );
            if ($onlyWoman) {
                next if $mysex eq 1 or $mysex eq 6;
            }
            elsif ($onlyMan) {
                next if $mysex eq 2 or $mysex eq 7;
            }
            if ($isReplyAll) {
                $totalCount++;
                my $reply = $rs->reply( "user", $message );
                if ( $reply eq 'ERR: No Reply Matched' ) {
                    print "\n$mynickname> $message\n";
                    print "Bot> $reply\n";
                    $errCount++;
                    last FILELOOP
                        if $maxFailsCheck > 0 and $errCount >= $maxFailsCheck;
                }
                else {
                    info("\n$mynickname> $message");
                    info("Bot> $reply");
                    $okCount++;
                }
            }
            else {
                #next if $message !~m{je sais pas};
                if ( $message !~ m{^http://www\.coco.fr/pub/photo0?\.htm.*} )
                {
                    $message =~ s{[,?!\.\;]+}{}g;
                    $message =~ s{'}{ }g;
                    $message =~ s{\s+}{ }g;
                    $message = trim($message);
                    $message = lc($message);
                    $message = $rs->unacString($message);
                }
                next if length($message) == 0;

                #print "<$message>\n";
                $message2count{$message}++;
                next;

                my $offsetMax = length($message) - 1;
                for my $offset ( 0 .. $offsetMax ) {
                    my $chr = substr( $message, $offset, 1 );
                    print "<$chr> : " . ord($chr) . "\n";
                }

            }
        }
        $fh->close();
        undef $fh;
        $fileCounter++;

        #last;
    }

    $fh->close() if defined $fh;
    if ($isReplyAll) {
        print STDOUT
            "failures: $errCount; success: $okCount; total: $totalCount\n";
    }
    else {
        eval { $matchReply_ref = deserializeHash($matchReplyFilename); };
        foreach my $message (
            sort { $message2count{$a} <=> $message2count{$b} }
            keys %message2count
            )
        {
            my $count = $message2count{$message};
            if ( exists $matchReply_ref->{$message} ) {
                $okCount++;
                next;
            }
            my $reply = $rs->reply( "user", $message );
            $totalCount++;
            if ( $reply ne 'ERR: No Reply Matched' ) {
                $okCount++;
                $matchReply_ref->{$message} = 1;
                next;
            }
            $errCount++;
            print "$count: $message \n";

            #print "\nYou> $message\n";
            #print "Bot> $reply\n";
        }
        print STDOUT
            "failures: $errCount; success: $okCount; total: $totalCount\n";
        serializeData( $matchReply_ref, $matchReplyFilename );
    }

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
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 'cm:V:f:aWM' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $isCheckAllAnswers = $opt_ref->{'c'} if exists $opt_ref->{'c'};
    $maxFailsCheck     = $opt_ref->{'m'} if exists $opt_ref->{'m'};
    $riveScriptDir     = $opt_ref->{'V'} if exists $opt_ref->{'V'};
    $filenameFilter    = $opt_ref->{'f'} if exists $opt_ref->{'f'};
    $isReplyAll        = 0               if exists $opt_ref->{'a'};
    $onlyMan           = 1               if exists $opt_ref->{'M'};
    $onlyWoman         = 1               if exists $opt_ref->{'W'};

    if ( defined $maxFailsCheck ) {
        if ( !defined $isCheckAllAnswers ) {
            error("The option m works only with the option c");
            return;
        }
        if ( $maxFailsCheck !~ m{\d+} ) {
            error("The m option must be an integer");
            exit;
        }
    }
    else {
        $maxFailsCheck = 10 if defined $isCheckAllAnswers;
    }
    $riveScriptDir  = 'rivescript/replies' if !defined $riveScriptDir;
    $filenameFilter = qr/$filenameFilter/  if defined $filenameFilter;

    # Create a new RiveScript interpreter object.
    $rs = new Cocoweb::RiveScript( 'debug' => $Cocoweb::isDebug );

    $matchReplyFilename = getVarDir() . '/matchReplies.data';
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, RiveScript chatbot 
Usage: 
 $Script [-v -d -c -V directory -f filter -a]
  -v            Verbose mode
  -d            Debug mode
  -c            Check all the answers from the files.
  -m            Maximum number of checks in failure.
  -V directory  RiveScript directory
  -f filter     Filename filter
  -a            Done statistics on messages.
  -W            Only the answers of women.
  -M            Only the answers of man.

Exemples:
$Script
$Script -d
$Script -c
$Script -c -m 20
$Script -c -V rivescript/woman-replies
$Script -c -V rivescript/woman-replies -f bot-test.pl.log
$Script -c -V rivescript/woman-replies -f 2016-07-18 -a -v -d
$Script -v -c -m 20 -V rivescript/checks-womens-with-man-names -f checks-womens-with-man-names
$Script -c -V rivescript/checks-womens-with-man-names -f 2018-08-02_checks-womens-with-man-names  -m 300

ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2018-08-02');
}

