package CatalystX::JobServer::Web::Model::MessageQueue;
use CatalystX::JobServer::Moose;
use namespace::autoclean;

extends 'CatalystX::JobServer::Web::ModelBase::Adaptor';

has '+class' => ( default => 'CatalystX::JobServer::MessageQueue' );

__PACKAGE__->meta->make_immutable;
1;

=head1 AUTHORS, COPYRIGHT, LICENSE

See L<CatalystX::JobServer>.

=cut
