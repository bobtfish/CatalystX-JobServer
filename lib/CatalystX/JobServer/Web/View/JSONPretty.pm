package CatalystX::JobServer::Web::View::JSONPretty;
use CatalystX::JobServer::Moose;

extends 'Catalyst::View';

# Fugly as fuck. Too tired to do betterer. Please clean up.
method process ($c, $data) {
    my $text = $c->stash->{json_encoder}->encode($data);
    $text =~ s{(http://[^"]+)}{<a href="$1">$1</a>}g;
    $text =~ s{\n}{<br />\n}g;
    my @lines = split /\n/, $text;
    foreach (@lines) {
        my ($cut) = $_ =~ m/^(\s+)/;
        my $replace = "&nbsp;" x length($cut);
        s/^$cut/$replace/;
    }
    return join("\n", @lines);
    return $text;
}

__PACKAGE__->meta->make_immutable;