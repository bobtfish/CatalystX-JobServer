package CatalystX::JobServer::Web::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
);

after process => sub {
    my ($self, $c) = @_;
    if ($c->res->header('Content-Type') =~ /html/) {
        my $body = $c->res->body;
        $c->res->body($body);
    }
};

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
1;
