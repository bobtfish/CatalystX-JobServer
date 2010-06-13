package CatalystX::JobServer::JobRunner::Forked;
use CatalystX::JobServer::Moose;
use AnyEvent::Util qw/ fork_call /;
use namespace::autoclean;

with 'CatalystX::JobServer::JobRunner';

sub post_fork {
    my ($self, $job) = @_;
}

sub _do_run_job {
    my ($self, $job, $return_cb) = @_;
    # What happens about many many requets..
    fork_call { # DO NOT ENTER THE EVENT LOOP OR YOU WILL DIE!!!
        $self->_clear_publish_timer if $self->can('_clear_publish_timer');
        $self->post_fork($job);
        $job->run;
    }
    sub {
        if (scalar @_) {
            $self->job_finished($job, shift, $return_cb);
        }
        else {
            warn("Job failed, returned " . $@);
            $self->job_failed($job, $@, $return_cb);
        }
    };
}

__PACKAGE__->meta->make_immutable;
1;
