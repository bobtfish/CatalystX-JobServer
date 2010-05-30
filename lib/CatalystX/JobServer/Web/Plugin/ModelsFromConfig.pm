package CatalystX::JobServer::Web::Plugin::ModelsFromConfig;
use Moose::Role;
use namespace::autoclean;

with 'CatalystX::DynamicComponent' => {
    name => '_setup_dynamic_model',
    superclasses => [qw/ CatalystX::JobServer::Web::ModelBase::Adaptor /],
};

after 'setup_components' => sub { shift->_setup_dynamic_models(@_); };

sub _setup_dynamic_models {
    my ($app) = @_;

    my $model_prefix = 'Model::';

    my $config = $app->config || {};

    foreach my $model_name ( grep { /^$model_prefix/ } keys %$config ) {
        $app->_setup_dynamic_model( $model_name, $config->{$model_name})
            unless $app->component($model_name);
    }
}

1;
