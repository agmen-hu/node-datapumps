var
  datapumps = require('../index'),
  Pump = datapumps.Pump,
  MongodbMixin = datapumps.mixin.MongodbMixin,
  ExcelWriterMixin = datapumps.mixin.ExcelWriterMixin,
  pump = new Pump();

pump
  .mixin(MongodbMixin('mongodb://localhost/marketing'))
  .useCollection('Contact')
  .from(pump.find({ country: "US" }))

  .mixin(ExcelWriterMixin())
  .createWorkbook('/tmp/ContactsInUs.xlsx')
  .createWorksheet('Contacts')
  .writeHeaders(['Name', 'Email'])

  .process(function(contact) {
    return pump.writeRow([ contact.name, contact.email ]);
  })
  .logErrorsToConsole()
  .run()
    .then(function() {
      console.log("Done writing contacts to file");
    });
