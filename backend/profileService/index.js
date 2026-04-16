const express = require('express');
const mongoose = require('mongoose');
require('dotenv').config();
var cors = require('cors');

const app = express();
const port = process.env.PORT;

mongoose.connect(process.env.MONGO_URL, { useNewUrlParser: true, useUnifiedTopology: true });

app.use(express.json());
app.use(cors());

app.get('/health', (req, res) => {
    res.send({ status: 'OK' });
});

// NEW: Simple /profile endpoint for Ingress routing test
app.get('/profile', (req, res) => {
    res.json({ message: 'Profile endpoint works' });
});

const userSchema = mongoose.Schema({
    name: {
        type: String,
        required: true,
        minlength: 1,
        maxlength: 200
    },
    age: {
        type: Number,
        required: true
    },
    createdAt: {
        type: Date,
        default: Date.now()
    }
});
const User = mongoose.model('user', userSchema);

app.post('/addUser', async (req, res) => {
    try {
        const { name, age } = req.body;
        if (!name || !age) {
            return res.status(400).json({ error: "Both name and age are required." });
        }
        const existingUser = await User.find({ name: name });
        // FIX: find returns an array, so check length
        if (existingUser.length > 0) {
            return res.status(409).json({ error: "User already exists." });
        }
        const newuser = new User({ name, age });
        const savedUser = await newuser.save();
        res.status(201).json({ msg: "User Added Successfully" });
    } catch (err) {
        console.error(err);
        res.status(500).json({ err: "Internal Server Error" });
    }
});

app.get('/fetchUser', async (req, res) => {
    try {
        let user = await User.find({});
        if (user.length) {
            res.send(user);
        } else {
            res.send({ msg: "User doesn't exist" });
        }
    } catch (err) {
        console.error(err);
        res.status(500).send({ msg: "Something went wrong" });
    }
});

app.listen(port, () => {
    console.log(`Server is running on port ${port}`);
});