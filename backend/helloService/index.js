const express = require('express');
require('dotenv').config()
var cors = require('cors')

const app = express();
app.use(cors())
app.use(express.json());

app.get('/', (req, res) => {
    res.send({ msg: 'Hello World' });
});

app.get('/health', (req, res) => {
    res.send({ status: 'OK' });
});

// ADD THIS BLOCK for /api route
app.get('/api', (req, res) => {
    res.send({ msg: 'Hello from /api endpoint' });
});
app.get('/api/*', (req, res) => {
    res.send({ msg: 'Hello from /api/* endpoint' });
});

app.listen(process.env.PORT, () => {
    console.log(`Server is running on port ${process.env.PORT}`);
});