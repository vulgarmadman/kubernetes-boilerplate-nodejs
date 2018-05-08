var expect  = require('chai').expect;
var request = require('request');

it('Test endpoint will work', function(done) {
    request('http://localhost:3000/ping' , function(error, response, body) {
        done();
    });
});
