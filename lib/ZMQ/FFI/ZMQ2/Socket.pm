package ZMQ::FFI::ZMQ2::Socket;
{
  $ZMQ::FFI::ZMQ2::Socket::VERSION = '0.07';
}

use Moo;
use namespace::autoclean;

use FFI::Raw;

extends q(ZMQ::FFI::SocketBase);

with q(ZMQ::FFI::SocketRole);

has zmq2_ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_zmq2_ffi',
);

sub send {
    my ($self, $msg, $flags) = @_;

    my $ffi      = $self->ffi;
    my $zmq2_ffi = $self->zmq2_ffi;

    $flags //= 0;

    my $bytes_size = length($msg);
    my $bytes      = pack "a$bytes_size", $msg;
    my $bytes_ptr  = unpack('L!', pack('P', $bytes));

    my $msg_ptr = FFI::Raw::memptr(40); # large enough to hold zmq_msg_t

    $self->check_error(
        'zmq_msg_init_size',
        $ffi->{zmq_msg_init_size}->($msg_ptr, $bytes_size)
    );

    my $msg_data_ptr = $ffi->{zmq_msg_data}->($msg_ptr);
    $self->ffi->{memcpy}->($msg_data_ptr, $bytes_ptr, $bytes_size);

    $self->check_error(
        'zmq_send',
        $zmq2_ffi->{zmq_send}->($self->_socket, $msg_ptr, $flags)
    );

    $ffi->{zmq_msg_close}->($msg_ptr);
}

sub recv {
    my ($self, $flags) = @_;

    my $ffi      = $self->ffi;
    my $zmq2_ffi = $self->zmq2_ffi;

    $flags //= 0;

    my $msg_ptr = FFI::Raw::memptr(40);

    $self->check_error(
        'zmq_msg_init',
        $ffi->{zmq_msg_init}->($msg_ptr)
    );

    $self->check_error(
        'zmq_recv',
        $zmq2_ffi->{zmq_recv}->($self->_socket, $msg_ptr, $flags)
    );

    my $data_ptr = $ffi->{zmq_msg_data}->($msg_ptr);

    my $msg_size = $ffi->{zmq_msg_size}->($msg_ptr);
    $self->check_error('zmq_msg_size', $msg_size);

    my $content_ptr = FFI::Raw::memptr($msg_size);

    $self->ffi->{memcpy}->($content_ptr, $data_ptr, $msg_size);

    $ffi->{zmq_msg_close}->($msg_ptr);
    return $content_ptr->tostr($msg_size);
}

sub _init_zmq2_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_send} = FFI::Raw->new(
        $soname => 'zmq_send',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket
        FFI::Raw::ptr, # ptr to zmq_msg_t
        FFI::Raw::int  # flags
    );

    $ffi->{zmq_recv} = FFI::Raw->new(
        $soname => 'zmq_recv',
        FFI::Raw::int, # retval
        FFI::Raw::ptr, # socket ptr
        FFI::Raw::ptr, # msg ptr
        FFI::Raw::int  # flags
    );

    return $ffi;
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=head1 NAME

ZMQ::FFI::ZMQ2::Socket

=head1 VERSION

version 0.07

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
