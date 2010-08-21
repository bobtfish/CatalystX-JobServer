var rx = new Rx({ defaultTypes: true });

for (coreType in Rx.CoreType) rx.registerType( Rx.CoreType[coreType] );

var schemaToTest = [];
schemaToTest = schemaToTest.sort();
for (i in schemaToTest) {
  var schemaName = schemaToTest[i];
  var schemaTest = plan.testSchema[ schemaName ];

  var rxChecker;

  try {
    rxChecker = rx.makeSchema(schemaTest.schema);
  } catch (e) {
    if (schemaTest.invalid && (e instanceof Rx.Error)) {
      print('ok ' + currentTest++ + ' - BAD SCHEMA: ' + schemaName);
      continue;
    }
    print("# exception thrown when creating schema " + schemaName + ": " + e.message);
    throw e;
  }

  if (schemaTest.invalid) {
    print('not ok ' + currentTest++ + ' - BAD SCHEMA: ' + schemaName);
    continue;
  }

  for (pf in { pass: 1, fail: 1 }) {
    for (sourceName in schemaTest[pf]) {
      var sourceTests = schemaTest[pf][sourceName];
      var sourceData = plan.testData[sourceName];

      for (j in sourceTests) {
        var sourceEntry = sourceTests[j];
        var testData = sourceData[ sourceEntry ];

        var valid = rxChecker.check( testData );
        var expect = pf == 'pass';

        var testDesc = (expect ? 'VALID : ' : 'INVALID: ')
                     + sourceName + '/' + sourceEntry
                     + ' against ' + schemaName;
        
        // JavaScript needs logical xor! -- rjbs, 2008-07-31
        if ((valid && !expect) || (!valid && expect)) {
          print("not ok " + currentTest++ + ' - ' + testDesc);
        } else {
          print("ok " + currentTest++ + ' - ' + testDesc);
        }
      }
    }
  }
}

