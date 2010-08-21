var rx = new Rx({ defaultTypes: true });

for (coreType in Rx.CoreType) rx.registerType( Rx.CoreType[coreType] );

var rxChecker;
$(document).ready(function() {
    try {
        var rxdata = $('#rxdata').text();
        var schema = JSON.parse(rxdata);
        rxChecker = rx.makeSchema(schema);
    } catch (e) {
        if (e instanceof Rx.Error) {
            alert('BAD SCHEMA: ' + e.message);
        }
        else {
            throw e;
        }
    }

 //       var valid = rxChecker.check( testData );

});

