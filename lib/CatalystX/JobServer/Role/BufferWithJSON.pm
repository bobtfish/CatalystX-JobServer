package CatalystX::JobServer::Role::BufferWithJSON;
use CatalystX::JobServer::Moose::Role;

method get_json_from_buffer ($buf_ref, $code_ref) {
    Carp::confess("AGGGHH") unless ref($code_ref) eq 'CODE';
    my $index = index $$buf_ref, "\xff";
    if ($index != -1) {
        my $json = substr($$buf_ref, 0, $index+1, '');
        substr($json, length($json)-1, 1, ''); # Chop trailing \xff
        substr($json, 0, 1, '');               # Chop leading  \x00
        $code_ref->($json);
        return 1;
    }
    return;
}

1;
