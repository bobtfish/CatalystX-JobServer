package CatalystX::JobServer::Role::BufferWithJSON;
use CatalystX::JobServer::Moose::Role;

requires 'json_object';

method get_json_from_buffer ($buf_ref) {
    my $index = index $$buf_ref, "\xff";
    if ($index != -1) {
        my $json = substr($$buf_ref, 0, $index+1, '');
        substr($json, length($json)-1, 1, ''); # Chop trailing \xff
        substr($json, 0, 1, '');               # Chop leading  \x00
        $self->json_object($json);
        return 1;
    }
    return;
}

1;
