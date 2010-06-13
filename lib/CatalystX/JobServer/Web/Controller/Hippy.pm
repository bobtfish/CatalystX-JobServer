package CatalystX::JobServer::Web::Controller::Hippy;
use CatalystX::JobServer::Moose;

BEGIN { extends 'Catalyst::Controller' };

sub hippy : Chained('/base') PathPart('hippy.html') Args(0) {
    my ($self, $c) = @_;

$c->res->body(q{
<html>
<head>
<title>Hippie demo: timer</title>
<script src="/static/jquery-1.3.2.min.js"></script>
<script src="/static/jquery.ev.js"></script>
<script src="/static/DUI.js"></script>
<script src="/static/Stream.js"></script>
<script src="/static/hippie.js"></script>
<script src="/static/json2.js"></script>
<script src="/static/dump.js"></script>

<script>

function log_it(stuff) {
  $("#log").append(stuff+'<br/>');
}
$(function() {
  var hippie = new Hippie( document.location.host + "/model/MessageQueue", 5, function() {
                               log_it("connected");
                             },
                             function() {
                               log_it("disconnected");
                             },
                             function(e) {
                               log_it("got message: " + dump(e));
                             } );
});


</script>
<link rel="stylesheet" href="/static/screen.css" />
</head>
<body>

<div id="content">

<div id="log">

</div>

</div>
</body>
</html>

});

}

__PACKAGE__->meta->make_immutable;
1;
