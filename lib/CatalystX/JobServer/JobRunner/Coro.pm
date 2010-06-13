package CatalystX::JobServer::JobRunner::Coro;
use CatalystX::JobServer::Moose;
use Coro;
use Try::Tiny;
use namespace::autoclean;

with 'CatalystX::JobServer::JobRunner';

sub _do_run_job {
    my ($self, $job, $return_cb) = @_;
    # What happens about many many requets..
    async {
        my $ret;
        try { $ret = $job->run }
        catch {
            $self->job_failed($job, $_, $return_cb);
            return;
        };
        $self->job_finished($job, $ret, $return_cb);
        return;
    };
}

__PACKAGE__->meta->make_immutable;
1;