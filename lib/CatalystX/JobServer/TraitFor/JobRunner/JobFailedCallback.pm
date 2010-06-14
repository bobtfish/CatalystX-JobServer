package CatalystX::JobServer::TraitFor::JobRunner::JobFailedCallback;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::CallbackWrapper' => {
    wrap => 'job_failed',
};

1;
