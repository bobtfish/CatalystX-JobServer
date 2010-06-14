package CatalystX::JobServer::TraitFor::JobRunner::JobFinishedCallback;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::CallbackWrapper' => {
    wrap => 'job_finished',
};

1;
