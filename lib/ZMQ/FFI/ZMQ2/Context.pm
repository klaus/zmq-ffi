package ZMQ::FFI::ZMQ2::Context;
{
  $ZMQ::FFI::ZMQ2::Context::VERSION = '0.07';
}

use Moo;
use namespace::autoclean;

use FFI::Raw;
use Carp;
use Try::Tiny;

use ZMQ::FFI::ZMQ2::Socket;

with qw(ZMQ::FFI::ContextRole);

has '+threads' => (
    default => 1,
);

has ffi => (
    is      => 'ro',
    lazy    => 1,
    builder => '_init_ffi',
);

sub BUILD {
    my $self = shift;

    if ($self->has_max_sockets) {
        croak
            "max_sockets option not available for ZMQ2\n".
            $self->_verstr();
    }

    try {
        $self->_ctx( $self->ffi->{zmq_init}->($self->_threads) );
        $self->check_null('zmq_init', $self->_ctx);
    }
    catch {
        $self->_ctx(-1);
        croak $_;
    };
}

sub get {
    my $self = shift;

    croak
        "getting ctx options not implemented for ZMQ2\n".
        "your version: ".$self->version;
}

sub set {
    my $self = shift;

    croak
        "setting ctx options not implemented for ZMQ2\n".
        "your version: ".$self->version;
}

sub socket {
    my ($self, $type) = @_;

    return ZMQ::FFI::ZMQ2::Socket->new(
        ctx     => $self,
        soname  => $self->soname,
        type    => $type
    );
}

sub destroy {
    my $self = shift;

    $self->check_error(
        'zmq_term',
        $self->ffi->{zmq_term}->($self->_ctx)
    );

    $self->_ctx(-1);
}

sub _init_ffi {
    my $self = shift;

    my $ffi    = {};
    my $soname = $self->soname;

    $ffi->{zmq_init} = FFI::Raw->new(
        $soname => 'zmq_init',
        FFI::Raw::ptr, # returns ctx ptr
        FFI::Raw::int  # num threads
    );

    $ffi->{zmq_term} = FFI::Raw->new(
        $soname => 'zmq_term',
        FFI::Raw::int, # retval
        FFI::Raw::ptr  # ctx pt
    );

    return $ffi;
}

__PACKAGE__->meta->make_immutable();

__END__

=pod

=head1 NAME

ZMQ::FFI::ZMQ2::Context

=head1 VERSION

version 0.07

=head1 AUTHOR

Dylan Cali <calid1984@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Dylan Cali.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
