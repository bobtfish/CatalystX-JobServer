package CatalystX::JobServer::JobRunner::Forked::WorkerStatus::StatusLine;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ Str /;

method is_complete { 0 }

with 'CatalystX::JobServer::JobRunner::Forked::WorkerStatus';

override BUILDARGS => sub {
    my (undef, $status_info) = (shift, shift);
    return { status_info => $status_info } if !ref($status_info) && !scalar(@_);
    super();
};

has status_info => (
    isa => Str,
    is => 'ro',
    traits => ['Serialize'],
);

__PACKAGE__->meta->make_immutable;
1;
