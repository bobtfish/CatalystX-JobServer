package TestJobReturn;
use Moose;
use MooseX::Storage;
use Method::Signatures::Simple;
use namespace::autoclean;

with Storage( format => 'JSON' );

has pid => (
    is => 'ro',
    required => 1,
);

package TestJob;
use Moose;
use MooseX::Storage;
use Method::Signatures::Simple;
use namespace::autoclean;

with Storage( format => 'JSON' );

method run {
    TestJobReturn->new(pid => $$);
}

__PACKAGE__->meta->make_immutable;
