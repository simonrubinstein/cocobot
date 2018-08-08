#!/usr/bin/perl
# @created 2013-11-11
# @date 2018-08-08
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
use Cocoweb::Logger;
my $CLI;

my $startTime;
my $lastTime;
my $messagesRegex;
my $wantedCode;
my %messageCode2Maxtime = ();

init();
run();

##@method void run()
sub run {
    for ( my $t = $startTime; $t <= $lastTime; $t += 86400 ) {
        print STDOUT ( "-" x 30 ) . ' ' . timeToDateOfDay($t) . "\n";
        my $messages_ref      = readMessageFile($t);
        my $alertMessages_ref = readAlertMessageFile($t);
        process( $messages_ref, $alertMessages_ref );
        showNotDisplayed( $messages_ref, $alertMessages_ref );
    }
}

#@method void process()
sub process {
    my ( $messages_ref, $alertMessages_ref ) = @_;

    for ( my $i = 0; $i < scalar(@$messages_ref); $i++ ) {
        my $message_ref = $messages_ref->[$i];
        next if $message_ref->{'hasBeenProcessed'};

        #next
        #    if $message_ref->{'mysex'} eq '1'
        #    or $message_ref->{'mysex'} eq '6';

        $message_ref->{'hasBeenProcessed'} = 1;

        my $alertNextTime
            = searchAlertMessages( $message_ref, $alertMessages_ref );

        showMessage($message_ref);

        for ( my $j = $i + 1; $j < scalar(@$messages_ref); $j++ ) {
            my $next_ref = $messages_ref->[$j];
            next if $next_ref->{'hasBeenProcessed'};
            next
                if $next_ref->{'code'} ne $message_ref->{'code'}
                or $next_ref->{'mynickname'} ne $message_ref->{'mynickname'};
            next
                if $alertNextTime > 0
                and $next_ref->{'time'} >= $alertNextTime;
            $next_ref->{'hasBeenProcessed'} = 1;
            showMessage($next_ref);
        }

        searchRiveScriptMessages( $message_ref, $alertMessages_ref );

        #last if $i > 70;
    }

}

sub showNotDisplayed {
    my ( $message_ref, $alertMessages_ref ) = @_;
    print "=" x 72 . "\n";
    for ( my $i = 0; $i < scalar(@$alertMessages_ref); $i++ ) {
        my $alerts_ref = $alertMessages_ref->[$i];
        next if $alerts_ref->{'hasBeenProcessed'};
        next if !$alerts_ref->{'isRiveScript'};
        showAlert($alerts_ref);
    }
}

sub showAlert {
    my ($alerts_ref) = @_;
    printf( $alerts_ref->{'date'}
            . " %-19s => "
            . '                              '
            . '                            '
            . "%-4s %-19s: $alerts_ref->{message}\n",
        $alerts_ref->{'botNickname'},
        $alerts_ref->{'code'}, $alerts_ref->{'mynickname'}
    );
}

sub showMessage {
    my ($message_ref) = @_;
    my $message = $message_ref->{'message'};
    $message =~ s{=}{?}g;
    printf( $message_ref->{'date'} . ' '
            . '%3s town: %-26s ISP: %-22s sex: %1s age: %2s nick: %-19s: %s'
            . "\n",
        $message_ref->{'code'},  $message_ref->{'town'},
        $message_ref->{'ISP'},   $message_ref->{'mysex'},
        $message_ref->{'myage'}, $message_ref->{'mynickname'},
        $message
    );
}

sub searchAlertMessages {
    my ( $message_ref, $alertMessages_ref ) = @_;
    my $code       = $message_ref->{'code'};
    my $mynickname = $message_ref->{'mynickname'};
    my $_time      = $message_ref->{'time'};

    my @results  = ();
    my $maxtime  = 0;
    my $nextTime = 0;

    for ( my $i = 0; $i < scalar(@$alertMessages_ref); $i++ ) {
        my $alerts_ref = $alertMessages_ref->[$i];
        next if $alerts_ref->{'hasBeenProcessed'};
        if ( !defined $alerts_ref->{'code'} ) {
            print Dumper $alerts_ref;
            exit;
        }
        next if $alerts_ref->{'code'} ne $code;
        if ( $alerts_ref->{'time'} > $_time ) {
            $nextTime = $alerts_ref->{'time'} if $nextTime eq '0';
            next;

        }
        $maxtime = $alerts_ref->{'time'} if $alerts_ref->{'time'} > $maxtime;
        push @results, $alerts_ref;

    }

    print "\n";

    #print Dumper \@results;
    my $first = 0;
    foreach my $alerts_ref (@results) {
        next if $alerts_ref->{'time'} < ( $maxtime - 2 );

        #print "$alerts_ref->{time} >= $maxtime\n";
        $alerts_ref->{'hasBeenProcessed'} = 1;
        if ( !$first ) {
            $first = 1;
            next;
        }
        showAlert($alerts_ref);
    }
    return $nextTime;

}

sub searchRiveScriptMessages {
    my ( $message_ref, $alertMessages_ref ) = @_;
    my $code       = $message_ref->{'code'};
    my $mynickname = $message_ref->{'mynickname'};
    my $_time      = $message_ref->{'time'};

    my @results  = ();
    my $maxtime  = 0;
    my $nextTime = 0;

    for ( my $i = 0; $i < scalar(@$alertMessages_ref); $i++ ) {
        my $alerts_ref = $alertMessages_ref->[$i];
        next if $alerts_ref->{'hasBeenProcessed'};
        next if !$alerts_ref->{'isRiveScript'};
        if ( !defined $alerts_ref->{'code'} ) {
            print Dumper $alerts_ref;
            exit;
        }
        next if $alerts_ref->{'code'} ne $code;
        if ( $alerts_ref->{'time'} < $_time ) {

            #$nextTime = $alerts_ref->{'time'} if $nextTime eq '0';
            next;
        }

        $nextTime = $alerts_ref->{'time'} if $nextTime eq '0';
        $maxtime  = $alerts_ref->{'time'} if $alerts_ref->{'time'} > $maxtime;
        push @results, $alerts_ref;
        print "maxtime : $messageCode2Maxtime{$code} $alerts_ref->{'time'}\n";
        if ( exists $messageCode2Maxtime{$code}
            and $alerts_ref->{'time'} < $messageCode2Maxtime{$code} )
        {
            print "$alerts_ref->{time} < $messageCode2Maxtime{$code}\n";
            last;
        }
    }
    return $nextTime if scalar(@results) < 1;
    print "\n";

    #print Dumper \@results;
    foreach my $alerts_ref (@results) {

        #next if $alerts_ref->{'time'} < ( $maxtime - 2 );

        #print "$alerts_ref->{time} >= $maxtime\n";
        $alerts_ref->{'hasBeenProcessed'} = 1;
        showAlert($alerts_ref);
    }
    return $nextTime;
}

sub readMessageFile {
    my ($datetime) = @_;

    my ( $year, $month, $day ) = getYearMonthDay($datetime);

    my $messagePath;
    ( undef, $messagePath )
        = getLogPathname( 'messages', 'save-logged-user-in-database.pl',
        $datetime );
    debug("$messagePath");
    my @messages = ();
    my $fh = IO::File->new( $messagePath, 'r' );
    die error("open($messagePath) was failed: $!")
        if !defined $fh;

    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        next if $line =~ m{^\s*$};
        if ( $line !~ $messagesRegex ) {
            die "bad  $line ($messagePath)";
        }
        my ( $h, $m, $s ) = ( $1, $2, $3 );
        my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
            = ( $4, $5, $6, $7, $8, $9, $10 );
        $town = '' if !defined $town;
        $code = '' if !defined $code;
        $ISP  = '' if !defined $code;
        next if defined $wantedCode and $wantedCode ne $code;

        #my $_date = "$year-$month-$day $h:$m:$s";
        my $_date = "$h:$m:$s";
        my $_time = Date::Parse::str2time($_date);
        die "str2time($_date) was failed" if !defined $_time;

        if ( defined $code ) {
            $messageCode2Maxtime{$code} = $_time
                if !exists $messageCode2Maxtime{$code}
                or $_time > $messageCode2Maxtime{$code};
        }

        push @messages,
            {
            'hasBeenProcessed' => 0,
            'time'             => $_time,
            'date'             => $_date,
            'mynickname'       => $mynickname,
            'code'             => $code,
            'town'             => trim($town),
            'ISP'              => substr( trim($ISP), 0, 22 ),
            'mysex'            => $mysex,
            'myage'            => $myage,
            'message'          => trim($message)
            };

        # my $str
        #     = sprintf(
        #     '%3s town: %-26s ISP: %-27s sex: %1s age: %2s nick: %-19s: '
        #         . $message,
        #     $code, $town, $ISP, $mysex, $myage, $mynickname );
        #print $line . "\n";
        #print "$h:$m:$s $str\n\n";
    }
    close $fh;
    return \@messages;
}

sub readAlertMessageFile {
    my ($datetime) = @_;

    my @dt = localtime($datetime);
    my ( $year, $month, $day ) = getYearMonthDay($datetime);

    my $alertMessagePath;
    ( undef, $alertMessagePath )
        = getLogPathname( 'alert-messages', 'save-logged-user-in-database.pl',
        $datetime );
    debug("$alertMessagePath");

    my @messages = ();
    my $fh = IO::File->new( $alertMessagePath, 'r' );
    if ( !defined $fh ) {
        error("open($alertMessagePath) was failed: $!");
        return \@messages;
    }
    while ( defined( my $line = $fh->getline() ) ) {
        chomp($line);
        if ($line !~ m{^(\d{2}):(\d{2}):(\d{2})
            \s+([0-9A-Za-z]+)
            \s+=>
            \s+([0-9A-Za-z:]+)
            \s+([A-Za-z0-9\(\)\*\+:=\-\!]{3})?
            \s+(.*)$}xms
            )
        {

            die "bad '$line'";
        }
        my ( $h, $m, $s ) = ( $1, $2, $3 );
        my ( $botNickname, $mynickname, $code, $message )
            = ( $4, $5, $6, $7 );

        #my $_date = "$year-$month-$day $h:$m:$s";
        my $_date = "$h:$m:$s";
        my $_time = Date::Parse::str2time($_date);
        die "str2time($_date) was failed" if !defined $_time;
        $code = '' if !defined $code;
        next if defined $wantedCode and $wantedCode ne $code;
        my $isRiveScriptMessage;
        if ( $message =~ m{^Cocoweb::Alert::RiveScript\s(.*)$} ) {
            $isRiveScriptMessage = 1;
            $message             = "[$1]";
        }
        else {
            $isRiveScriptMessage = 0;
        }
        push @messages,
            {
            'hasBeenProcessed' => 0,
            'time'             => $_time,
            'date'             => $_date,
            'botNickname'      => $botNickname,
            'mynickname'       => $mynickname,
            'code'             => $code,
            'message'          => trim($message),
            'isRiveScript'     => $isRiveScriptMessage
            };

        #printf( "$h:$m:$s %-19s => %-19s %-4s $message\n",
        #    $botNickname, $mynickname, $code );
        #print "$line\n\n";
    }
    close $fh;
    return \@messages;
}

sub getYearMonthDay {
    my ($datetime) = @_;
    my @dt = localtime($datetime);
    return (
        ( $dt[5] + 1900 ),
        sprintf( '%02d', ( $dt[4] + 1 ) ),
        sprintf( '%02d', $dt[3] )
    );
}

## @method void init()
sub init {
    $CLI = Cocoweb::CLI->instance();
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 't:s:l:c:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    my $myTime = $opt_ref->{'t'} if exists $opt_ref->{'t'};
    $startTime  = $opt_ref->{'s'} if exists $opt_ref->{'s'};
    $lastTime   = $opt_ref->{'l'} if exists $opt_ref->{'l'};
    $wantedCode = $opt_ref->{'c'} if exists $opt_ref->{'c'};
    if ( defined $myTime ) {
        if ( defined $startTime or defined $lastTime ) {
            error("The -t and the -s/-l options are mutually exclusive.");
            HELP_MESSAGE();
            exit;
        }
        if ( $myTime !~ m{^\d+$} ) {
            error("The -t and the -s/-l options are mutually exclusive.");
            HELP_MESSAGE();
            exit;
        }
        $myTime = ( time - ( 86400 * $myTime ) );
        $startTime = $lastTime = $myTime;
    }
    else {
        if ( !defined $startTime and !defined $lastTime ) {
            $startTime = $lastTime = time;
        }
        else {
            if ( !defined $startTime ) {
                error("You must specify a start date.");
                HELP_MESSAGE();
                exit;
            }
            $myTime = Date::Parse::str2time($startTime);
            die error("str2time($startTime) was failed") if !defined $myTime;
            $startTime = $myTime;
            if ( defined $lastTime ) {
                $myTime = Date::Parse::str2time($lastTime);
                die error("str2time($lastTime) was failed")
                    if !defined $myTime;
                $lastTime = $myTime;
            }
            else {
                $lastTime = time - 86400;
            }
            if ( $startTime > $lastTime ) {
                error("The start date is after the end date");
                HELP_MESSAGE();
                exit;
            }

        }
    }
    my $logger = Cocoweb::Logger->instance();
    $messagesRegex = $logger->getMessagesLogRegex();
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, read 'var/alert-messages/*' and 'var/messages/*' files 
Usage: 
 $Script [-v -d ] [-t daysBefore | -s startDate -l lastDate] [-c code]
  -v            Verbose mode
  -d            Debug mode
  -c code       The nickname code searched, an alphanumeric code
                of three characters, i.e. WcL
  -s startDate  The date of the first file to be processed.
  -l lastDate   The date of the last file to be processed.
  -t daysBefore The number of days before today. 
                1 = one day before, 2 = two days before, etc.
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2018-08-08');
}

