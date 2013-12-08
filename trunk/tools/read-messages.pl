#!/usr/bin/perl
# @created 2013-11-11
# @date 2013-12-08
# @author Simon Rubinstein <ssimonrubinstein1@gmail.com>
# http://code.google.com/p/cocobot/
#
# copyright (c) Simon Rubinstein 2010-2013
# Id: $Id$
# Revision: $Revision$
# Date: $Date$
# Author: $Author$
# HeadURL: $HeadURL$
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
my $myTime;

init();
run();

sub run {

    my $messages_ref = readMessageFile($myTime);

    #print Dumper $messages_ref;

    my $alertMessages_ref = readAlertMessageFile($myTime);

    #print Dumper $alertMessages_ref;

    process( $messages_ref, $alertMessages_ref );

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
            . '%3s town: %-26s ISP: %-27s sex: %1s age: %2s nick: %-19s: '
            . $message . "\n",
        $message_ref->{'code'},  $message_ref->{'town'},
        $message_ref->{'ISP'},   $message_ref->{'mysex'},
        $message_ref->{'myage'}, $message_ref->{'mynickname'}
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
                . '                              ' . '   '
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
        if ($line !~ m{^(\d{2}):(\d{2}):(\d{2})
            \s+([A-Za-z0-9]{3})?
            \s+town:\s([A-Z]{2}-\s[A-Za-z-\s]*)?
            \s+ISP:\s([A-Za-z-\s\.]+)
            \s+sex:\s(\d)
            \s+age:\s(\d{2})
            \s+nick:\s([0-9A-Za-z]+)
            \s+:\s(.*)$}xms
            )
        {
            die "bad  $line";
        }
        my ( $h, $m, $s ) = ( $1, $2, $3 );
        my ( $code, $town, $ISP, $mysex, $myage, $mynickname, $message )
            = ( $4, $5, $6, $7, $8, $9, $10 );
        $town = '' if !defined $town;
        $code = '' if !defined $code;
        $ISP  = '' if !defined $code;
        my $_date = "$year-$month-$day $h:$m:$s";
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
            'ISP'              => trim($ISP),
            'mysex'            => $mysex,
            'myage'            => $myage,
            'message'          => $message
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
            \s+([0-9A-Za-z]+)
            \s+([A-Za-z0-9]{3})?
            \s+(.*)$}xms
            )
        {

            die "bad  $line";
        }
        my ( $h, $m, $s ) = ( $1, $2, $3 );
        my ( $botNickname, $mynickname, $code, $message )
            = ( $4, $5, $6, $7 );

        my $_date = "$year-$month-$day $h:$m:$s";
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
            'message'          => $message
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
    my $opt_ref = $CLI->getMinimumOpts( 'argumentative' => 't:' );
    if ( !defined $opt_ref ) {
        HELP_MESSAGE();
        exit;
    }
    $myTime = $opt_ref->{'t'} if exists $opt_ref->{'t'};
    if ( defined $myTime ) {
        if ( $myTime !~ m{^\d+$} ) {
            HELP_MESSAGE();
            exit;
        }
        $myTime = ( time - ( 86400 * $myTime ) );
    }
    else {
        $myTime = time;
    }
}

## @method void HELP_MESSAGE()
# Display help message
sub HELP_MESSAGE {
    print <<ENDTXT;
Usage: 
 $Script [-v -d ]
  -v          Verbose mode
  -d          Debug mode
  -t          1 = one day before, 2 = two days before, etc.
ENDTXT
    exit 0;
}

##@method void VERSION_MESSAGE()
#@brief Displays the version of the script
sub VERSION_MESSAGE {
    $CLI->VERSION_MESSAGE('2013-12-01');
}

