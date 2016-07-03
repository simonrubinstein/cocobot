#!/usr/bin/perl
# @created 2013-11-11
# @date 2016-07-02
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
use utf8;
no utf8;
use lib "../lib";
use Cocoweb;
use Cocoweb::CLI;
use Cocoweb::File;
my $CLI;

my $startTime;
my $lastTime;

init();
run();

sub run {

    for ( my $t = $startTime; $t <= $lastTime; $t += 86400 ) {
        print STDOUT ( "-" x 30 ) . ' ' . timeToDateOfDay($t) . "\n";
        my $messages_ref = readMessageFile($t);

        #print Dumper $messages_ref;
        my $alertMessages_ref = readAlertMessageFile($t);

        #print Dumper $alertMessages_ref;
        process( $messages_ref, $alertMessages_ref );
    }

}

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

        #last if $i > 70;

    }

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
        if ( !defined $alerts_ref->{'code'} ) {
            print Dumper $alerts_ref;
            exit;
        }
        next if $alerts_ref->{'code'} ne $code;
        next if $alerts_ref->{'hasBeenProcessed'};
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
        printf( $alerts_ref->{'date'}
                . " %-19s => "
                . '                              '
                . '                            '
                . "%-4s %-19s: $alerts_ref->{message}\n",
            $alerts_ref->{'botNickname'},
            $alerts_ref->{'code'}, $alerts_ref->{'mynickname'}
        );

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
            die "bad  $line ($messagePath)";
        }
        my ( $h, $m, $s ) = ( $1, $2, $3 );
        my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
            = ( $4, $5, $6, $7, $8, $9, $10 );
        $town = '' if !defined $town;
        $code = '' if !defined $code;
        $ISP  = '' if !defined $code;

        #my $_date = "$year-$month-$day $h:$m:$s";
        my $_date = "$h:$m:$s";
        my $_time = Date::Parse::str2time($_date);
        die "str2time($_date) was failed" if !defined $_time;

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
            \s+([A-Za-z0-9]{3})?
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

        push @messages,
            {
            'hasBeenProcessed' => 0,
            'time'             => $_time,
            'date'             => $_date,
            'botNickname'      => $botNickname,
            'mynickname'       => $mynickname,
            'code'             => $code,
            'message'          => trim($message)
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
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 't:s:l:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    my $myTime = $opt_ref->{'t'} if exists $opt_ref->{'t'};
    $startTime = $opt_ref->{'s'} if exists $opt_ref->{'s'};
    $lastTime  = $opt_ref->{'l'} if exists $opt_ref->{'l'};
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
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
$Script, read 'var/alert-messages/*' and 'var/messages/*' files 
Usage: 
 $Script [-v -d ] [-t daysBefore | -s startDate -l lastDate]
  -v            Verbose mode
  -d            Debug mode
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
    $CLI->VERSION_MESSAGE('2016-07-02');
}

