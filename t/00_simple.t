#!/usr/bin/perl

# vim: set syntax=perl
use warnings;
use strict;

use Test::More tests => 6;

BEGIN {
    use_ok 'Mojolicious';
    use_ok 'IO::AIO';
    use_ok 'MojoX::AIO';
}

use Fcntl qw( O_RDONLY );
use FindBin;

use strict;
use warnings;

sub _start {
    my $file = $FindBin::Bin.'/../Makefile.PL';
    Test::More::pass("started, opening $file");

    aio_open( $file, O_RDONLY, 0, sub { open_done( $file, @_ ) });
}

sub open_done {
    my ( $file, $fh ) = @_;

    unless ( defined $fh ) {
        Test::More::fail("aio open failed on $file: $!");
        return;
    }

    Test::More::pass("opened $file, going to read");

    my $buffer = '';
    aio_read( $fh, 0, 1024, $buffer, 0, sub { read_done( $buffer, @_ ) } );
}

sub read_done {
    my ( $buffer, $bytes ) = @_;

    unless( $bytes > 0 ) {
        Test::More::fail("aio read failed: $!");
        return;
    }

    Test::More::pass("read file: $bytes bytes");

    Mojo::IOLoop->singleton->stop;
}

Mojo::IOLoop->singleton->timer( 1 => \&_start );

Mojo::IOLoop->singleton->start;

1;
