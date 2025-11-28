import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'change_me';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/atx_wallet';

await mongoose.connect(MONGODB_URI);

const userSchema = new mongoose.Schema({
  name: { type: String },
  username: { type: String, required: true, unique: true, index: true },
  email: { type: String }, // опционально
  passwordHash: { type: String, required: true },
}, { timestamps: true });

const User = mongoose.model('User', userSchema);

function sign(user) {
  return jwt.sign({ sub: user._id, username: user.username }, JWT_SECRET, { expiresIn: '7d' });
}

app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, username, password, email } = req.body || {};
    if (!username || !password) return res.status(400).json({ message: 'Invalid payload' });

    const exists = await User.findOne({ username });
    if (exists) return res.status(409).json({ message: 'User already exists' });

    const passwordHash = await bcrypt.hash(password, 10);
    const user = await User.create({ name, username, email, passwordHash });
    const token = sign(user);
    return res.status(201).json({ token, user: { id: user._id, name, username } });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.post('/api/auth/login', async (req, res) => {
  try {
    const { login, password } = req.body || {};
    if (!login || !password) return res.status(400).json({ message: 'Invalid payload' });

    const user = await User.findOne({ username: login })
      || await User.findOne({ email: login }); // fallback, если передали email
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });

    const ok = await bcrypt.compare(password, user.passwordHash);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

    const token = sign(user);
    return res.status(200).json({ token, user: { id: user._id, name: user.name, username: user.username } });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/health', (req, res) => res.json({ ok: true }));

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://0.0.0.0:${PORT}`);
});
