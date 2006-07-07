#!/usr/local/bin/perl
use lib qw[lib];
use strict;
use warnings;

use Email::Folder;
use Email::Thread;
use Mail::Thread;
use Benchmark qw[cmpthese timethese];

my $TIMES    = shift @ARGV;
my @messages = Email::Folder->new(@ARGV)->messages;

cmpthese(timethese($TIMES => {
    'Email-Thread' => \&ethread,
    'Mail-Thread'  => \&mthread,
}));

sub ethread {
    my $ethread = Email::Thread->new({ messages => \@messages });
    $ethread->thread;
    my $erootset = $ethread->rootset;
}

sub mthread {
    my $mthread = Mail::Thread->new(@messages);
    $mthread->thread;
    my $mrootset = [$mthread->rootset];
}
