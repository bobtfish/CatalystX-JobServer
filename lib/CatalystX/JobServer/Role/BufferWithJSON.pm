package CatalystX::JobServer::Role::BufferWithJSON;
use CatalystX::JobServer::Moose::Role;
use JSON;
use Try::Tiny;
use Data::Dumper;

method get_json_from_buffer ($buf_ref, $code_ref) {
    Carp::confess("AGGGHH") unless ref($code_ref) eq 'CODE';
    my $finish_index = index $$buf_ref, "\xff";
    my $start_index = index $$buf_ref, "\x00";
    if ($start_index != -1 && $finish_index != -1) {
        my $length = $finish_index - $start_index;
        my $pre_junk = substr($$buf_ref, 0, $start_index+1, '');
        my $json = substr($$buf_ref, 0, $length-1, '');
        substr($$buf_ref, 0, 1, ''); # Remove trailing character
        # FIXME - Multiple JSON packets in one callback..
        #warn("Grabbed JSON" . Dumper($json));
        my $data = try { from_json($json) }
            catch { warn("Error deserializing $_ content $json") };
        $code_ref->($data) if $data;
        return 1;
    }
    return;
}

1;
