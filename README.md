# Datapumps: Simple ETL for node.js
[![Travis CI Badge](https://api.travis-ci.org/agmen-hu/node-datapumps.svg?branch=master)](https://travis-ci.org/agmen-hu/node-datapumps "Travis CI")

## Overview
Create a group of pumps to import, export, transform or transfer data.

## Usage example: csv export from mysql
 * Create a group:
   ```js
   var datapumps = require('datapumps');
   var pumpGroup = datapumps.group();
   ```

 * Create a pump that loads the data from mysql:
   ```js
   pumpGroup.addPump('customers')
     .from(mysqlConnection.query('SELECT id,last_name,first_name FROM customer').stream({highWaterMark: 5}));
   ```
   This pump will read the query results into a buffer. The pump controls the data flow, i.e.
   it pauses read of query results when buffer is full.

 * Create a pump that writes the data to csv:
   ```js
   pumpGroup.addPump('csvWriter')
     .from(pumpGroup.pump('customers').buffer())
     .mixin(datapumps.mixin.CsvWriterMixin({
       path: 'test.csv',
       headers: [ 'Id', 'First Name', 'Last Name' ]
     }))
     .process(function(customer) {
       this.writeRow([ customer.id, customer.first_name, customer.last_name ]);
     });
   ```
   `.from` indicates that the pump will load data from the buffer of *customers* pump. The
   `CsvWriterMixin` extends the functionality of the pump, it creates csv file with given
   headers and adds the `.writeRow` method to the pump. Finally, the `.process` method
   (which copies data to the output buffer by default) is overridden with writing rows to the csv.

 * Register a listener for `end` event and `.start()` the pump:
   ```js
   pumpGroup
     .on('end', function() {
       console.log('CSV export complete.');
     })
     .start();
   ```
   The group will emit *end* event when all of its pumps completed their jobs. It is also possible
   to get a promise for that (`.whenFinished()`).

## Pump
A pump reads data from its input and copies it to the output buffer by default:
```js
datapumps = require('datapumps');
(pump = new datapumps.Pump())
  .from(<put a nodejs stream or datapumps buffer here>)
  .start()
```

To access the output buffer, use the `.buffer()` method, which returns a Buffer instance:
```js
buffer = pump.buffer('output');
buffer = pump.buffer(); // equivalent with previous as the default buffer
                        // of the pump is called 'output'
```

Use the `.buffers()` method when you need multiple buffers:
```js
ticketsPump
  .buffers({
    openTickets: pump.createBuffer(),
    closedTickets: pump.createBuffer(),
  });

reminderMailer = new datapumps.Pump()
reminderMailer
  .from(ticketPump.buffer('openTickets'))
  ...
```
Note that the *tickets* pump has two output buffers: *openTickets* and *closedTickets*. The *reminderMailer* pump
reads data from the *openTickets* buffer of the *tickets* pump.

### Transforming data
Use the `.process()` method to set the function which processes data:
```js
ticketsPump
  .process(function(ticket) {
    ticket.title = 'URGENT: ' + ticket.title;
    return this.buffer('openTickets').writeAsync(ticket);
  });
```
The argument of `.process()` is a function that will be executed after the pump reads a data item.
The function is executed in the context of the pump object, i.e. `this` refers to the pump itself. The
function should return a Promise that fulfills when the data is processed (i.e. written into a buffer
or stored elsewhere).

### Start and end of pumping
A pump is started by calling the `.start()` method. The `end` event will be emitted when the
input stream or buffer ended and all output buffers became empty.
```js
pump.on('end', function() {
  console.log('Pumped everything, and all my output buffers are empty. Bye.')
})
```

## Pump group
You often need multiple pumps to complete an ETL task. Pump groups help starting multiple pump in
one step, and also enables handling the event when every pump ended:
```js
sendMails = datapumps.group();
sendMails.addPump('tickets')
  ...;
sendMails.addPump('reminderMailer')
  ...;
sendMails
  .start()
  .whenFinished().then(function() {
    console.log('Tickets processed.');
  });
```
The `.addPump()` method creates a new pump with given name and returns it for configuration.
`.start()` will start all pumps in the group, while `.whenFinished()` returns a Promise the fulfills
when every pump ended (Note: `end` event is also emitted).

### Encapsulation
Sometimes you wish to encapsulate a part of an ETL process and also use it elsewhere. It is possible
to set an input pump and expose buffers from the group, so it will provide the same interface as a
simple pump (i.e. it has `.from()`, `.start()`, `.buffer()` methods and emits `end` event).

Most likely, you want to extend `datapumps.Group` class (example is written in CoffeeScript):
```coffee
{ Group, mixin: { MysqlMixin } } = require 'datapumps'

class Notifier extends Group
  constructor: ->
    super()
    @addPump 'emailLookup'
      .mixin MysqlMixin connection
      .process (data) ->
        @query('SELECT email FROM user where username = ?', [ data.username ])
          .then (result) =>
            data.emailAddress = result.email
            @buffer().writeAsync data
    @addPump 'sendMail'
      .from @pump 'emailLookup'
      .process (data) ->
        ... # send email to data.emailAddress
        @buffer().writeAsync
          recipient:
            name: data.name
            email: data.emailAddress

    @setInputPump 'emailLookup'
    @expose 'output', 'sendMail/output'
```
The `Notifier` will behave like pump, but in the inside, it does an email address lookup using
mysql, and sends mail to those addresses. The output buffer of `sendMail` pump is filled with
recipient data.

Use the created class like this:
```coffee
etlProcess = datapumps.group()
etlProcess
  .addPump 'notifier', new Notifier
    .from <node stream or datapumps buffer>

etlProcess
  .addPump 'logger'
    .from etlProcess.pump('notifier').buffer()
    .process (data) ->
      console.log "Email sent to #{data.name} (#{data.email})"
```
Please note that you cannot use `.process` method on a group.

## Error handling
Errors may occur while data is transfered between systems. Most of the time, you don't want to stop
on the first error but complete the transfer and re-run after fixing problems. Therefore
the pump group has an error buffer (`.errorBuffer()`) which can hold ten error messages by default.
When the error buffer fills up, `error` event is triggered and `.whenFinised()` promise is rejected:
```js
group
  .start()
  .whenFinished()
    .then(function() {
      if (!group.errorBuffer().isEmpty()) {
        console.log("Transfer finished, but with errors.");
        // errors list will be at group.errorBuffer().getContent()
      }
    })
    .catch(function() {
      console.log("Pump group failed with errors");
      // errors list will be at group.errorBuffer().getContent()
    });
```

### Debugging
The following example shows a fingers-crossed type logging, i.e. debug logging is turned on
after the first error occured:

```coffee
{ group } = require('datapumps')

(d = group())
  .addPump 'test'
    .from d.createBuffer
      sealed: true,
      content: [ 'first', 'second', 'third', 'fourth' ]
    .process (data) ->
      throw new Error 'Start debugging', data if data == 'second'
      @copy data

d.errorBuffer().on 'write', (data) ->
  console.log data
  d.buffer('test/output').on 'write', (data) ->
    console.log "#{data} was written to test/output buffer"

d.start()
```

The output:
```
{ message: [Error: Start debugging], pump: 'test' }
third was written to test/output buffer
fourth was written to test/output buffer
```

## Mixins
The core components of datapumps is only responsible for passing data in a flow-controlled manner.
The features required for import, export or transfer is provided by mixins:
 * CsvWriterMixin - Writes csv files using fast-csv package
 * ExcelWriterMixin - Writes excel xlsx workbooks
 * MysqlMixin - Reads and writes on a mysql connection

For more details, see the documented source code until the docco docs become available. If you
implement new mixins, please fork datapumps and make a pull request.
