var path = require('path');
var express = require('express');
var app = express();
var cors = require('cors')

app.use(cors({
    origin: 'http://elasticsearch1:31358'
}));
app.use(express.static('/home/alice/ownCloud'));

app.listen(3000, function () {
    console.log('Listening on http://elasticsearch1:3000/');
});
