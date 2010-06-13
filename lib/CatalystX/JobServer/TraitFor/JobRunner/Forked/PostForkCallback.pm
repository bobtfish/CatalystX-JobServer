package CatalystX::JobServer::TraitFor::JobRunner::Forked::PostForkCallback;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ CodeRef Str /;

my $code = subtype CodeRef, where { 1 };
coerce $code, from Str, via { eval "sub { $_ };" };

has post_fork_callback => (
    isa => $code,
    is => 'ro',
    coerce => 1,
    required => 1,
);

before run_job_post_fork => sub {
    my ($self, @args) = @_;
    $self->post_fork_callback->($self, @args);
};

1;
