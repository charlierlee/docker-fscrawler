var path = require('path');
var express = require('express');
var app = express();
var cors = require('cors')

app.use(cors({
    origin: 'https://search.leenet.link'
}));
app.use(express.static('/home/alice/share'));

app.listen(3000, function () {
    console.log('Listening on http://elasticsearch-client:3000/');
});
