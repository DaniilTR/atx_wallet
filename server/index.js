import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { promises as fs } from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const app = express();
app.use(cors());
app.use(express.json());

// Simple request logger to help debugging mobile<->server connectivity
app.use((req, res, next) => {
  console.log(new Date().toISOString(), req.method, req.url, 'from', req.ip);
  next();
});

// Simple in-memory pairing store for development/testing
const pairings = new Map();

// Accept pairing confirmation from mobile clients
app.post('/api/pairings', async (req, res) => {
  try {
    const body = req.body || {};
    console.log('POST /api/pairings body:', body);
    const { session, device, address } = body;
    if (!session) return res.status(400).json({ message: 'Session is required' });
    // Store optional address (wallet address) if provided by mobile client
    pairings.set(String(session), { connected: true, device: device || 'mobile', when: Date.now(), address: address || null });
    return res.status(201).json({ ok: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

// Query pairing status by session id
app.get('/api/pairings/:session', async (req, res) => {
  try {
    const { session } = req.params;
    if (!session) return res.status(400).json({ message: 'Session is required' });
    const entry = pairings.get(String(session));
    if (!entry) return res.status(404).json({ connected: false });
    return res.status(200).json({ connected: !!entry.connected, device: entry.device, when: entry.when, address: entry.address || null });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'change_me';
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/atx_wallet';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const DEV_WALLET_DIR = path.resolve(__dirname, '../dev_wallets');
const DEV_HISTORY_DIR = DEV_WALLET_DIR;

const SAFE_ID_REGEXP = /[^a-zA-Z0-9_.@-]/g;

async function ensureDevDir() {
  await fs.mkdir(DEV_WALLET_DIR, { recursive: true });
}

function devWalletFile(userId) {
  const safeId = String(userId ?? '').replace(SAFE_ID_REGEXP, '_');
  return path.join(DEV_WALLET_DIR, `${safeId}.wallet.json`);
}

function devHistoryFile(userId) {
  const safeId = String(userId ?? '').replace(SAFE_ID_REGEXP, '_');
  return path.join(DEV_HISTORY_DIR, `${safeId}.history.json`);
}

let dbConnected = false;
try {
  await mongoose.connect(MONGODB_URI);
  dbConnected = true;
  console.log('Connected to MongoDB');
} catch (e) {
  console.warn('MongoDB not available, running in dev-only mode (pairing endpoints will work).');
}

let User = null;
if (dbConnected) {
  const userSchema = new mongoose.Schema({
    name: { type: String },
    username: { type: String, required: true, unique: true, index: true },
    email: { type: String }, // опционально
    passwordHash: { type: String, required: true },
  }, { timestamps: true });

  User = mongoose.model('User', userSchema);
}

function sign(user) {
  return jwt.sign({ sub: user._id, username: user.username }, JWT_SECRET, { expiresIn: '7d' });
}

app.post('/api/auth/register', async (req, res) => {
  if (!dbConnected) return res.status(503).json({ message: 'Database unavailable in dev mode' });
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
  if (!dbConnected) return res.status(503).json({ message: 'Database unavailable in dev mode' });
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

app.put('/api/dev-wallets/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'UserId is required' });
    const payload = req.body;
    if (!payload || typeof payload !== 'object') {
      return res.status(400).json({ message: 'Profile payload is required' });
    }

    await ensureDevDir();
    const filePath = devWalletFile(userId);
    await fs.writeFile(filePath, JSON.stringify(payload, null, 2), 'utf8');
    return res.status(204).end();
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/dev-wallets/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'UserId is required' });
    const filePath = devWalletFile(userId);
    try {
      const data = await fs.readFile(filePath, 'utf8');
      return res.status(200).json(JSON.parse(data));
    } catch (err) {
      if (err.code === 'ENOENT') return res.status(404).json({ message: 'Not found' });
      throw err;
    }
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.head('/api/dev-wallets/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).end();
    const filePath = devWalletFile(userId);
    try {
      await fs.access(filePath);
      return res.status(200).end();
    } catch (err) {
      if (err.code === 'ENOENT') return res.status(404).end();
      throw err;
    }
  } catch (e) {
    console.error(e);
    return res.status(500).end();
  }
});

app.delete('/api/dev-wallets/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'UserId is required' });
    const filePath = devWalletFile(userId);
    try {
      await fs.unlink(filePath);
    } catch (err) {
      if (err.code === 'ENOENT') return res.status(404).end();
      throw err;
    }
    return res.status(204).end();
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.get('/api/dev-wallet-history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'UserId is required' });
    await ensureDevDir();
    const filePath = devHistoryFile(userId);
    try {
      const data = await fs.readFile(filePath, 'utf8');
      return res.status(200).json(JSON.parse(data));
    } catch (err) {
      if (err.code === 'ENOENT') return res.status(404).json([]);
      throw err;
    }
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.put('/api/dev-wallet-history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: 'UserId is required' });
    const payload = req.body;
    if (!Array.isArray(payload)) {
      return res.status(400).json({ message: 'History payload must be an array' });
    }
    await ensureDevDir();
    const filePath = devHistoryFile(userId);
    await fs.writeFile(filePath, JSON.stringify(payload, null, 2), 'utf8');
    return res.status(204).end();
  } catch (e) {
    console.error(e);
    return res.status(500).json({ message: 'Server error' });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server listening on http://0.0.0.0:${PORT}`);
});
