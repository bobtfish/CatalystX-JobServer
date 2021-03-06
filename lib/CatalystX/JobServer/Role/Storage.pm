package CatalystX::JobServer::Role::Storage;
use CatalystX::JobServer::Moose::Role;
use JSON::XS;
use MooseX::Storage 0.28;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();
use MooseX::Types::Moose qw/ ArrayRef /;
use MooseX::Storage;
use MooseX::Storage::Engine;
use namespace::autoclean;

foreach my $type (qw/File Dir/) {
    MooseX::Storage::Engine->add_custom_type_handler(
        'Path::Class::' . $type =>
            expand => sub {},
            collapse => sub { shift() . "" },
    );
}

with Storage(engine => 'JSON'),
     'Log::Message::Structured::Stringify::AsJSON',
     'Log::Message::Structured' => { excludes => [qw/ freeze /]};

has catalyst_component_name => (
    is => 'ro',
    writer => '_set_catalyst_component_name',
);

sub freeze {
    my $self = shift;
    JSON::XS->new->pretty(shift||0)->encode($self->pack);
};

around 'pack' => sub {
    my ($orig, $self, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, '+CatalystX::JobServer::Role::Storage::Engine::Trait::OnlySerializeMarked');
    $self->$orig(%args);
};

around 'unpack' => sub {
    my ($orig, $self, $data, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, '+CatalystX::JobServer::Role::Storage::Engine::Trait::OnlySerializeMarked');
    $self->$orig($data, %args);
};

1;
