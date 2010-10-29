package CatalystX::JobServer::Web::Plugin::ModelsFromConfig;
use CatalystX::JobServer::Moose::Role;
use CatalystX::InjectComponent;

after 'setup_components' => sub { shift->_setup_dynamic_models(@_); };

sub _setup_dynamic_models {
    my ($app) = @_;

    my $model_prefix = 'Model::';

    my $config = $app->config || {};

    foreach my $model_name ( grep { /^$model_prefix/ } keys %$config ) {
        unless ($app->component($model_name)) {
            CatalystX::InjectComponent->inject(
                into => $app,
                component => 'CatalystX::JobServer::Web::ModelBase::Adaptor',
                as => $model_name,
            );
        }
    }
}

after _setup_dynamic_models => sub {
    my ($app) = @_;
    my @models = grep { eval { $app->model($_)->isa('CatalystX::JobServer::JobRunner::Forked') } }
        $app->models;
    foreach my $model_name (@models) {
        my $name = 'Controller::' . $model_name;
        $app->config( $name => {
            action => {
                base => {
                    PathPart => [ lc $model_name ],
                }
            },
            model_name => $model_name,
        });
        CatalystX::InjectComponent->inject(
            into => $app,
            component => 'CatalystX::JobServer::Web::ControllerBase::ForkedJobRunner',
            as => "$name",
        );
    }
};

1;

=head1 NAME

CatalystX::JobServer::Web::Plugin::ModelsFromConfig - Plugin role to build application components from config.

=head1 SYNOPSIS

    use Catalyst qw/
        +CatalystX::JobServer::Web::Plugin::ModelsFromConfig
    /;

=head1 DESCRIPTION

Goes through the application config. Any config keys for models which aren't registered after L<Catalyst/setup_components>
are injected as instances of L<CatalystX::JobServer::Web::ModelBase::Adaptor> using L<CatalystX::InjectComponent>.

=head1 SEE ALSO

L<CatalystX::JobServer::Web::ModelBase::Adaptor>, L<CatalystX::InjectComponent>.

=cut
