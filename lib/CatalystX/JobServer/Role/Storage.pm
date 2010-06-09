package CatalystX::JobServer::Role::Storage;
use Moose::Role;
use JSON::XS;
use MooseX::Storage;
use Set::Object;
use CatalystX::JobServer::Meta::Attribute::Trait::Serialize ();
use MooseX::Types::Moose qw/ ArrayRef /;
use MooseX::Storage;
use MooseX::Storage::Engine;
use namespace::autoclean;

MooseX::Storage::Engine->add_custom_type_handler(
    'Set::Object' =>
        expand => sub {},
        collapse => sub {
            my @members = $_[0]->members;
            MooseX::Storage::Engine->find_type_handler( ArrayRef )->{collapse}->( \@members );
        },
);

with Storage(engine => 'JSON');

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
    push(@{$args{engine_traits}}, 'OnlySerializeMarked');
    $self->$orig(%args);
};

around 'unpack' => sub {
    my ($orig, $self, $data, %args) = @_;
    $args{engine_traits} ||= [];
    push(@{$args{engine_traits}}, 'OnlySerializeMarked');
    $self->$orig($data, %args);
};

1;
