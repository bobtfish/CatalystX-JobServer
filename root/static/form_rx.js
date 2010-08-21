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
});
function SetupRxFormChecker (formId) {
    $('#' + formId).submit(function() {
        // get all the inputs into an array.
        var $inputs = $('#' + formId + ' :input');

        // not sure if you wanted this, but I thought I'd add it.
        // get an associative array of just the values.
        var values = {};
        $inputs.each(function() {
            if (this.name.length) {
                var val = $(this).val();
                if (val.length && ! isNaN(val * 1)) {
                    val = val *1;
                }
                values[this.name] = val; 
            }
        });
        alert(dump(values));
        var valid = rxChecker.check(values);
        if (! valid) {
               alert('Form ' + formId + ' invalid, cannot be submitted');
        }

    });
}