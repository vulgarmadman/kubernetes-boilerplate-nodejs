var express = require('express')
var app     = express()

//Define request response in root URL (/)
app.get('/ping', function (req, res) {
  res.send(JSON.stringify({result: 'pong!'}));
})

//Launch listening server on port 3000
app.listen(3000, function () {
    console.log(`Running in the environment ${process.env.NODE_ENV}`)
    console.log('App listening on port 3000!')
})
