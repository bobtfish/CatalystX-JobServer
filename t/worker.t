use strict;
use warnings;

use Test::More;

{
    package MyWorker;
    use Moose;
    use MooseX::Types::Moose qw/ ArrayRef Str /;
    extends 'CatalystX::JobServer::JobRunner::Forked::Worker';

    has _found_jobs => (
        isa => ArrayRef[Str],
        is => 'rw',
        default => sub { [] },
    );

    around get_json_from_buffer => sub {
        my ($orig, $self, $buf) = @_;
        $self->$orig($buf, sub { $self->json_object(shift)});
    };

    sub json_object {
        my ($self, $data) = @_;
        push(@{ $self->_found_jobs }, $data);
    }
}

my $w = MyWorker->new;
ok $w, 'Have worker';

my $buf = "\x00FOO\xff";
ok $w->get_json_from_buffer(\$buf), 'Got a job';
is $buf, '', 'Buf empty';
is_deeply $w->_found_jobs, ['FOO'], 'Got a job';

$w->_found_jobs([]);

$buf = "\x00FOO\xff\x00BAR\xff";
ok $w->get_json_from_buffer(\$buf), 'Found one job';
ok $w->get_json_from_buffer(\$buf), 'Found second job';
is $buf, '', 'Buf empty';
is_deeply $w->_found_jobs, ['FOO', 'BAR'], 'Got two jobs';

$w->_found_jobs([]);

$buf = "\x00FO";
ok !$w->get_json_from_buffer(\$buf), 'Did not get from buffer';
$buf = "\x00FOO\xff\x00BA";
ok $w->get_json_from_buffer(\$buf), 'Got one job from buffer';
ok !$w->get_json_from_buffer(\$buf), 'Did not get a second';
is $buf, "\x00BA", 'Partial second job still in buffer';
$buf = "\x00BAR\xff\x00QUACK";
ok $w->get_json_from_buffer(\$buf), 'Got job from buffer';
is_deeply $w->_found_jobs, ['FOO', 'BAR'], 'Found two expected jobs';
is $buf, "\x00QUACK", 'buffer as expectedget_json_from_buffer';

done_testing;
