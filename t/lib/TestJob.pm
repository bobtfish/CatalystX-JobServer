package TestJob;
use Moose;
use MooseX::Storage;
use Method::Signatures::Simple;
use namespace::autoclean;

with Storage( format => 'JSON' );

has exit => ( is => 'ro', required => 1, isa => 'Bool',);
has return => ( is => 'ro', required => 1);

method run {
    exit if $self->exit;
    return $self->return;
}

__PACKAGE__->meta->make_immutable;
