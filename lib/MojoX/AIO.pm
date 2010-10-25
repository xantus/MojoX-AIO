package MojoX::AIO;

use Mojo::IOLoop;

use IO::AIO qw( poll_fileno poll_cb );

use strict;
use warnings;
use Carp qw( croak );

our $VERSION = '0.01';

use vars qw( $singleton );

sub import {
    my ( $class, $args ) = @_;
    my $package = caller();

    croak "MojoX::AIO expects its arguments in a hash ref"
        if ( $args && ref( $args ) ne 'HASH' );

    unless ( delete $args->{no_auto_export} ) {
        eval( "package $package; use IO::AIO qw( 2 );" );
        if ( $@ ) {
            croak "could not export IO::AIO into $package (is it installed?)";
        }
    }

    return if ( $args->{no_auto_bootstrap} );

    # bootstrap
    MojoX::AIO->new( %$args );

    return;
}

sub new {
    my $class = shift;
    return $singleton if ( $singleton );

    my $self = $singleton = bless({
        @_
    }, ref $class || $class );

    my $fd = poll_fileno();
    open( my $fh, "<&=$fd" ) or die "Can't open IO::AIO poll_fileno - $fd : $!";

    my $id = $self->{_id} = "$fh";

    Mojo::IOLoop->singleton->{_fds}->{ $fd } = $id;
    Mojo::IOLoop->singleton->{_cs}->{ $id } = {
        socket => $fh
    };
    Mojo::IOLoop->singleton->on_read( $id, \&poll_cb );
    Mojo::IOLoop->singleton->on_error( $id, sub {
        # XXX
        warn "MojoX::AIO error! @_\n";
    });
    Mojo::IOLoop->singleton->_not_writing( $id );

    return $self;
}

sub singleton() {
    $singleton;
}

1;

__END__

=head1 NAME

MojoX::AIO - Asynchronous File I/O for Mojolicious

=head1 SYNOPSIS

  use Mojo::IOLoop;
  use MojoX::AIO;
  use Fcntl qw( O_RDONLY );

  aio_open( '/etc/passwd', O_RDONLY, 0, sub {
      my $fh = shift;
      my $buffer = '';
      aio_read( $fh, 0, 1024, $buffer, 0, sub {
          my $bytes = shift;
          warn "read bytes: $bytes data: $buffer\n";
          Mojo::IOLoop->singleton->stop;
      });
  });

  Mojo::IOLoop->singleton->start;

=head1 DESCRIPTION

 This component adds support for L<IO::AIO> use with L<Mojolicious>

=head1 NOTES

This module automaticly bootstraps itself on use.

=head1 SEE ALSO

L<IO::AIO>, L<Mojolicious>

=head1 AUTHOR

David Davis <xantus@cpan.org>
L<http://xant.us/>

=head1 LICENSE

Artistic License

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2010 David Davis, All rights reserved
