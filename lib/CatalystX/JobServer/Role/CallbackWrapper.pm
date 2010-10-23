package CatalystX::JobServer::Role::CallbackWrapper;
use MooseX::Role::Parameterized;
use MooseX::Types::Moose qw/ CodeRef Str /;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

my $code = subtype CodeRef, where { 1 };
coerce $code, from Str, via { eval "sub { $_ };" };

parameter wrap => (
    isa      => Str,
    required => 1,
);

parameter wrap_type => (
    isa => enum([qw/before after/]),
    default => 'before',
);

parameter callback_name => (
    isa => Str,
    predicate => 'has_callback_name',
);

role {
    my $p = shift;

    my $name = $p->wrap;
    my $callback_name = $p->has_callback_name ? $p->callback_name : $name . '_callback';

    has $callback_name => (
        isa => $code,
        is => 'ro',
        coerce => 1,
        required => 1,
    );

    my $wrap = sub {
        my ($self, @args) = @_;
        my $code = $self->$callback_name;
        $self->$code(@args);
    };
    $p->wrap_type eq 'before' ? do { before $name => $wrap } : do { after $name => $wrap };
};

1;
