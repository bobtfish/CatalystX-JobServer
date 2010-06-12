package CatalystX::JobServer::Web::Plugin::ModelsFromConfig;
use CatalystX::JobServer::Moose::Role;
use CatalystX::InjectComponent;

after 'setup_components' => sub { shift->_setup_dynamic_models(@_); };

sub _setup_dynamic_models {
    my ($app) = @_;

    my $model_prefix = 'Model::';

    my $config = $app->config || {};

    foreach my $model_name ( grep { /^$model_prefix/ } keys %$config ) {
        unless ($app->component) {
            CatalystX::InjectComponent->inject(
                into => $app,
                component => 'CatalystX::JobServer::Web::ModelBase::Adaptor',
                as => $model_name,
            );
        }
    }
}

1;
