package CatalystX::JobServer::TraitFor::JobRunner::Forked::JobFinishedCallback;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::CallBackWrapper' => {
    wrap => 'job_finished',
};

1;
