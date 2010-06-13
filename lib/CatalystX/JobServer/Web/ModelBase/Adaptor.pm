package CatalystX::JobServer::Web::ModelBase::Adaptor;
use CatalystX::JobServer::Moose;
use Moose::Util qw/ find_meta /;
use MooseX::Types::Moose qw/ HashRef ArrayRef Str /;
use MooseX::Types::LoadableClass qw/LoadableClass/;
use CatalystX::JobServer::Inlined::MooseX::Traits::Pluggable;

extends 'Catalyst::Model';
with 'MooseX::Traits::Pluggable' => {
    -excludes => ['new_with_traits'],
    -alias => { _build_instance_with_traits => 'build_instance_with_traits' },
};

sub _trait_namespace {
    my $class = shift->{class};
    if ($class =~ s/^CatalystX::JobServer//) {
        my @list;
        do {
            push(@list, 'CatalystX::JobServer::TraitFor' . $class)
        }
        while ($class =~ s/::\w+$//);
        push(@list, 'CatalystX::JobServer::TraitFor::Model' . $class);
        return \@list;
    }
    return $class . '::TraitFor';
}

has class => (
    isa => LoadableClass,
    is => 'ro',
    required => 1,
    coerce => 1,
);

has args => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

has traits => (
    isa => Str|ArrayRef([Str]),
    predicate => 'has_traits',
    is => 'ro',
);

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    my $self = $class->next::method($app, @rest);

    $self->build_instance_with_traits(
        $self->class,
        {
            publish_message_callback => sub { $app->model('MessageQueue')->publish_to_channel( @_ ) },
            model_locator_callback => sub { $app->model(@_) },
            $self->has_traits ? (traits => $self->traits) : (),
            %{ $self->args },
        },
    );
}

__PACKAGE__->meta->make_immutable;
