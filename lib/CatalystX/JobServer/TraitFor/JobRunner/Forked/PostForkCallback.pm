package CatalystX::JobServer::TraitFor::JobRunner::Forked::PostForkCallback;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::CallBackWrapper' => {
    wrap => 'post_fork',
};

1;
