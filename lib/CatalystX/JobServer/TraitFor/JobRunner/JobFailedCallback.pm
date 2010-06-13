package CatalystX::JobServer::TraitFor::JobRunner::JobFailedCallback;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::CallBackWrapper' => {
    wrap => 'job_failed',
};

1;
