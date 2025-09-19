const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const sharp = require('sharp');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
const Joi = require('joi');
const path = require('path');
const fs = require('fs').promises;
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'seangkatan_secret_key_2024';

// Database Configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'seangkatan_db',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

let db;

// Initialize Database Connection
async function initDatabase() {
  try {
    // First connect without specifying database
    const tempConfig = { ...dbConfig };
    delete tempConfig.database;
    
    const tempDb = mysql.createPool(tempConfig);
    console.log('Database connected successfully');
    
    // Create database if not exists
    await tempDb.execute(`CREATE DATABASE IF NOT EXISTS ${dbConfig.database}`);
    await tempDb.end();
    
    // Now connect with the database
    db = mysql.createPool(dbConfig);
    console.log('Database selected successfully');
    
    // Create tables
    await createTables();
  } catch (error) {
    console.error('Database connection failed:', error);
    throw error;
  }
}

// Create Tables
async function createTables() {
  const tables = [
    `CREATE TABLE IF NOT EXISTS users (
      id INT PRIMARY KEY AUTO_INCREMENT,
      username VARCHAR(50) UNIQUE NOT NULL,
      email VARCHAR(100) UNIQUE NOT NULL,
      password_hash VARCHAR(255) NOT NULL,
      role ENUM('owner', 'school_admin', 'teacher', 'parent', 'student') NOT NULL,
      full_name VARCHAR(100) NOT NULL,
      phone VARCHAR(20),
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )`,
    `CREATE TABLE IF NOT EXISTS classes (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(100) NOT NULL,
      grade_level VARCHAR(20) NOT NULL,
      academic_year VARCHAR(20) NOT NULL,
      teacher_id INT,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (teacher_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS events (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(200) NOT NULL,
      description TEXT,
      type ENUM('parent_meeting', 'class_competition') NOT NULL,
      event_date DATE NOT NULL,
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      location VARCHAR(200),
      created_by INT NOT NULL,
      max_participants INT DEFAULT 0,
      status ENUM('active', 'cancelled', 'completed') DEFAULT 'active',
      class_id INT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (created_by) REFERENCES users(id),
      FOREIGN KEY (class_id) REFERENCES classes(id)
    )`,
    `CREATE TABLE IF NOT EXISTS event_bookings (
      id INT PRIMARY KEY AUTO_INCREMENT,
      event_id INT NOT NULL,
      user_id INT NOT NULL,
      student_id INT,
      time_slot DATETIME NOT NULL,
      status ENUM('pending', 'confirmed', 'cancelled') DEFAULT 'pending',
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (student_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS quizzes (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(200) NOT NULL,
      description TEXT,
      category ENUM('reading', 'writing', 'math', 'science') NOT NULL,
      difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
      time_limit INT DEFAULT 0,
      created_by INT NOT NULL,
      class_id INT,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (created_by) REFERENCES users(id),
      FOREIGN KEY (class_id) REFERENCES classes(id)
    )`,
    `CREATE TABLE IF NOT EXISTS quiz_questions (
      id INT PRIMARY KEY AUTO_INCREMENT,
      quiz_id INT,
      question TEXT NOT NULL,
      type ENUM('multiple_choice', 'true_false', 'fill_blank') NOT NULL,
      options JSON,
      correct_answer TEXT NOT NULL,
      points INT DEFAULT 1,
      difficulty ENUM('easy', 'medium', 'hard') DEFAULT 'medium',
      explanation TEXT,
      order_number INT DEFAULT 1,
      created_by INT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE,
      FOREIGN KEY (created_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS quiz_question_options (
      id INT PRIMARY KEY AUTO_INCREMENT,
      question_id INT NOT NULL,
      option_text VARCHAR(500) NOT NULL,
      option_order INT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (question_id) REFERENCES quiz_questions(id) ON DELETE CASCADE
    )`,
    `CREATE TABLE IF NOT EXISTS quiz_attempts (
      id INT PRIMARY KEY AUTO_INCREMENT,
      quiz_id INT NOT NULL,
      student_id INT NOT NULL,
      total_score INT DEFAULT 0,
      max_score INT NOT NULL,
      percentage DECIMAL(5,2) DEFAULT 0,
      time_spent INT DEFAULT 0,
      completed_at TIMESTAMP NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
      FOREIGN KEY (student_id) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS quiz_answers (
      id INT PRIMARY KEY AUTO_INCREMENT,
      attempt_id INT NOT NULL,
      question_id INT NOT NULL,
      answer TEXT,
      is_correct BOOLEAN DEFAULT FALSE,
      points INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE,
      FOREIGN KEY (question_id) REFERENCES quiz_questions(id)
    )`,
    `CREATE TABLE IF NOT EXISTS badges (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(100) NOT NULL,
      description TEXT,
      icon VARCHAR(255),
      category VARCHAR(50),
      criteria_type ENUM('quiz_score', 'quiz_count', 'streak') NOT NULL,
      criteria_value INT NOT NULL,
      criteria_category VARCHAR(50),
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,
    `CREATE TABLE IF NOT EXISTS user_badges (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      badge_id INT NOT NULL,
      quiz_attempt_id INT,
      earned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (badge_id) REFERENCES badges(id),
      FOREIGN KEY (quiz_attempt_id) REFERENCES quiz_attempts(id),
      UNIQUE KEY unique_user_badge (user_id, badge_id)
    )`,
    `CREATE TABLE IF NOT EXISTS posts (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(200) NOT NULL,
      description TEXT,
      type ENUM('artwork', 'assignment', 'project') NOT NULL,
      media_files JSON,
      author_id INT NOT NULL,
      class_id INT,
      subject VARCHAR(100),
      tags JSON,
      status ENUM('draft', 'pending', 'approved', 'rejected') DEFAULT 'pending',
      approved_by INT,
      approved_at TIMESTAMP NULL,
      likes JSON,
      views INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (author_id) REFERENCES users(id),
      FOREIGN KEY (class_id) REFERENCES classes(id),
      FOREIGN KEY (approved_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS comments (
      id INT PRIMARY KEY AUTO_INCREMENT,
      post_id INT NOT NULL,
      author_id INT NOT NULL,
      content TEXT NOT NULL,
      parent_comment_id INT,
      status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending',
      moderated_by INT,
      moderated_at TIMESTAMP NULL,
      likes JSON,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
      FOREIGN KEY (author_id) REFERENCES users(id),
      FOREIGN KEY (parent_comment_id) REFERENCES comments(id),
      FOREIGN KEY (moderated_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS albums (
      id INT PRIMARY KEY AUTO_INCREMENT,
      title VARCHAR(200) NOT NULL,
      description TEXT,
      cover_photo VARCHAR(255),
      class_id INT,
      created_by INT NOT NULL,
      is_public BOOLEAN DEFAULT TRUE,
      allow_download BOOLEAN DEFAULT TRUE,
      tags JSON,
      photo_count INT DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (class_id) REFERENCES classes(id),
      FOREIGN KEY (created_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS photos (
      id INT PRIMARY KEY AUTO_INCREMENT,
      album_id INT NOT NULL,
      filename VARCHAR(255) NOT NULL,
      original_name VARCHAR(255) NOT NULL,
      path VARCHAR(500) NOT NULL,
      thumbnail_path VARCHAR(500),
      watermarked_path VARCHAR(500),
      size INT NOT NULL,
      width INT,
      height INT,
      uploaded_by INT NOT NULL,
      caption TEXT,
      tags JSON,
      likes JSON,
      views INT DEFAULT 0,
      uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE,
      FOREIGN KEY (uploaded_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS chat_rooms (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(200) NOT NULL,
      type ENUM('class_chat', 'parent_channel', 'teacher_room') NOT NULL,
      class_id INT,
      description TEXT,
      members JSON,
      moderators JSON,
      settings JSON,
      is_active BOOLEAN DEFAULT TRUE,
      created_by INT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (class_id) REFERENCES classes(id),
      FOREIGN KEY (created_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS messages (
      id INT PRIMARY KEY AUTO_INCREMENT,
      room_id INT NOT NULL,
      sender_id INT NOT NULL,
      content TEXT,
      type ENUM('text', 'sticker', 'file', 'image') DEFAULT 'text',
      file_data JSON,
      sticker_id INT,
      reply_to INT,
      is_edited BOOLEAN DEFAULT FALSE,
      edited_at TIMESTAMP NULL,
      is_deleted BOOLEAN DEFAULT FALSE,
      deleted_by INT,
      deleted_at TIMESTAMP NULL,
      reactions JSON,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (room_id) REFERENCES chat_rooms(id) ON DELETE CASCADE,
      FOREIGN KEY (sender_id) REFERENCES users(id),
      FOREIGN KEY (reply_to) REFERENCES messages(id),
      FOREIGN KEY (deleted_by) REFERENCES users(id)
    )`,
    `CREATE TABLE IF NOT EXISTS stickers (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(100) NOT NULL,
      category VARCHAR(50) NOT NULL,
      image_path VARCHAR(255) NOT NULL,
      image_url VARCHAR(255),
      pack_name VARCHAR(100) DEFAULT 'default',
      description TEXT,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )`,
    `CREATE TABLE IF NOT EXISTS user_chat_settings (
      id INT PRIMARY KEY AUTO_INCREMENT,
      user_id INT NOT NULL,
      notifications_enabled BOOLEAN DEFAULT TRUE,
      sound_enabled BOOLEAN DEFAULT TRUE,
      theme ENUM('light', 'dark') DEFAULT 'light',
      font_size ENUM('small', 'medium', 'large') DEFAULT 'medium',
      auto_download_media BOOLEAN DEFAULT TRUE,
      show_read_receipts BOOLEAN DEFAULT TRUE,
      language VARCHAR(10) DEFAULT 'id',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
      UNIQUE KEY unique_user (user_id)
    )`
  ];
  
  for (const table of tables) {
    await db.execute(table);
  }
  
  console.log('All tables created successfully');
}

// Middleware
app.use(helmet());
app.use(compression());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// File upload configuration
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif|pdf|doc|docx/;
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);
    
    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// Create uploads directory
async function createUploadsDir() {
  const dirs = ['uploads', 'uploads/images', 'uploads/documents', 'uploads/watermarked', 'uploads/thumbnails', 'uploads/photos', 'uploads/photos/thumbnails'];
  for (const dir of dirs) {
    try {
      await fs.mkdir(dir, { recursive: true });
    } catch (error) {
      // Directory already exists
    }
  }
}

// Static file serving
app.use('/uploads', express.static('uploads'));
app.use(express.static('public'));

// Validation Schemas
const schemas = {
  register: Joi.object({
    username: Joi.string().alphanum().min(3).max(50).required(),
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
    role: Joi.string().valid('owner', 'school_admin', 'teacher', 'parent', 'student').required(),
    full_name: Joi.string().min(2).max(100).required(),
    phone: Joi.string().optional()
  }),
  login: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
  }),
  event: Joi.object({
    title: Joi.string().min(3).max(200).required(),
    description: Joi.string().optional(),
    type: Joi.string().valid('parent_meeting', 'class_competition').required(),
    event_date: Joi.date().required(),
    start_time: Joi.string().required(),
    end_time: Joi.string().required(),
    location: Joi.string().max(200).optional(),
    max_participants: Joi.number().integer().min(0).optional(),
    class_id: Joi.number().integer().optional()
  }),
  quiz: Joi.object({
    title: Joi.string().min(3).max(200).required(),
    description: Joi.string().optional(),
    category: Joi.string().valid('reading', 'writing', 'math', 'science').required(),
    difficulty: Joi.string().valid('easy', 'medium', 'hard').required(),
    time_limit: Joi.number().integer().min(0).optional(),
    class_id: Joi.number().integer().required()
  }),
  post: Joi.object({
    title: Joi.string().min(3).max(200).required(),
    description: Joi.string().min(10).required(),
    type: Joi.string().valid('artwork', 'assignment', 'project').required(),
    class_id: Joi.number().integer().optional(),
    subject: Joi.string().max(100).optional(),
    tags: Joi.array().items(Joi.string()).optional()
  }),
  album: Joi.object({
    title: Joi.string().min(3).max(200).required(),
    description: Joi.string().optional(),
    class_id: Joi.number().integer().optional(),
    is_public: Joi.boolean().optional(),
    allow_download: Joi.boolean().optional(),
    tags: Joi.array().items(Joi.string()).optional()
  }),
  chatRoom: Joi.object({
    name: Joi.string().min(3).max(200).required(),
    type: Joi.string().valid('class_chat', 'parent_channel', 'teacher_room', 'general').required(),
    class_id: Joi.number().integer().optional(),
    description: Joi.string().optional()
  }),
  quizQuestion: Joi.object({
    question: Joi.string().min(5).max(1000).required(),
    type: Joi.string().valid('multiple_choice', 'true_false', 'fill_blank').required(),
    options: Joi.array().items(Joi.string()).when('type', {
      is: 'multiple_choice',
      then: Joi.array().items(Joi.string()).min(2).max(6).required(),
      otherwise: Joi.optional()
    }),
    correct_answer: Joi.string().required(),
    points: Joi.number().integer().min(1).max(100).default(10),
    explanation: Joi.string().optional()
  }),
  eventBooking: Joi.object({
    student_id: Joi.number().integer().optional(),
    time_slot: Joi.string().optional(),
    notes: Joi.string().optional()
  }),
  class: Joi.object({
    name: Joi.string().min(3).max(100).required(),
    grade_level: Joi.string().min(1).max(20).required(),
    academic_year: Joi.string().min(4).max(20).required(),
    teacher_id: Joi.number().integer().optional()
  }),
  badge: Joi.object({
    name: Joi.string().min(3).max(100).required(),
    description: Joi.string().optional(),
    icon: Joi.string().optional(),
    category: Joi.string().max(50).optional(),
    criteria_type: Joi.string().valid('quiz_score', 'quiz_count', 'streak').required(),
    criteria_value: Joi.number().integer().min(1).required(),
    criteria_category: Joi.string().max(50).optional()
  }),
  sticker: Joi.object({
    name: Joi.string().min(3).max(100).required(),
    image_url: Joi.string().required(),
    category: Joi.string().min(3).max(50).required(),
    pack_name: Joi.string().max(100).optional(),
    description: Joi.string().optional()
  }),
  userChatSettings: Joi.object({
    notifications_enabled: Joi.boolean().optional(),
    sound_enabled: Joi.boolean().optional(),
    theme: Joi.string().valid('light', 'dark').optional(),
    font_size: Joi.string().valid('small', 'medium', 'large').optional(),
    auto_download_media: Joi.boolean().optional(),
    show_read_receipts: Joi.boolean().optional(),
    language: Joi.string().valid('id', 'en').optional()
  })
};

// Authentication Middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const [rows] = await db.execute('SELECT * FROM users WHERE id = ? AND is_active = TRUE', [decoded.userId]);
    
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid token or user not found' });
    }

    req.user = rows[0];
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid or expired token' });
  }
};

// Authorization Middleware
const authorize = (roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    next();
  };
};

// Validation Middleware
const validate = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    next();
  };
};

// Error Handler
const errorHandler = (err, req, res, next) => {
  console.error(err.stack);
  
  if (err.name === 'ValidationError') {
    return res.status(400).json({ error: err.message });
  }
  
  if (err.code === 'ER_DUP_ENTRY') {
    return res.status(409).json({ error: 'Duplicate entry' });
  }
  
  if (err.name === 'MulterError') {
    return res.status(400).json({ error: 'File upload error: ' + err.message });
  }
  
  res.status(500).json({ error: 'Internal server error' });
};

// Utility Functions
const generateToken = (userId, role) => {
  return jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: '24h' });
};

const hashPassword = async (password) => {
  return await bcrypt.hash(password, 12);
};

const comparePassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};

const addWatermark = async (inputBuffer, outputPath) => {
  try {
    await sharp(inputBuffer)
      .composite([{
        input: Buffer.from(`<svg width="200" height="50">
          <text x="10" y="30" font-family="Arial" font-size="16" fill="rgba(255,255,255,0.7)">SEANGKATAN</text>
        </svg>`),
        gravity: 'southeast'
      }])
      .jpeg({ quality: 90 })
      .toFile(outputPath);
    return outputPath;
  } catch (error) {
    console.error('Watermark error:', error);
    return null;
  }
};

const createThumbnail = async (inputBuffer, outputPath) => {
  try {
    await sharp(inputBuffer)
      .resize(300, 300, { fit: 'cover' })
      .jpeg({ quality: 80 })
      .toFile(outputPath);
    return outputPath;
  } catch (error) {
    console.error('Thumbnail error:', error);
    return null;
  }
};

// ==================== AUTHENTICATION ROUTES ====================

// Register
app.post('/api/auth/register', validate(schemas.register), async (req, res) => {
  try {
    const { username, email, password, role, full_name, phone } = req.body;
    
    // Debug logging
    console.log('Register request body:', { username, email, password: '***', role, full_name, phone });
    
    // Check if user already exists
    const [existing] = await db.execute('SELECT id FROM users WHERE email = ? OR username = ?', [email, username]);
    if (existing.length > 0) {
      return res.status(409).json({ error: 'User already exists' });
    }
    
    const hashedPassword = await hashPassword(password);
    
    // Debug parameters
    const params = [username, email, hashedPassword, role, full_name, phone || null];
    console.log('SQL parameters:', params.map((p, i) => `${i}: ${p === null ? 'NULL' : typeof p} - ${p === null ? 'null' : p}`));
    
    const [result] = await db.execute(
      'INSERT INTO users (username, email, password_hash, role, full_name, phone) VALUES (?, ?, ?, ?, ?, ?)',
      params
    );
    
    const token = generateToken(result.insertId, role);
    
    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: result.insertId,
        username,
        email,
        role,
        full_name
      }
    });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: 'Registration failed' });
  }
});

// Login
app.post('/api/auth/login', validate(schemas.login), async (req, res) => {
  try {
    const { email, password } = req.body;
    
    const [rows] = await db.execute('SELECT * FROM users WHERE email = ? AND is_active = TRUE', [email]);
    
    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const user = rows[0];
    const isValidPassword = await comparePassword(password, user.password_hash);
    
    if (!isValidPassword) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }
    
    const token = generateToken(user.id, user.role);
    
    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        role: user.role,
        full_name: user.full_name
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed' });
  }
});

// Get Profile
app.get('/api/auth/profile', authenticateToken, async (req, res) => {
  try {
    const { password_hash, ...userProfile } = req.user;
    res.json({ user: userProfile });
  } catch (error) {
    console.error('Profile error:', error);
    res.status(500).json({ error: 'Failed to get profile' });
  }
});

// Update Profile
app.put('/api/auth/profile', authenticateToken, async (req, res) => {
  try {
    const { full_name, phone, bio } = req.body;
    const userId = req.user.id;
    
    // Build update query dynamically
    const updates = [];
    const values = [];
    
    if (full_name !== undefined) {
      updates.push('full_name = ?');
      values.push(full_name);
    }
    
    if (phone !== undefined) {
      updates.push('phone = ?');
      values.push(phone);
    }
    
    if (bio !== undefined) {
      updates.push('bio = ?');
      values.push(bio);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }
    
    values.push(userId);
    
    await db.execute(
      `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP WHERE id = ?`,
      values
    );
    
    // Get updated user profile
    const [rows] = await db.execute('SELECT * FROM users WHERE id = ?', [userId]);
    const { password_hash, ...userProfile } = rows[0];
    
    res.json({
      message: 'Profile updated successfully',
      user: userProfile
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// ==================== EVENT PLANNER ROUTES ====================

// Get Events
app.get('/api/events', authenticateToken, async (req, res) => {
  try {
    const { type, class_id, status = 'active' } = req.query;
    let query = `
      SELECT e.*, u.full_name as creator_name, c.name as class_name,
             (SELECT COUNT(*) FROM event_bookings WHERE event_id = e.id AND status = 'confirmed') as confirmed_bookings
      FROM events e 
      LEFT JOIN users u ON e.created_by = u.id 
      LEFT JOIN classes c ON e.class_id = c.id 
      WHERE e.status = ?
    `;
    const params = [status];
    
    if (type) {
      query += ' AND e.type = ?';
      params.push(type);
    }
    
    if (class_id) {
      query += ' AND e.class_id = ?';
      params.push(class_id);
    }
    
    // Role-based filtering
    if (req.user.role === 'student' || req.user.role === 'parent') {
      query += ' AND (e.class_id IS NULL OR e.class_id IN (SELECT id FROM classes WHERE id = ?))';
      params.push(class_id || 0);
    }
    
    query += ' ORDER BY e.event_date ASC, e.start_time ASC';
    
    const [events] = await db.execute(query, params);
    res.json({ events });
  } catch (error) {
    console.error('Get events error:', error);
    res.status(500).json({ error: 'Failed to get events' });
  }
});

// Create Event
app.post('/api/events', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.event), async (req, res) => {
  try {
    const { title, description, type, event_date, start_time, end_time, location, max_participants, class_id } = req.body;
    
    const [result] = await db.execute(
      `INSERT INTO events (title, description, type, event_date, start_time, end_time, location, 
       created_by, max_participants, class_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [title, description, type, event_date, start_time, end_time, location, req.user.id, max_participants, class_id || null]
    );
    
    res.status(201).json({
      message: 'Event created successfully',
      event_id: result.insertId
    });
  } catch (error) {
    console.error('Create event error:', error);
    res.status(500).json({ error: 'Failed to create event' });
  }
});

// Update Event
app.put('/api/events/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.event), async (req, res) => {
  try {
    const eventId = req.params.id;
    const { title, description, type, event_date, start_time, end_time, location, max_participants, class_id } = req.body;
    
    // Check if event exists and user has permission
    const [events] = await db.execute('SELECT * FROM events WHERE id = ?', [eventId]);
    if (events.length === 0) {
      return res.status(404).json({ error: 'Event not found' });
    }
    
    // Check if user is the creator or has admin rights
    if (events[0].created_by !== req.user.id && !['owner', 'school_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized to update this event' });
    }
    
    await db.execute(
      `UPDATE events SET title = ?, description = ?, type = ?, event_date = ?, start_time = ?, 
       end_time = ?, location = ?, max_participants = ?, class_id = ?, updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`,
      [title, description, type, event_date, start_time, end_time, location, max_participants, class_id || null, eventId]
    );
    
    res.json({ message: 'Event updated successfully' });
  } catch (error) {
    console.error('Update event error:', error);
    res.status(500).json({ error: 'Failed to update event' });
  }
});

// Book Event
app.post('/api/events/:id/book', authenticateToken, validate(schemas.eventBooking), async (req, res) => {
  try {
    const eventId = req.params.id;
    const { student_id, time_slot, notes } = req.body;
    
    // Check if event exists and is active
    const [events] = await db.execute('SELECT * FROM events WHERE id = ? AND status = "active"', [eventId]);
    if (events.length === 0) {
      return res.status(404).json({ error: 'Event not found or not active' });
    }
    
    // Check if already booked
    const [existing] = await db.execute(
      'SELECT id FROM event_bookings WHERE event_id = ? AND user_id = ? AND status != "cancelled"',
      [eventId, req.user.id]
    );
    
    if (existing.length > 0) {
      return res.status(409).json({ error: 'Already booked for this event' });
    }
    
    const [result] = await db.execute(
      'INSERT INTO event_bookings (event_id, user_id, student_id, time_slot, notes) VALUES (?, ?, ?, ?, ?)',
      [eventId, req.user.id, student_id || null, time_slot || null, notes || null]
    );
    
    res.status(201).json({
      message: 'Event booked successfully',
      booking_id: result.insertId
    });
  } catch (error) {
    console.error('Book event error:', error);
    res.status(500).json({ error: 'Failed to book event' });
  }
});

// Get Event Bookings
app.get('/api/events/:id/bookings', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const eventId = req.params.id;
    
    const [bookings] = await db.execute(`
      SELECT eb.*, u.full_name as user_name, u.email as user_email,
             s.full_name as student_name
      FROM event_bookings eb
      LEFT JOIN users u ON eb.user_id = u.id
      LEFT JOIN users s ON eb.student_id = s.id
      WHERE eb.event_id = ?
      ORDER BY eb.created_at DESC
    `, [eventId]);
    
    res.json({ bookings });
  } catch (error) {
    console.error('Get bookings error:', error);
    res.status(500).json({ error: 'Failed to get bookings' });
  }
});

// ==================== QUIZ INTERAKTIF ROUTES ====================

// Get Quizzes
app.get('/api/quizzes', authenticateToken, async (req, res) => {
  try {
    const { category, difficulty, class_id } = req.query;
    let query = `
      SELECT q.*, u.full_name as creator_name, c.name as class_name,
             (SELECT COUNT(*) FROM quiz_questions WHERE quiz_id = q.id) as question_count,
             (SELECT COUNT(*) FROM quiz_attempts WHERE quiz_id = q.id) as attempt_count
      FROM quizzes q 
      LEFT JOIN users u ON q.created_by = u.id 
      LEFT JOIN classes c ON q.class_id = c.id 
      WHERE q.is_active = TRUE
    `;
    const params = [];
    
    if (category) {
      query += ' AND q.category = ?';
      params.push(category);
    }
    
    if (difficulty) {
      query += ' AND q.difficulty = ?';
      params.push(difficulty);
    }
    
    if (class_id) {
      query += ' AND q.class_id = ?';
      params.push(class_id);
    }
    
    query += ' ORDER BY q.created_at DESC';
    
    const [quizzes] = await db.execute(query, params);
    res.json({ quizzes });
  } catch (error) {
    console.error('Get quizzes error:', error);
    res.status(500).json({ error: 'Failed to get quizzes' });
  }
});

// Create Quiz
app.post('/api/quizzes', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.quiz), async (req, res) => {
  try {
    const { title, description, category, difficulty, time_limit, class_id } = req.body;
    
    const [result] = await db.execute(
      'INSERT INTO quizzes (title, description, category, difficulty, time_limit, created_by, class_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [title, description, category, difficulty, time_limit, req.user.id, class_id || null]
    );
    
    res.status(201).json({
      message: 'Quiz created successfully',
      quiz_id: result.insertId
    });
  } catch (error) {
    console.error('Create quiz error:', error);
    res.status(500).json({ error: 'Failed to create quiz' });
  }
});

// Update Quiz
app.put('/api/quizzes/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.quiz), async (req, res) => {
  try {
    const quizId = req.params.id;
    const { title, description, category, difficulty, time_limit, class_id } = req.body;
    
    // Check if quiz exists and user has permission
    const [quizzes] = await db.execute('SELECT * FROM quizzes WHERE id = ?', [quizId]);
    if (quizzes.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }
    
    // Check if user is the creator or has admin rights
    if (quizzes[0].created_by !== req.user.id && !['owner', 'school_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized to update this quiz' });
    }
    
    await db.execute(
      'UPDATE quizzes SET title = ?, description = ?, category = ?, difficulty = ?, time_limit = ?, class_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [title, description, category, difficulty, time_limit, class_id || null, quizId]
    );
    
    res.json({ message: 'Quiz updated successfully' });
  } catch (error) {
    console.error('Update quiz error:', error);
    res.status(500).json({ error: 'Failed to update quiz' });
  }
});

// Add Quiz Question
app.post('/api/quizzes/:id/questions', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.quizQuestion), async (req, res) => {
  try {
    const quizId = req.params.id;
    const { question, type, correct_answer, points, explanation, options } = req.body;
    
    // Get next question order
    const [orderResult] = await db.execute('SELECT COALESCE(MAX(question_order), 0) + 1 as next_order FROM quiz_questions WHERE quiz_id = ?', [quizId]);
    const questionOrder = orderResult[0].next_order;
    
    const [result] = await db.execute(
      'INSERT INTO quiz_questions (quiz_id, question, type, correct_answer, points, explanation, question_order) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [quizId, question, type, correct_answer, points || 1, explanation, questionOrder]
    );
    
    // Add options for multiple choice questions
    if (type === 'multiple_choice' && options && options.length > 0) {
      for (let i = 0; i < options.length; i++) {
        await db.execute(
          'INSERT INTO quiz_question_options (question_id, option_text, option_order) VALUES (?, ?, ?)',
          [result.insertId, options[i], i + 1]
        );
      }
    }
    
    res.status(201).json({
      message: 'Question added successfully',
      question_id: result.insertId
    });
  } catch (error) {
    console.error('Add question error:', error);
    res.status(500).json({ error: 'Failed to add question' });
  }
});

// Start Quiz Attempt
app.post('/api/quizzes/:id/attempt', authenticateToken, authorize(['student']), async (req, res) => {
  try {
    const quizId = req.params.id;
    
    // Get quiz details and questions
    const [quiz] = await db.execute('SELECT * FROM quizzes WHERE id = ? AND is_active = TRUE', [quizId]);
    if (quiz.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }
    
    const [questions] = await db.execute(`
      SELECT qq.*, GROUP_CONCAT(qo.option_text ORDER BY qo.option_order) as options
      FROM quiz_questions qq
      LEFT JOIN quiz_question_options qo ON qq.id = qo.question_id
      WHERE qq.quiz_id = ?
      GROUP BY qq.id
      ORDER BY qq.question_order
    `, [quizId]);
    
    const maxScore = questions.reduce((sum, q) => sum + q.points, 0);
    
    const [result] = await db.execute(
      'INSERT INTO quiz_attempts (quiz_id, student_id, max_score) VALUES (?, ?, ?)',
      [quizId, req.user.id, maxScore]
    );
    
    // Format questions for response (hide correct answers)
    const formattedQuestions = questions.map(q => ({
      id: q.id,
      question: q.question,
      type: q.type,
      points: q.points,
      options: q.options ? q.options.split(',') : null
    }));
    
    res.status(201).json({
      message: 'Quiz attempt started',
      attempt_id: result.insertId,
      quiz: quiz[0],
      questions: formattedQuestions
    });
  } catch (error) {
    console.error('Start attempt error:', error);
    res.status(500).json({ error: 'Failed to start quiz attempt' });
  }
});

// Submit Quiz Answer
app.post('/api/attempts/:id/answer', authenticateToken, async (req, res) => {
  try {
    const attemptId = req.params.id;
    const { question_id, answer } = req.body;
    
    // Get question details
    const [questions] = await db.execute('SELECT * FROM quiz_questions WHERE id = ?', [question_id]);
    if (questions.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }
    
    const question = questions[0];
    const isCorrect = answer.toLowerCase().trim() === question.correct_answer.toLowerCase().trim();
    const points = isCorrect ? question.points : 0;
    
    await db.execute(
      'INSERT INTO quiz_answers (attempt_id, question_id, answer, is_correct, points) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE answer = VALUES(answer), is_correct = VALUES(is_correct), points = VALUES(points)',
      [attemptId, question_id, answer, isCorrect, points]
    );
    
    res.json({
      message: 'Answer submitted',
      is_correct: isCorrect,
      points: points
    });
  } catch (error) {
    console.error('Submit answer error:', error);
    res.status(500).json({ error: 'Failed to submit answer' });
  }
});

// Complete Quiz Attempt
app.post('/api/attempts/:id/complete', authenticateToken, async (req, res) => {
  try {
    const attemptId = req.params.id;
    const { time_spent } = req.body;
    
    // Calculate total score
    const [scoreResult] = await db.execute(
      'SELECT SUM(points) as total_score, COUNT(*) as answered_questions FROM quiz_answers WHERE attempt_id = ?',
      [attemptId]
    );
    
    const totalScore = scoreResult[0].total_score || 0;
    
    // Get max score
    const [attemptResult] = await db.execute('SELECT max_score FROM quiz_attempts WHERE id = ?', [attemptId]);
    const maxScore = attemptResult[0].max_score;
    const percentage = (totalScore / maxScore) * 100;
    
    // Update attempt
    await db.execute(
      'UPDATE quiz_attempts SET total_score = ?, percentage = ?, time_spent = ?, completed_at = NOW() WHERE id = ?',
      [totalScore, percentage, time_spent, attemptId]
    );
    
    // Check for badges
    await checkAndAwardBadges(req.user.id, attemptId, percentage);
    
    res.json({
      message: 'Quiz completed',
      total_score: totalScore,
      max_score: maxScore,
      percentage: percentage.toFixed(2)
    });
  } catch (error) {
    console.error('Complete attempt error:', error);
    res.status(500).json({ error: 'Failed to complete quiz' });
  }
});

// Get User Badges
app.get('/api/users/:id/badges', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.id;
    
    // Check if user can view badges
    if (req.user.id != userId && !['owner', 'school_admin', 'teacher'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
    const [badges] = await db.execute(`
      SELECT b.*, ub.earned_at
      FROM user_badges ub
      JOIN badges b ON ub.badge_id = b.id
      WHERE ub.user_id = ?
      ORDER BY ub.earned_at DESC
    `, [userId]);
    
    res.json({ badges });
  } catch (error) {
    console.error('Get badges error:', error);
    res.status(500).json({ error: 'Failed to get badges' });
  }
});

// Badge checking function
async function checkAndAwardBadges(userId, attemptId, percentage) {
  try {
    const [badges] = await db.execute('SELECT * FROM badges WHERE is_active = TRUE');
    
    for (const badge of badges) {
      let shouldAward = false;
      
      if (badge.criteria_type === 'quiz_score' && percentage >= badge.criteria_value) {
        shouldAward = true;
      } else if (badge.criteria_type === 'quiz_count') {
        const [countResult] = await db.execute(
          'SELECT COUNT(*) as count FROM quiz_attempts WHERE student_id = ? AND completed_at IS NOT NULL',
          [userId]
        );
        if (countResult[0].count >= badge.criteria_value) {
          shouldAward = true;
        }
      }
      
      if (shouldAward) {
        // Check if user already has this badge
        const [existing] = await db.execute(
          'SELECT id FROM user_badges WHERE user_id = ? AND badge_id = ?',
          [userId, badge.id]
        );
        
        if (existing.length === 0) {
          await db.execute(
            'INSERT INTO user_badges (user_id, badge_id, quiz_attempt_id) VALUES (?, ?, ?)',
            [userId, badge.id, attemptId]
          );
        }
      }
    }
  } catch (error) {
    console.error('Badge check error:', error);
  }
}

// ==================== MADING ONLINE ROUTES ====================

// Get Posts
app.get('/api/posts', authenticateToken, async (req, res) => {
  try {
    const { type, class_id, status = 'approved', author_id } = req.query;
    let query = `
      SELECT p.*, u.full_name as author_name, c.name as class_name,
             a.full_name as approved_by_name
      FROM posts p 
      LEFT JOIN users u ON p.author_id = u.id 
      LEFT JOIN classes c ON p.class_id = c.id 
      LEFT JOIN users a ON p.approved_by = a.id
      WHERE 1=1
    `;
    const params = [];
    
    // Role-based filtering
    if (req.user.role === 'student') {
      query += ' AND (p.status = "approved" OR p.author_id = ?)';
      params.push(req.user.id);
    } else if (req.user.role === 'parent') {
      query += ' AND p.status = "approved"';
    } else {
      if (status) {
        query += ' AND p.status = ?';
        params.push(status);
      }
    }
    
    if (type && type.trim() !== '') {
      query += ' AND p.type = ?';
      params.push(type);
    }
    
    if (class_id) {
      query += ' AND p.class_id = ?';
      params.push(class_id);
    }
    
    if (author_id) {
      query += ' AND p.author_id = ?';
      params.push(author_id);
    }
    
    query += ' ORDER BY p.created_at DESC';
    
    const [posts] = await db.execute(query, params);
    
    // Parse JSON fields
    posts.forEach(post => {
      post.media_files = post.media_files ? JSON.parse(post.media_files) : [];
      post.tags = post.tags ? JSON.parse(post.tags) : [];
      post.likes = post.likes ? JSON.parse(post.likes) : [];
    });
    
    res.json({ success: true, posts });
  } catch (error) {
    console.error('Get posts error:', error);
    res.status(500).json({ success: false, error: 'Failed to get posts' });
  }
});

// Create Post
app.post('/api/posts', authenticateToken, authorize(['student', 'teacher']), upload.array('files', 5), validate(schemas.post), async (req, res) => {
  try {
    const { title, description, type, class_id, subject, tags } = req.body;
    const files = req.files || [];
    
    // Process uploaded files
    const mediaFiles = [];
    for (const file of files) {
      const filename = `${Date.now()}_${file.originalname}`;
      const filepath = path.join('uploads/documents', filename);
      
      await fs.promises.writeFile(filepath, file.buffer);
      
      mediaFiles.push({
        filename: filename,
        original_name: file.originalname,
        path: filepath,
        size: file.size,
        mimetype: file.mimetype
      });
    }
    
    const [result] = await db.execute(
      'INSERT INTO posts (title, description, type, media_files, author_id, class_id, subject, tags) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [title, description, type, JSON.stringify(mediaFiles), req.user.id, class_id || null, subject || null, JSON.stringify(tags || [])]
    );
    
    res.status(201).json({
      message: 'Post created successfully',
      post_id: result.insertId
    });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Update Post
app.put('/api/posts/:id', authenticateToken, authorize(['student', 'teacher']), upload.array('files', 5), validate(schemas.post), async (req, res) => {
  try {
    const postId = req.params.id;
    const { title, description, type, class_id, subject, tags } = req.body;
    const files = req.files || [];
    
    // Check if post exists and user has permission
    const [posts] = await db.execute('SELECT * FROM posts WHERE id = ?', [postId]);
    if (posts.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }
    
    // Check if user is the author or has admin rights
    if (posts[0].author_id !== req.user.id && !['owner', 'school_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Not authorized to update this post' });
    }
    
    // Process uploaded files if any
    let mediaFiles = posts[0].media_files ? JSON.parse(posts[0].media_files) : [];
    
    if (files.length > 0) {
      const newMediaFiles = [];
      for (const file of files) {
        const filename = `${Date.now()}_${file.originalname}`;
        const filepath = path.join('uploads/documents', filename);
        
        await fs.promises.writeFile(filepath, file.buffer);
        
        newMediaFiles.push({
          filename: filename,
          original_name: file.originalname,
          path: filepath,
          size: file.size,
          mimetype: file.mimetype
        });
      }
      mediaFiles = [...mediaFiles, ...newMediaFiles];
    }
    
    await db.execute(
      'UPDATE posts SET title = ?, description = ?, type = ?, media_files = ?, class_id = ?, subject = ?, tags = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [title, description, type, JSON.stringify(mediaFiles), class_id || null, subject, JSON.stringify(tags || []), postId]
    );
    
    res.json({ message: 'Post updated successfully' });
  } catch (error) {
    console.error('Update post error:', error);
    res.status(500).json({ error: 'Failed to update post' });
  }
});

// Approve/Reject Post
app.patch('/api/posts/:id/moderate', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const postId = req.params.id;
    const { status } = req.body; // 'approved' or 'rejected'
    
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }
    
    await db.execute(
      'UPDATE posts SET status = ?, approved_by = ?, approved_at = NOW() WHERE id = ?',
      [status, req.user.id, postId]
    );
    
    res.json({ message: `Post ${status} successfully` });
  } catch (error) {
    console.error('Moderate post error:', error);
    res.status(500).json({ error: 'Failed to moderate post' });
  }
});

// Like Post
app.post('/api/posts/:id/like', authenticateToken, async (req, res) => {
  try {
    const postId = req.params.id;
    
    const [posts] = await db.execute('SELECT likes FROM posts WHERE id = ?', [postId]);
    if (posts.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }
    
    let likes = posts[0].likes ? JSON.parse(posts[0].likes) : [];
    const userIndex = likes.indexOf(req.user.id);
    
    if (userIndex > -1) {
      likes.splice(userIndex, 1); // Unlike
    } else {
      likes.push(req.user.id); // Like
    }
    
    await db.execute('UPDATE posts SET likes = ? WHERE id = ?', [JSON.stringify(likes), postId]);
    
    res.json({ 
      message: userIndex > -1 ? 'Post unliked' : 'Post liked',
      likes_count: likes.length
    });
  } catch (error) {
    console.error('Like post error:', error);
    res.status(500).json({ error: 'Failed to like post' });
  }
});

// Add Comment
app.post('/api/posts/:id/comments', authenticateToken, async (req, res) => {
  try {
    const postId = req.params.id;
    const { content, parent_comment_id } = req.body;
    
    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Comment content is required' });
    }
    
    const [result] = await db.execute(
      'INSERT INTO comments (post_id, author_id, content, parent_comment_id) VALUES (?, ?, ?, ?)',
      [postId, req.user.id, content.trim(), parent_comment_id || null]
    );
    
    res.status(201).json({
      message: 'Comment added successfully',
      comment_id: result.insertId
    });
  } catch (error) {
    console.error('Add comment error:', error);
    res.status(500).json({ error: 'Failed to add comment' });
  }
});

// Get Comments
app.get('/api/posts/:id/comments', authenticateToken, async (req, res) => {
  try {
    const postId = req.params.id;
    
    const [comments] = await db.execute(`
      SELECT c.*, u.full_name as author_name,
             m.full_name as moderated_by_name
      FROM comments c
      LEFT JOIN users u ON c.author_id = u.id
      LEFT JOIN users m ON c.moderated_by = m.id
      WHERE c.post_id = ? AND c.status = 'approved'
      ORDER BY c.created_at ASC
    `, [postId]);
    
    // Parse JSON fields
    comments.forEach(comment => {
      comment.likes = comment.likes ? JSON.parse(comment.likes) : [];
    });
    
    res.json({ comments });
  } catch (error) {
    console.error('Get comments error:', error);
    res.status(500).json({ error: 'Failed to get comments' });
  }
});

// ==================== ADDITIONAL COMMENTS ROUTES ====================

// Get single comment
app.get('/api/comments/:id', authenticateToken, async (req, res) => {
  try {
    const commentId = req.params.id;
    
    const [comments] = await db.execute(`
      SELECT c.*, u.full_name as author_name, p.title as post_title,
             m.full_name as moderated_by_name
      FROM comments c
      LEFT JOIN users u ON c.author_id = u.id
      LEFT JOIN posts p ON c.post_id = p.id
      LEFT JOIN users m ON c.moderated_by = m.id
      WHERE c.id = ? AND c.is_active = TRUE
    `, [commentId]);

    if (comments.length === 0) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    const comment = comments[0];
    comment.likes = comment.likes ? JSON.parse(comment.likes) : [];

    res.json({
      success: true,
      data: comment
    });
  } catch (error) {
    console.error('Get comment error:', error);
    res.status(500).json({ error: 'Failed to fetch comment' });
  }
});

// Update comment
app.put('/api/comments/:id', authenticateToken, async (req, res) => {
  try {
    const commentId = req.params.id;
    const { content } = req.body;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Comment content is required' });
    }

    // Check if comment exists and belongs to user
    const [existingComment] = await db.execute(`
      SELECT id, author_id FROM comments 
      WHERE id = ? AND is_active = TRUE
    `, [commentId]);

    if (existingComment.length === 0) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    // Check authorization - only author or admin can update
    if (existingComment[0].author_id !== req.user.id && !['owner', 'school_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    await db.execute(`
      UPDATE comments 
      SET content = ?, updated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `, [content.trim(), commentId]);

    const [updatedComment] = await db.execute(`
      SELECT c.*, u.full_name as author_name
      FROM comments c
      LEFT JOIN users u ON c.author_id = u.id
      WHERE c.id = ?
    `, [commentId]);

    const comment = updatedComment[0];
    comment.likes = comment.likes ? JSON.parse(comment.likes) : [];

    res.json({
      success: true,
      message: 'Comment updated successfully',
      data: comment
    });
  } catch (error) {
    console.error('Update comment error:', error);
    res.status(500).json({ error: 'Failed to update comment' });
  }
});

// Delete comment
app.delete('/api/comments/:id', authenticateToken, async (req, res) => {
  try {
    const commentId = req.params.id;

    // Check if comment exists
    const [existingComment] = await db.execute(`
      SELECT id, author_id FROM comments 
      WHERE id = ? AND is_active = TRUE
    `, [commentId]);

    if (existingComment.length === 0) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    // Check authorization - only author or admin can delete
    if (existingComment[0].author_id !== req.user.id && !['owner', 'school_admin', 'teacher'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Soft delete
    await db.execute('UPDATE comments SET is_active = FALSE WHERE id = ?', [commentId]);

    res.json({
      success: true,
      message: 'Comment deleted successfully'
    });
  } catch (error) {
    console.error('Delete comment error:', error);
    res.status(500).json({ error: 'Failed to delete comment' });
  }
});

// Approve comment (for moderation)
app.put('/api/comments/:id/approve', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const commentId = req.params.id;

    // Check if comment exists
    const [existingComment] = await db.execute(`
      SELECT id, status FROM comments 
      WHERE id = ? AND is_active = TRUE
    `, [commentId]);

    if (existingComment.length === 0) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    await db.execute(`
      UPDATE comments 
      SET status = 'approved', moderated_by = ?, moderated_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `, [req.user.id, commentId]);

    const [updatedComment] = await db.execute(`
      SELECT c.*, u.full_name as author_name, m.full_name as moderated_by_name
      FROM comments c
      LEFT JOIN users u ON c.author_id = u.id
      LEFT JOIN users m ON c.moderated_by = m.id
      WHERE c.id = ?
    `, [commentId]);

    const comment = updatedComment[0];
    comment.likes = comment.likes ? JSON.parse(comment.likes) : [];

    res.json({
      success: true,
      message: 'Comment approved successfully',
      data: comment
    });
  } catch (error) {
    console.error('Approve comment error:', error);
    res.status(500).json({ error: 'Failed to approve comment' });
  }
});

// Like/unlike comment
app.post('/api/comments/:id/like', authenticateToken, async (req, res) => {
  try {
    const commentId = req.params.id;
    const userId = req.user.id;

    // Check if comment exists
    const [existingComment] = await db.execute(`
      SELECT id, likes FROM comments 
      WHERE id = ? AND is_active = TRUE AND status = 'approved'
    `, [commentId]);

    if (existingComment.length === 0) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    let likes = existingComment[0].likes ? JSON.parse(existingComment[0].likes) : [];
    let action = '';

    if (likes.includes(userId)) {
      // Unlike
      likes = likes.filter(id => id !== userId);
      action = 'unliked';
    } else {
      // Like
      likes.push(userId);
      action = 'liked';
    }

    await db.execute(`
      UPDATE comments 
      SET likes = ?
      WHERE id = ?
    `, [JSON.stringify(likes), commentId]);

    res.json({
      success: true,
      message: `Comment ${action} successfully`,
      data: {
        comment_id: commentId,
        likes_count: likes.length,
        user_liked: likes.includes(userId)
      }
    });
  } catch (error) {
    console.error('Like comment error:', error);
    res.status(500).json({ error: 'Failed to like/unlike comment' });
  }
});

// Get all comments (for admin/moderation)
app.get('/api/comments', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const { status, post_id, author_id } = req.query;
    let query = `
      SELECT c.*, u.full_name as author_name, p.title as post_title,
             m.full_name as moderated_by_name
      FROM comments c
      LEFT JOIN users u ON c.author_id = u.id
      LEFT JOIN posts p ON c.post_id = p.id
      LEFT JOIN users m ON c.moderated_by = m.id
      WHERE c.is_active = TRUE
    `;
    const params = [];

    if (status) {
      query += ' AND c.status = ?';
      params.push(status);
    }

    if (post_id) {
      query += ' AND c.post_id = ?';
      params.push(post_id);
    }

    if (author_id) {
      query += ' AND c.author_id = ?';
      params.push(author_id);
    }

    query += ' ORDER BY c.created_at DESC';

    const [comments] = await db.execute(query, params);

    // Parse JSON fields
    comments.forEach(comment => {
      comment.likes = comment.likes ? JSON.parse(comment.likes) : [];
    });

    res.json({
      success: true,
      data: comments,
      total: comments.length
    });
  } catch (error) {
    console.error('Get all comments error:', error);
    res.status(500).json({ error: 'Failed to fetch comments' });
  }
});

// ==================== GALERI FOTO ROUTES ====================

// Get Albums
app.get('/api/albums', authenticateToken, async (req, res) => {
  try {
    const { class_id, created_by } = req.query;
    let query = `
      SELECT a.*, u.full_name as creator_name, c.name as class_name,
             (SELECT COUNT(*) FROM photos WHERE album_id = a.id) as photo_count
      FROM albums a 
      LEFT JOIN users u ON a.created_by = u.id 
      LEFT JOIN classes c ON a.class_id = c.id 
      WHERE 1=1
    `;
    const params = [];
    
    if (class_id) {
      query += ' AND a.class_id = ?';
      params.push(class_id);
    }
    
    if (created_by) {
      query += ' AND a.created_by = ?';
      params.push(created_by);
    }
    
    query += ' ORDER BY a.created_at DESC';
    
    const [albums] = await db.execute(query, params);
    res.json({ albums });
  } catch (error) {
    console.error('Get albums error:', error);
    res.status(500).json({ error: 'Failed to get albums' });
  }
});

// Create Album
app.post('/api/albums', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.album), async (req, res) => {
  try {
    const { title, description, class_id, is_public, allow_download, tags } = req.body;
    
    const [result] = await db.execute(
      'INSERT INTO albums (title, description, created_by, class_id, is_public, allow_download, tags) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [title, description, req.user.id, class_id || null, is_public || false, allow_download || false, tags ? JSON.stringify(tags) : null]
    );
    
    res.status(201).json({
      message: 'Album created successfully',
      album_id: result.insertId
    });
  } catch (error) {
    console.error('Create album error:', error);
    res.status(500).json({ error: 'Failed to create album' });
  }
});

// Update Album
app.put('/api/albums/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.album), async (req, res) => {
  try {
    const albumId = req.params.id;
    const { title, description, class_id, is_public, allow_download, tags } = req.body;
    
    // Check if album exists
    const [albums] = await db.execute('SELECT * FROM albums WHERE id = ?', [albumId]);
    if (albums.length === 0) {
      return res.status(404).json({ error: 'Album not found' });
    }
    
    const album = albums[0];
    
    // Check permission - only creator or admin can update
    if (req.user.role !== 'owner' && req.user.role !== 'school_admin' && album.created_by !== req.user.id) {
      return res.status(403).json({ error: 'Not authorized to update this album' });
    }
    
    // Update album
    await db.execute(
      'UPDATE albums SET title = ?, description = ?, class_id = ?, is_public = ?, allow_download = ?, tags = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?',
      [title, description, class_id || null, is_public || false, allow_download || false, tags ? JSON.stringify(tags) : null, albumId]
    );
    
    res.json({ message: 'Album updated successfully' });
  } catch (error) {
    console.error('Update album error:', error);
    res.status(500).json({ error: 'Failed to update album' });
  }
});

// Upload Photos to Album
app.post('/api/albums/:id/photos', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), upload.array('photos', 10), async (req, res) => {
  try {
    const albumId = req.params.id;
    const { captions } = req.body; // Array of captions for each photo
    const files = req.files || [];
    
    if (files.length === 0) {
      return res.status(400).json({ error: 'No photos uploaded' });
    }
    
    const uploadedPhotos = [];
    
    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const filename = `${Date.now()}_${i}_${file.originalname}`;
      const filepath = path.join('uploads/photos', filename);
      
      // Resize and add watermark
      await sharp(file.buffer)
        .resize(1200, 800, { fit: 'inside', withoutEnlargement: true })
        .composite([{
          input: Buffer.from(`<svg width="200" height="50"><text x="10" y="30" font-family="Arial" font-size="16" fill="rgba(255,255,255,0.7)">© Seangkatan</text></svg>`),
          gravity: 'southeast'
        }])
        .jpeg({ quality: 85 })
        .toFile(filepath);
      
      // Create thumbnail
      const thumbnailPath = path.join('uploads/photos/thumbnails', filename);
      await sharp(file.buffer)
        .resize(300, 200, { fit: 'cover' })
        .jpeg({ quality: 80 })
        .toFile(thumbnailPath);
      
      const caption = Array.isArray(captions) ? captions[i] : null;
      
      const [result] = await db.execute(
        'INSERT INTO photos (album_id, filename, original_name, path, thumbnail_path, size, caption, uploaded_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [albumId, filename, file.originalname, filepath, thumbnailPath, file.size, caption, req.user.id]
      );
      
      uploadedPhotos.push({
        id: result.insertId,
        filename: filename,
        caption: caption
      });
    }
    
    res.status(201).json({
      message: `${uploadedPhotos.length} photos uploaded successfully`,
      photos: uploadedPhotos
    });
  } catch (error) {
    console.error('Upload photos error:', error);
    res.status(500).json({ error: 'Failed to upload photos' });
  }
});

// Get Photos from Album
app.get('/api/albums/:id/photos', authenticateToken, async (req, res) => {
  try {
    const albumId = req.params.id;
    
    const [photos] = await db.execute(`
      SELECT p.*, u.full_name as uploader_name
      FROM photos p
      LEFT JOIN users u ON p.uploaded_by = u.id
      WHERE p.album_id = ?
      ORDER BY p.created_at DESC
    `, [albumId]);
    
    res.json({ photos });
  } catch (error) {
    console.error('Get photos error:', error);
    res.status(500).json({ error: 'Failed to get photos' });
  }
});

// Get Single Photo
app.get('/api/photos/:id', authenticateToken, async (req, res) => {
  try {
    const photoId = req.params.id;
    
    const [photos] = await db.execute(`
      SELECT p.*, u.full_name as uploader_name, a.title as album_title
      FROM photos p
      LEFT JOIN users u ON p.uploaded_by = u.id
      LEFT JOIN albums a ON p.album_id = a.id
      WHERE p.id = ?
    `, [photoId]);
    
    if (photos.length === 0) {
      return res.status(404).json({ error: 'Photo not found' });
    }
    
    res.json({ photo: photos[0] });
  } catch (error) {
    console.error('Get photo error:', error);
    res.status(500).json({ error: 'Failed to get photo' });
  }
});

// Delete Photo
app.delete('/api/photos/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const photoId = req.params.id;
    
    // Get photo details
    const [photos] = await db.execute('SELECT * FROM photos WHERE id = ?', [photoId]);
    if (photos.length === 0) {
      return res.status(404).json({ error: 'Photo not found' });
    }
    
    const photo = photos[0];
    
    // Delete files
    try {
      await fs.unlink(photo.path);
      await fs.unlink(photo.thumbnail_path);
    } catch (fileError) {
      console.error('File deletion error:', fileError);
    }
    
    // Delete from database
    await db.execute('DELETE FROM photos WHERE id = ?', [photoId]);
    
    res.json({ message: 'Photo deleted successfully' });
  } catch (error) {
    console.error('Delete photo error:', error);
    res.status(500).json({ error: 'Failed to delete photo' });
  }
});

// ==================== ROOM CHAT KELAS ROUTES ====================

// Get Chat Rooms
app.get('/api/chat-rooms', authenticateToken, async (req, res) => {
  try {
    const { class_id, type } = req.query;
    let query = `
      SELECT cr.*, c.name as class_name, u.full_name as creator_name,
             (SELECT COUNT(*) FROM chat_messages WHERE room_id = cr.id) as message_count,
             (SELECT COUNT(*) FROM room_members WHERE room_id = cr.id) as member_count
      FROM chat_rooms cr 
      LEFT JOIN classes c ON cr.class_id = c.id 
      LEFT JOIN users u ON cr.created_by = u.id 
      WHERE cr.is_active = TRUE
    `;
    const params = [];
    
    // Role-based filtering
    if (req.user.role === 'student') {
      query += ' AND (cr.type = "class" OR cr.id IN (SELECT room_id FROM room_members WHERE user_id = ?))';
      params.push(req.user.id);
    } else if (req.user.role === 'parent') {
      query += ' AND cr.type = "parent"';
    }
    
    if (class_id) {
      query += ' AND cr.class_id = ?';
      params.push(class_id);
    }
    
    if (type) {
      query += ' AND cr.type = ?';
      params.push(type);
    }
    
    query += ' ORDER BY cr.created_at DESC';
    
    const [rooms] = await db.execute(query, params);
    res.json({ rooms });
  } catch (error) {
    console.error('Get chat rooms error:', error);
    res.status(500).json({ error: 'Failed to get chat rooms' });
  }
});

// Create Chat Room
app.post('/api/chat-rooms', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), validate(schemas.chatRoom), async (req, res) => {
  try {
    const { name, description, type, class_id } = req.body;
    
    // Handle null class_id for general chat rooms
    const [result] = await db.execute(
      'INSERT INTO chat_rooms (name, description, type, class_id, created_by) VALUES (?, ?, ?, ?, ?)',
      [name, description, type, class_id || null, req.user.id]
    );
    
    res.status(201).json({
      message: 'Chat room created successfully',
      room_id: result.insertId
    });
  } catch (error) {
    console.error('Create chat room error:', error);
    res.status(500).json({ error: 'Failed to create chat room' });
  }
});

// Join Chat Room
app.post('/api/chat-rooms/:id/join', authenticateToken, async (req, res) => {
  try {
    const roomId = req.params.id;
    
    // Check if room exists
    const [rooms] = await db.execute('SELECT * FROM chat_rooms WHERE id = ? AND is_active = TRUE', [roomId]);
    if (rooms.length === 0) {
      return res.status(404).json({ error: 'Chat room not found' });
    }
    
    // Check if already a member
    const [existing] = await db.execute('SELECT id FROM user_chat_settings WHERE room_id = ? AND user_id = ?', [roomId, req.user.id]);
    if (existing.length > 0) {
      return res.status(400).json({ error: 'Already a member of this room' });
    }
    
    await db.execute(
      'INSERT INTO user_chat_settings (room_id, user_id) VALUES (?, ?)',
      [roomId, req.user.id]
    );
    
    res.json({ message: 'Joined chat room successfully' });
  } catch (error) {
    console.error('Join room error:', error);
    res.status(500).json({ error: 'Failed to join chat room' });
  }
});

// Send Message
app.post('/api/chat-rooms/:id/messages', authenticateToken, upload.single('sticker'), async (req, res) => {
  try {
    const roomId = req.params.id;
    const { content, message_type = 'text', reply_to_message_id } = req.body;
    
    // Check if user is member of the room
    const [membership] = await db.execute(
      'SELECT ucs.* FROM user_chat_settings ucs WHERE ucs.room_id = ? AND ucs.user_id = ?',
      [roomId, req.user.id]
    );
    
    if (membership.length === 0) {
      return res.status(403).json({ error: 'Not a member of this chat room' });
    }
    
    let messageContent = content;
    let attachmentPath = null;
    
    // Handle sticker upload
    if (message_type === 'sticker' && req.file) {
      const filename = `${Date.now()}_${req.file.originalname}`;
      const filepath = path.join('uploads/stickers', filename);
      
      await fs.promises.writeFile(filepath, req.file.buffer);
      attachmentPath = filepath;
      messageContent = filename;
    }
    
    const [result] = await db.execute(
      'INSERT INTO messages (room_id, sender_id, content, type, reply_to_id) VALUES (?, ?, ?, ?, ?)',
      [roomId, req.user.id, messageContent, message_type, reply_to_message_id || null]
    );
    
    res.status(201).json({
      message: 'Message sent successfully',
      message_id: result.insertId
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

// Get Messages
app.get('/api/chat-rooms/:id/messages', authenticateToken, async (req, res) => {
  try {
    const roomId = req.params.id;
    const { page = 1, limit = 50 } = req.query;
    const offset = (page - 1) * limit;
    
    // Check if user is member of the room
    const [membership] = await db.execute(
      'SELECT id FROM user_chat_settings WHERE room_id = ? AND user_id = ?',
      [roomId, req.user.id]
    );
    
    if (membership.length === 0) {
      return res.status(403).json({ error: 'Not a member of this chat room' });
    }
    
    const [messages] = await db.execute(`
      SELECT m.*, u.full_name as sender_name,
             rm.content as reply_content, ru.full_name as reply_sender_name
      FROM messages m
      LEFT JOIN users u ON m.sender_id = u.id
      LEFT JOIN messages rm ON m.reply_to_id = rm.id
      LEFT JOIN users ru ON rm.sender_id = ru.id
      WHERE m.room_id = ? AND m.is_deleted = FALSE
      ORDER BY m.created_at DESC
      LIMIT ? OFFSET ?
    `, [roomId, parseInt(limit), offset]);
    
    res.json({ 
      messages: messages.reverse(), // Reverse to show oldest first
      page: parseInt(page),
      limit: parseInt(limit)
    });
  } catch (error) {
    console.error('Get messages error:', error);
    res.status(500).json({ error: 'Failed to get messages' });
  }
});

// Delete Message
app.delete('/api/messages/:id', authenticateToken, async (req, res) => {
  try {
    const messageId = req.params.id;
    
    // Get message details
    const [messages] = await db.execute('SELECT * FROM messages WHERE id = ?', [messageId]);
    if (messages.length === 0) {
      return res.status(404).json({ error: 'Message not found' });
    }
    
    const message = messages[0];
    
    // Check permissions
    if (message.sender_id !== req.user.id && !['owner', 'school_admin', 'teacher'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Insufficient permissions' });
    }
    
    // Delete attachment file if exists
    if (message.attachment_path) {
      try {
        await fs.unlink(message.attachment_path);
      } catch (fileError) {
        console.error('File deletion error:', fileError);
      }
    }
    
    // Soft delete message
    await db.execute('UPDATE messages SET is_deleted = TRUE WHERE id = ?', [messageId]);
    
    res.json({ message: 'Message deleted successfully' });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ error: 'Failed to delete message' });
  }
});

// ==================== CLASSES ROUTES ====================

// Get all classes
app.get('/api/classes', authenticateToken, async (req, res) => {
  try {
    const { grade_level, academic_year, teacher_id } = req.query;
    let query = `
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email,
             COUNT(DISTINCT e.id) as event_count,
             COUNT(DISTINCT q.id) as quiz_count
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      LEFT JOIN events e ON c.id = e.class_id AND e.status = 'active'
      LEFT JOIN quizzes q ON c.id = q.class_id AND q.is_active = TRUE
      WHERE c.is_active = TRUE
    `;
    const params = [];

    if (grade_level) {
      query += ' AND c.grade_level = ?';
      params.push(grade_level);
    }
    if (academic_year) {
      query += ' AND c.academic_year = ?';
      params.push(academic_year);
    }
    if (teacher_id) {
      query += ' AND c.teacher_id = ?';
      params.push(teacher_id);
    }

    query += ' GROUP BY c.id ORDER BY c.grade_level, c.name';

    const [rows] = await db.execute(query, params);
    res.json({
      success: true,
      data: rows,
      total: rows.length
    });
  } catch (error) {
    console.error('Get classes error:', error);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

// Get single class
app.get('/api/classes/:id', authenticateToken, async (req, res) => {
  try {
    const classId = req.params.id;
    const [rows] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email,
             COUNT(DISTINCT e.id) as event_count,
             COUNT(DISTINCT q.id) as quiz_count,
             COUNT(DISTINCT p.id) as post_count
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      LEFT JOIN events e ON c.id = e.class_id AND e.status = 'active'
      LEFT JOIN quizzes q ON c.id = q.class_id AND q.is_active = TRUE
      LEFT JOIN posts p ON c.id = p.class_id AND p.status = 'approved'
      WHERE c.id = ? AND c.is_active = TRUE
      GROUP BY c.id
    `, [classId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Get class error:', error);
    res.status(500).json({ error: 'Failed to fetch class' });
  }
});

// Create new class
app.post('/api/classes', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.class), async (req, res) => {
  try {
    const { name, grade_level, academic_year, teacher_id } = req.body;

    // Check if teacher exists and is actually a teacher
    if (teacher_id) {
      const [teacherRows] = await db.execute('SELECT id, role FROM users WHERE id = ? AND role = "teacher" AND is_active = TRUE', [teacher_id]);
      if (teacherRows.length === 0) {
        return res.status(400).json({ error: 'Invalid teacher ID' });
      }
    }

    const [result] = await db.execute(
      'INSERT INTO classes (name, grade_level, academic_year, teacher_id) VALUES (?, ?, ?, ?)',
      [name, grade_level, academic_year, teacher_id || null]
    );

    const [newClass] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.id = ?
    `, [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Class created successfully',
      data: newClass[0]
    });
  } catch (error) {
    console.error('Create class error:', error);
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Class with this name already exists' });
    }
    res.status(500).json({ error: 'Failed to create class' });
  }
});

// Update class
app.put('/api/classes/:id', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.class), async (req, res) => {
  try {
    const classId = req.params.id;
    const { name, grade_level, academic_year, teacher_id } = req.body;

    // Check if class exists
    const [existingClass] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (existingClass.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Check if teacher exists and is actually a teacher
    if (teacher_id) {
      const [teacherRows] = await db.execute('SELECT id, role FROM users WHERE id = ? AND role = "teacher" AND is_active = TRUE', [teacher_id]);
      if (teacherRows.length === 0) {
        return res.status(400).json({ error: 'Invalid teacher ID' });
      }
    }

    await db.execute(
      'UPDATE classes SET name = ?, grade_level = ?, academic_year = ?, teacher_id = ? WHERE id = ?',
      [name, grade_level, academic_year, teacher_id || null, classId]
    );

    const [updatedClass] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.id = ?
    `, [classId]);

    res.json({
      success: true,
      message: 'Class updated successfully',
      data: updatedClass[0]
    });
  } catch (error) {
    console.error('Update class error:', error);
    res.status(500).json({ error: 'Failed to update class' });
  }
});

// Delete class (soft delete)
app.delete('/api/classes/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const classId = req.params.id;

    // Check if class exists
    const [existingClass] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (existingClass.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Soft delete the class
    await db.execute('UPDATE classes SET is_active = FALSE WHERE id = ?', [classId]);

    res.json({
      success: true,
      message: 'Class deleted successfully'
    });
  } catch (error) {
    console.error('Delete class error:', error);
    res.status(500).json({ error: 'Failed to delete class' });
  }
});

// Get students in a class
app.get('/api/classes/:id/students', authenticateToken, async (req, res) => {
  try {
    const classId = req.params.id;

    // Check if class exists
    const [classExists] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (classExists.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Get students through quiz attempts, posts, or event bookings related to this class
    const [students] = await db.execute(`
      SELECT DISTINCT u.id, u.username, u.full_name, u.email, u.created_at,
             COUNT(DISTINCT qa.id) as quiz_attempts,
             COUNT(DISTINCT p.id) as posts_count,
             COUNT(DISTINCT eb.id) as event_bookings
      FROM users u
      LEFT JOIN quiz_attempts qa ON u.id = qa.student_id
      LEFT JOIN quizzes q ON qa.quiz_id = q.id AND q.class_id = ?
      LEFT JOIN posts p ON u.id = p.author_id AND p.class_id = ?
      LEFT JOIN event_bookings eb ON u.id = eb.user_id
      LEFT JOIN events e ON eb.event_id = e.id AND e.class_id = ?
      WHERE u.role = 'student' AND u.is_active = TRUE
      AND (qa.id IS NOT NULL OR p.id IS NOT NULL OR eb.id IS NOT NULL)
      GROUP BY u.id
      ORDER BY u.full_name
    `, [classId, classId, classId]);

    res.json({
      success: true,
      data: students,
      total: students.length
    });
  } catch (error) {
    console.error('Get class students error:', error);
    res.status(500).json({ error: 'Failed to fetch class students' });
  }
});

// ==================== BADGES ROUTES ====================

// Get all badges
app.get('/api/badges', authenticateToken, async (req, res) => {
  try {
    const { category, criteria_type } = req.query;
    let query = 'SELECT * FROM badges WHERE is_active = TRUE';
    const params = [];

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }
    if (criteria_type) {
      query += ' AND criteria_type = ?';
      params.push(criteria_type);
    }

    query += ' ORDER BY category, name';

    const [rows] = await db.execute(query, params);
    res.json({
      success: true,
      data: rows,
      total: rows.length
    });
  } catch (error) {
    console.error('Get badges error:', error);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
});

// Get single badge
app.get('/api/badges/:id', authenticateToken, async (req, res) => {
  try {
    const badgeId = req.params.id;
    const [rows] = await db.execute('SELECT * FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    // Get users who have this badge
    const [users] = await db.execute(`
      SELECT u.id, u.username, u.full_name, ub.earned_at
      FROM user_badges ub
      JOIN users u ON ub.user_id = u.id
      WHERE ub.badge_id = ? AND u.is_active = TRUE
      ORDER BY ub.earned_at DESC
    `, [badgeId]);

    res.json({
      success: true,
      data: {
        ...rows[0],
        earned_by: users
      }
    });
  } catch (error) {
    console.error('Get badge error:', error);
    res.status(500).json({ error: 'Failed to fetch badge' });
  }
});

// Create new badge
app.post('/api/badges', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.badge), async (req, res) => {
  try {
    const { name, description, icon, category, criteria_type, criteria_value, criteria_category } = req.body;

    const [result] = await db.execute(
      'INSERT INTO badges (name, description, icon, category, criteria_type, criteria_value, criteria_category) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [name, description, icon, category, criteria_type, criteria_value, criteria_category]
    );

    const [newBadge] = await db.execute('SELECT * FROM badges WHERE id = ?', [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Badge created successfully',
      data: newBadge[0]
    });
  } catch (error) {
    console.error('Create badge error:', error);
    res.status(500).json({ error: 'Failed to create badge' });
  }
});

// Update badge
app.put('/api/badges/:id', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.badge), async (req, res) => {
  try {
    const badgeId = req.params.id;
    const { name, description, icon, category, criteria_type, criteria_value, criteria_category } = req.body;

    // Check if badge exists
    const [existingBadge] = await db.execute('SELECT id FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);
    if (existingBadge.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    await db.execute(
      'UPDATE badges SET name = ?, description = ?, icon = ?, category = ?, criteria_type = ?, criteria_value = ?, criteria_category = ? WHERE id = ?',
      [name, description, icon, category, criteria_type, criteria_value, criteria_category, badgeId]
    );

    const [updatedBadge] = await db.execute('SELECT * FROM badges WHERE id = ?', [badgeId]);

    res.json({
      success: true,
      message: 'Badge updated successfully',
      data: updatedBadge[0]
    });
  } catch (error) {
    console.error('Update badge error:', error);
    res.status(500).json({ error: 'Failed to update badge' });
  }
});

// Delete badge (soft delete)
app.delete('/api/badges/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const badgeId = req.params.id;

    // Check if badge exists
    const [existingBadge] = await db.execute('SELECT id FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);
    if (existingBadge.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    // Soft delete the badge
    await db.execute('UPDATE badges SET is_active = FALSE WHERE id = ?', [badgeId]);

    res.json({
      success: true,
      message: 'Badge deleted successfully'
    });
  } catch (error) {
    console.error('Delete badge error:', error);
    res.status(500).json({ error: 'Failed to delete badge' });
  }
});

// Award badge to user manually
app.post('/api/users/:userId/badges/:badgeId', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const { userId, badgeId } = req.params;

    // Check if user and badge exist
    const [userExists] = await db.execute('SELECT id FROM users WHERE id = ? AND is_active = TRUE', [userId]);
    const [badgeExists] = await db.execute('SELECT id FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);

    if (userExists.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    if (badgeExists.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    // Check if user already has this badge
    const [existingUserBadge] = await db.execute('SELECT id FROM user_badges WHERE user_id = ? AND badge_id = ?', [userId, badgeId]);
    if (existingUserBadge.length > 0) {
      return res.status(409).json({ error: 'User already has this badge' });
    }

    // Award the badge
    await db.execute('INSERT INTO user_badges (user_id, badge_id) VALUES (?, ?)', [userId, badgeId]);

    res.json({
      success: true,
      message: 'Badge awarded successfully'
    });
  } catch (error) {
    console.error('Award badge error:', error);
    res.status(500).json({ error: 'Failed to award badge' });
  }
});

// Revoke badge from user
app.delete('/api/users/:userId/badges/:badgeId', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const { userId, badgeId } = req.params;

    // Check if user has this badge
    const [userBadge] = await db.execute('SELECT id FROM user_badges WHERE user_id = ? AND badge_id = ?', [userId, badgeId]);
    if (userBadge.length === 0) {
      return res.status(404).json({ error: 'User does not have this badge' });
    }

    // Remove the badge
    await db.execute('DELETE FROM user_badges WHERE user_id = ? AND badge_id = ?', [userId, badgeId]);

    res.json({
      success: true,
      message: 'Badge revoked successfully'
    });
  } catch (error) {
    console.error('Revoke badge error:', error);
    res.status(500).json({ error: 'Failed to revoke badge' });
  }
});

// ==================== CLASSES ROUTES ====================

// Get all classes
app.get('/api/classes', authenticateToken, async (req, res) => {
  try {
    const { academic_year, grade_level } = req.query;
    let query = `
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email,
             COUNT(DISTINCT e.id) as event_count,
             COUNT(DISTINCT q.id) as quiz_count
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      LEFT JOIN events e ON c.id = e.class_id
      LEFT JOIN quizzes q ON c.id = q.class_id
      WHERE c.is_active = TRUE
    `;
    const params = [];

    if (academic_year) {
      query += ' AND c.academic_year = ?';
      params.push(academic_year);
    }

    if (grade_level) {
      query += ' AND c.grade_level = ?';
      params.push(grade_level);
    }

    query += ' GROUP BY c.id ORDER BY c.grade_level, c.name';

    const [rows] = await db.execute(query, params);
    res.json({
      success: true,
      data: rows,
      total: rows.length
    });
  } catch (error) {
    console.error('Get classes error:', error);
    res.status(500).json({ error: 'Failed to fetch classes' });
  }
});

// Get single class
app.get('/api/classes/:id', authenticateToken, async (req, res) => {
  try {
    const classId = req.params.id;
    const [rows] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name, u.email as teacher_email
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.id = ? AND c.is_active = TRUE
    `, [classId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Get class error:', error);
    res.status(500).json({ error: 'Failed to fetch class' });
  }
});

// Create new class
app.post('/api/classes', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.class), async (req, res) => {
  try {
    const { name, grade_level, academic_year, teacher_id } = req.body;

    // Validate teacher exists if provided
    if (teacher_id) {
      const [teacherRows] = await db.execute('SELECT id FROM users WHERE id = ? AND role = "teacher" AND is_active = TRUE', [teacher_id]);
      if (teacherRows.length === 0) {
        return res.status(400).json({ error: 'Invalid teacher ID' });
      }
    }

    const [result] = await db.execute(`
      INSERT INTO classes (name, grade_level, academic_year, teacher_id)
      VALUES (?, ?, ?, ?)
    `, [name, grade_level, academic_year, teacher_id || null]);

    const [newClass] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.id = ?
    `, [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Class created successfully',
      data: newClass[0]
    });
  } catch (error) {
    console.error('Create class error:', error);
    res.status(500).json({ error: 'Failed to create class' });
  }
});

// Update class
app.put('/api/classes/:id', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.class), async (req, res) => {
  try {
    const classId = req.params.id;
    const { name, grade_level, academic_year, teacher_id } = req.body;

    // Check if class exists
    const [existingClass] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (existingClass.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Validate teacher exists if provided
    if (teacher_id) {
      const [teacherRows] = await db.execute('SELECT id FROM users WHERE id = ? AND role = "teacher" AND is_active = TRUE', [teacher_id]);
      if (teacherRows.length === 0) {
        return res.status(400).json({ error: 'Invalid teacher ID' });
      }
    }

    await db.execute(`
      UPDATE classes 
      SET name = ?, grade_level = ?, academic_year = ?, teacher_id = ?
      WHERE id = ?
    `, [name, grade_level, academic_year, teacher_id || null, classId]);

    const [updatedClass] = await db.execute(`
      SELECT c.*, u.full_name as teacher_name
      FROM classes c
      LEFT JOIN users u ON c.teacher_id = u.id
      WHERE c.id = ?
    `, [classId]);

    res.json({
      success: true,
      message: 'Class updated successfully',
      data: updatedClass[0]
    });
  } catch (error) {
    console.error('Update class error:', error);
    res.status(500).json({ error: 'Failed to update class' });
  }
});

// Delete class (soft delete)
app.delete('/api/classes/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const classId = req.params.id;

    // Check if class exists
    const [existingClass] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (existingClass.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Soft delete
    await db.execute('UPDATE classes SET is_active = FALSE WHERE id = ?', [classId]);

    res.json({
      success: true,
      message: 'Class deleted successfully'
    });
  } catch (error) {
    console.error('Delete class error:', error);
    res.status(500).json({ error: 'Failed to delete class' });
  }
});

// Get students in a class
app.get('/api/classes/:id/students', authenticateToken, async (req, res) => {
  try {
    const classId = req.params.id;

    // Check if class exists
    const [classExists] = await db.execute('SELECT id FROM classes WHERE id = ? AND is_active = TRUE', [classId]);
    if (classExists.length === 0) {
      return res.status(404).json({ error: 'Class not found' });
    }

    // Get students - assuming students are linked through events or other relationships
    // For now, we'll get all students as this relationship isn't clearly defined in the schema
    const [students] = await db.execute(`
      SELECT id, username, full_name, email, created_at
      FROM users 
      WHERE role = 'student' AND is_active = TRUE
      ORDER BY full_name
    `);

    res.json({
      success: true,
      data: students,
      total: students.length
    });
  } catch (error) {
    console.error('Get class students error:', error);
    res.status(500).json({ error: 'Failed to fetch class students' });
  }
});

// ==================== BADGES ROUTES ====================

// Get all badges
app.get('/api/badges', authenticateToken, async (req, res) => {
  try {
    const { category, criteria_type } = req.query;
    let query = 'SELECT * FROM badges WHERE is_active = TRUE';
    const params = [];

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }

    if (criteria_type) {
      query += ' AND criteria_type = ?';
      params.push(criteria_type);
    }

    query += ' ORDER BY category, name';

    const [rows] = await db.execute(query, params);
    res.json({
      success: true,
      data: rows,
      total: rows.length
    });
  } catch (error) {
    console.error('Get badges error:', error);
    res.status(500).json({ error: 'Failed to fetch badges' });
  }
});

// Get single badge
app.get('/api/badges/:id', authenticateToken, async (req, res) => {
  try {
    const badgeId = req.params.id;
    const [rows] = await db.execute('SELECT * FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Get badge error:', error);
    res.status(500).json({ error: 'Failed to fetch badge' });
  }
});



// Update badge
app.put('/api/badges/:id', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.badge), async (req, res) => {
  try {
    const badgeId = req.params.id;
    const { name, description, icon, category, criteria_type, criteria_value, criteria_category } = req.body;

    // Check if badge exists
    const [existingBadge] = await db.execute('SELECT id FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);
    if (existingBadge.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    await db.execute(`
      UPDATE badges 
      SET name = ?, description = ?, icon = ?, category = ?, criteria_type = ?, criteria_value = ?, criteria_category = ?
      WHERE id = ?
    `, [name, description || null, icon || null, category || null, criteria_type, criteria_value, criteria_category || null, badgeId]);

    const [updatedBadge] = await db.execute('SELECT * FROM badges WHERE id = ?', [badgeId]);

    res.json({
      success: true,
      message: 'Badge updated successfully',
      data: updatedBadge[0]
    });
  } catch (error) {
    console.error('Update badge error:', error);
    res.status(500).json({ error: 'Failed to update badge' });
  }
});

// Delete badge (soft delete)
app.delete('/api/badges/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const badgeId = req.params.id;

    // Check if badge exists
    const [existingBadge] = await db.execute('SELECT id FROM badges WHERE id = ? AND is_active = TRUE', [badgeId]);
    if (existingBadge.length === 0) {
      return res.status(404).json({ error: 'Badge not found' });
    }

    // Soft delete
    await db.execute('UPDATE badges SET is_active = FALSE WHERE id = ?', [badgeId]);

    res.json({
      success: true,
      message: 'Badge deleted successfully'
    });
  } catch (error) {
    console.error('Delete badge error:', error);
    res.status(500).json({ error: 'Failed to delete badge' });
  }
});

// ==================== QUIZ QUESTIONS ROUTES ====================

// Get questions for a quiz
app.get('/api/quizzes/:quizId/questions', authenticateToken, async (req, res) => {
  try {
    const quizId = req.params.quizId;
    
    // Check if quiz exists
    const [quizExists] = await db.execute('SELECT id FROM quizzes WHERE id = ? AND is_active = TRUE', [quizId]);
    if (quizExists.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const [questions] = await db.execute(`
      SELECT qq.*, 
             COUNT(qa.id) as answer_count
      FROM quiz_questions qq
      LEFT JOIN quiz_answers qa ON qq.id = qa.question_id
      WHERE qq.quiz_id = ? AND qq.is_active = TRUE
      GROUP BY qq.id
      ORDER BY qq.order_number, qq.created_at
    `, [quizId]);

    res.json({
      success: true,
      data: questions,
      total: questions.length
    });
  } catch (error) {
    console.error('Get quiz questions error:', error);
    res.status(500).json({ error: 'Failed to fetch quiz questions' });
  }
});

// Create quiz question (standalone)
app.post('/api/quiz-questions', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const { 
      quiz_id, 
      question, 
      type, 
      options, 
      correct_answer, 
      points = 10, 
      difficulty = 'medium',
      explanation,
      order_number = 1
    } = req.body;

    if (!question || !type || !correct_answer) {
      return res.status(400).json({ error: 'Question text, type, and correct answer are required' });
    }

    // If quiz_id is provided, verify it exists
    if (quiz_id) {
      const [quizExists] = await db.execute('SELECT id FROM quizzes WHERE id = ? AND is_active = TRUE', [quiz_id]);
      if (quizExists.length === 0) {
        return res.status(404).json({ error: 'Quiz not found' });
      }
    }

    const [result] = await db.execute(`
      INSERT INTO quiz_questions (
        quiz_id, question, type, correct_answer, 
        points, difficulty, explanation, order_number, created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      quiz_id || null, 
      question, 
      type, 
      correct_answer, 
      points, 
      difficulty, 
      explanation || null, 
      order_number, 
      req.user.id
    ]);

    // Insert options if it's a multiple choice question
    if (type === 'multiple_choice' && options && options.length > 0) {
      for (let i = 0; i < options.length; i++) {
        await db.execute(`
          INSERT INTO quiz_question_options (question_id, option_text, option_order)
          VALUES (?, ?, ?)
        `, [result.insertId, options[i], i + 1]);
      }
    }

    const [newQuestion] = await db.execute(`
      SELECT qq.*, q.title as quiz_title
      FROM quiz_questions qq
      LEFT JOIN quizzes q ON qq.quiz_id = q.id
      WHERE qq.id = ?
    `, [result.insertId]);

    // Get options for the question
    const [questionOptions] = await db.execute(`
      SELECT option_text, option_order
      FROM quiz_question_options
      WHERE question_id = ?
      ORDER BY option_order
    `, [result.insertId]);

    const newQuestionData = newQuestion[0];
    newQuestionData.options = questionOptions.map(opt => opt.option_text);

    res.status(201).json({
      success: true,
      message: 'Quiz question created successfully',
      data: newQuestionData
    });
  } catch (error) {
    console.error('Create quiz question error:', error);
    res.status(500).json({ error: 'Failed to create quiz question' });
  }
});

// Get single quiz question with answers
app.get('/api/quiz-questions/:id', authenticateToken, async (req, res) => {
  try {
    const questionId = req.params.id;
    
    const [questions] = await db.execute(`
      SELECT qq.*, q.title as quiz_title
      FROM quiz_questions qq
      LEFT JOIN quizzes q ON qq.quiz_id = q.id
      WHERE qq.id = ? AND qq.is_active = TRUE
    `, [questionId]);

    if (questions.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    // Get answers for this question
    const [answers] = await db.execute(`
      SELECT * FROM quiz_answers 
      WHERE question_id = ? AND is_active = TRUE
      ORDER BY order_number, created_at
    `, [questionId]);

    const question = questions[0];
    question.answers = answers;

    res.json({
      success: true,
      data: question
    });
  } catch (error) {
    console.error('Get quiz question error:', error);
    res.status(500).json({ error: 'Failed to fetch quiz question' });
  }
});

// Create quiz question
app.post('/api/quizzes/:quizId/questions', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const quizId = req.params.quizId;
    const { question, type, order_number, points } = req.body;

    // Check if quiz exists
    const [quizExists] = await db.execute('SELECT id FROM quizzes WHERE id = ? AND is_active = TRUE', [quizId]);
    if (quizExists.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const [result] = await db.execute(`
      INSERT INTO quiz_questions (quiz_id, question, type, order_number, points)
      VALUES (?, ?, ?, ?, ?)
    `, [quizId, question, type || 'multiple_choice', order_number || 1, points || 1]);

    const [newQuestion] = await db.execute('SELECT * FROM quiz_questions WHERE id = ?', [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Quiz question created successfully',
      data: newQuestion[0]
    });
  } catch (error) {
    console.error('Create quiz question error:', error);
    res.status(500).json({ error: 'Failed to create quiz question' });
  }
});

// Update quiz question
app.put('/api/quiz-questions/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const questionId = req.params.id;
    const { question, type, order_number, points } = req.body;

    // Check if question exists
    const [existingQuestion] = await db.execute('SELECT id FROM quiz_questions WHERE id = ? AND is_active = TRUE', [questionId]);
    if (existingQuestion.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    await db.execute(`
      UPDATE quiz_questions 
      SET question = ?, type = ?, order_number = ?, points = ?
      WHERE id = ?
    `, [question, type, order_number, points, questionId]);

    const [updatedQuestion] = await db.execute('SELECT * FROM quiz_questions WHERE id = ?', [questionId]);

    res.json({
      success: true,
      message: 'Quiz question updated successfully',
      data: updatedQuestion[0]
    });
  } catch (error) {
    console.error('Update quiz question error:', error);
    res.status(500).json({ error: 'Failed to update quiz question' });
  }
});

// Delete quiz question
app.delete('/api/quiz-questions/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const questionId = req.params.id;

    // Check if question exists
    const [existingQuestion] = await db.execute('SELECT id FROM quiz_questions WHERE id = ? AND is_active = TRUE', [questionId]);
    if (existingQuestion.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    // Soft delete question and its answers
    await db.execute('UPDATE quiz_questions SET is_active = FALSE WHERE id = ?', [questionId]);
    await db.execute('UPDATE quiz_answers SET is_active = FALSE WHERE question_id = ?', [questionId]);

    res.json({
      success: true,
      message: 'Quiz question deleted successfully'
    });
  } catch (error) {
    console.error('Delete quiz question error:', error);
    res.status(500).json({ error: 'Failed to delete quiz question' });
  }
});

// ==================== QUIZ ANSWERS ROUTES ====================

// Create quiz answer
app.post('/api/quiz-questions/:questionId/answers', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const questionId = req.params.questionId;
    const { answer_text, is_correct, order_number } = req.body;

    // Check if question exists
    const [questionExists] = await db.execute('SELECT id FROM quiz_questions WHERE id = ? AND is_active = TRUE', [questionId]);
    if (questionExists.length === 0) {
      return res.status(404).json({ error: 'Question not found' });
    }

    const [result] = await db.execute(`
      INSERT INTO quiz_answers (question_id, answer_text, is_correct, order_number)
      VALUES (?, ?, ?, ?)
    `, [questionId, answer_text, is_correct || false, order_number || 1]);

    const [newAnswer] = await db.execute('SELECT * FROM quiz_answers WHERE id = ?', [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Quiz answer created successfully',
      data: newAnswer[0]
    });
  } catch (error) {
    console.error('Create quiz answer error:', error);
    res.status(500).json({ error: 'Failed to create quiz answer' });
  }
});

// Update quiz answer
app.put('/api/quiz-answers/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const answerId = req.params.id;
    const { answer_text, is_correct, order_number } = req.body;

    // Check if answer exists
    const [existingAnswer] = await db.execute('SELECT id FROM quiz_answers WHERE id = ? AND is_active = TRUE', [answerId]);
    if (existingAnswer.length === 0) {
      return res.status(404).json({ error: 'Answer not found' });
    }

    await db.execute(`
      UPDATE quiz_answers 
      SET answer_text = ?, is_correct = ?, order_number = ?
      WHERE id = ?
    `, [answer_text, is_correct, order_number, answerId]);

    const [updatedAnswer] = await db.execute('SELECT * FROM quiz_answers WHERE id = ?', [answerId]);

    res.json({
      success: true,
      message: 'Quiz answer updated successfully',
      data: updatedAnswer[0]
    });
  } catch (error) {
    console.error('Update quiz answer error:', error);
    res.status(500).json({ error: 'Failed to update quiz answer' });
  }
});

// Delete quiz answer
app.delete('/api/quiz-answers/:id', authenticateToken, authorize(['owner', 'school_admin', 'teacher']), async (req, res) => {
  try {
    const answerId = req.params.id;

    // Check if answer exists
    const [existingAnswer] = await db.execute('SELECT id FROM quiz_answers WHERE id = ? AND is_active = TRUE', [answerId]);
    if (existingAnswer.length === 0) {
      return res.status(404).json({ error: 'Answer not found' });
    }

    // Soft delete
    await db.execute('UPDATE quiz_answers SET is_active = FALSE WHERE id = ?', [answerId]);

    res.json({
      success: true,
      message: 'Quiz answer deleted successfully'
    });
  } catch (error) {
    console.error('Delete quiz answer error:', error);
    res.status(500).json({ error: 'Failed to delete quiz answer' });
  }
});

// ==================== QUIZ ATTEMPTS ROUTES ====================

// Get quiz attempts for a user
app.get('/api/users/:userId/quiz-attempts', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;
    const { quiz_id } = req.query;

    // Check authorization - users can only see their own attempts unless admin
    if (req.user.id !== parseInt(userId) && !['owner', 'school_admin', 'teacher'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    let query = `
      SELECT qa.*, q.title as quiz_title, q.total_questions, q.time_limit
      FROM quiz_attempts qa
      LEFT JOIN quizzes q ON qa.quiz_id = q.id
      WHERE qa.user_id = ? AND qa.is_active = TRUE
    `;
    const params = [userId];

    if (quiz_id) {
      query += ' AND qa.quiz_id = ?';
      params.push(quiz_id);
    }

    query += ' ORDER BY qa.created_at DESC';

    const [attempts] = await db.execute(query, params);

    res.json({
      success: true,
      data: attempts,
      total: attempts.length
    });
  } catch (error) {
    console.error('Get quiz attempts error:', error);
    res.status(500).json({ error: 'Failed to fetch quiz attempts' });
  }
});

// Create quiz attempt (start quiz)
app.post('/api/quizzes/:quizId/attempts', authenticateToken, async (req, res) => {
  try {
    const quizId = req.params.quizId;
    const userId = req.user.id;

    // Check if quiz exists
    const [quizExists] = await db.execute('SELECT * FROM quizzes WHERE id = ? AND is_active = TRUE', [quizId]);
    if (quizExists.length === 0) {
      return res.status(404).json({ error: 'Quiz not found' });
    }

    const quiz = quizExists[0];

    // Check if user already has an active attempt
    const [activeAttempt] = await db.execute(`
      SELECT id FROM quiz_attempts 
      WHERE user_id = ? AND quiz_id = ? AND status = 'in_progress' AND is_active = TRUE
    `, [userId, quizId]);

    if (activeAttempt.length > 0) {
      return res.status(400).json({ error: 'You already have an active attempt for this quiz' });
    }

    const startTime = new Date();
    const endTime = quiz.time_limit ? new Date(startTime.getTime() + quiz.time_limit * 60000) : null;

    const [result] = await db.execute(`
      INSERT INTO quiz_attempts (user_id, quiz_id, start_time, end_time, status)
      VALUES (?, ?, ?, ?, 'in_progress')
    `, [userId, quizId, startTime, endTime]);

    const [newAttempt] = await db.execute(`
      SELECT qa.*, q.title as quiz_title, q.total_questions, q.time_limit
      FROM quiz_attempts qa
      LEFT JOIN quizzes q ON qa.quiz_id = q.id
      WHERE qa.id = ?
    `, [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Quiz attempt started successfully',
      data: newAttempt[0]
    });
  } catch (error) {
    console.error('Create quiz attempt error:', error);
    res.status(500).json({ error: 'Failed to start quiz attempt' });
  }
});

// Submit quiz attempt
app.put('/api/quiz-attempts/:id/submit', authenticateToken, async (req, res) => {
  try {
    const attemptId = req.params.id;
    const { answers } = req.body; // Array of {question_id, selected_answer_id}

    // Check if attempt exists and belongs to user
    const [attempts] = await db.execute(`
      SELECT * FROM quiz_attempts 
      WHERE id = ? AND user_id = ? AND status = 'in_progress' AND is_active = TRUE
    `, [attemptId, req.user.id]);

    if (attempts.length === 0) {
      return res.status(404).json({ error: 'Quiz attempt not found or already completed' });
    }

    const attempt = attempts[0];

    // Calculate score
    let correctAnswers = 0;
    let totalQuestions = 0;

    if (answers && answers.length > 0) {
      for (const answer of answers) {
        const [correctAnswer] = await db.execute(`
          SELECT qa.is_correct, qq.points
          FROM quiz_answers qa
          LEFT JOIN quiz_questions qq ON qa.question_id = qq.id
          WHERE qa.id = ? AND qa.question_id = ?
        `, [answer.selected_answer_id, answer.question_id]);

        if (correctAnswer.length > 0) {
          totalQuestions++;
          if (correctAnswer[0].is_correct) {
            correctAnswers += correctAnswer[0].points || 1;
          }
        }
      }
    }

    const score = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0;
    const completedAt = new Date();

    await db.execute(`
      UPDATE quiz_attempts 
      SET score = ?, completed_at = ?, status = 'completed', answers_json = ?
      WHERE id = ?
    `, [score, completedAt, JSON.stringify(answers), attemptId]);

    const [updatedAttempt] = await db.execute(`
      SELECT qa.*, q.title as quiz_title
      FROM quiz_attempts qa
      LEFT JOIN quizzes q ON qa.quiz_id = q.id
      WHERE qa.id = ?
    `, [attemptId]);

    res.json({
      success: true,
      message: 'Quiz submitted successfully',
      data: updatedAttempt[0]
    });
  } catch (error) {
    console.error('Submit quiz attempt error:', error);
    res.status(500).json({ error: 'Failed to submit quiz attempt' });
  }
});

// ==================== STICKERS ROUTES ====================

// Get all stickers
app.get('/api/stickers', authenticateToken, async (req, res) => {
  try {
    const { category, pack_name } = req.query;
    let query = 'SELECT * FROM stickers WHERE is_active = TRUE';
    const params = [];

    if (category) {
      query += ' AND category = ?';
      params.push(category);
    }

    if (pack_name) {
      query += ' AND pack_name = ?';
      params.push(pack_name);
    }

    query += ' ORDER BY pack_name, name';

    const [rows] = await db.execute(query, params);
    res.json({
      success: true,
      data: rows,
      total: rows.length
    });
  } catch (error) {
    console.error('Get stickers error:', error);
    res.status(500).json({ error: 'Failed to fetch stickers' });
  }
});

// Get single sticker
app.get('/api/stickers/:id', authenticateToken, async (req, res) => {
  try {
    const stickerId = req.params.id;
    const [rows] = await db.execute('SELECT * FROM stickers WHERE id = ? AND is_active = TRUE', [stickerId]);

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Sticker not found' });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Get sticker error:', error);
    res.status(500).json({ error: 'Failed to fetch sticker' });
  }
});

// Create new sticker
app.post('/api/stickers', authenticateToken, authorize(['owner', 'school_admin']), validate(schemas.sticker), async (req, res) => {
  try {
    const { name, image_url, category, pack_name, description } = req.body;

    const [result] = await db.execute(`
      INSERT INTO stickers (name, image_url, category, pack_name, description)
      VALUES (?, ?, ?, ?, ?)
    `, [name, image_url, category || null, pack_name || null, description || null]);

    const [newSticker] = await db.execute('SELECT * FROM stickers WHERE id = ?', [result.insertId]);

    res.status(201).json({
      success: true,
      message: 'Sticker created successfully',
      data: newSticker[0]
    });
  } catch (error) {
    console.error('Create sticker error:', error);
    res.status(500).json({ error: 'Failed to create sticker' });
  }
});

// Update sticker
app.put('/api/stickers/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const stickerId = req.params.id;
    const { name, image_url, category, pack_name, description } = req.body;

    // Check if sticker exists
    const [existingSticker] = await db.execute('SELECT id FROM stickers WHERE id = ? AND is_active = TRUE', [stickerId]);
    if (existingSticker.length === 0) {
      return res.status(404).json({ error: 'Sticker not found' });
    }

    await db.execute(`
      UPDATE stickers 
      SET name = ?, image_url = ?, category = ?, pack_name = ?, description = ?
      WHERE id = ?
    `, [name, image_url, category || null, pack_name || null, description || null, stickerId]);

    const [updatedSticker] = await db.execute('SELECT * FROM stickers WHERE id = ?', [stickerId]);

    res.json({
      success: true,
      message: 'Sticker updated successfully',
      data: updatedSticker[0]
    });
  } catch (error) {
    console.error('Update sticker error:', error);
    res.status(500).json({ error: 'Failed to update sticker' });
  }
});

// Delete sticker (soft delete)
app.delete('/api/stickers/:id', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const stickerId = req.params.id;

    // Check if sticker exists
    const [existingSticker] = await db.execute('SELECT id FROM stickers WHERE id = ? AND is_active = TRUE', [stickerId]);
    if (existingSticker.length === 0) {
      return res.status(404).json({ error: 'Sticker not found' });
    }

    // Soft delete
    await db.execute('UPDATE stickers SET is_active = FALSE WHERE id = ?', [stickerId]);

    res.json({
      success: true,
      message: 'Sticker deleted successfully'
    });
  } catch (error) {
    console.error('Delete sticker error:', error);
    res.status(500).json({ error: 'Failed to delete sticker' });
  }
});

// ===== USER CHAT SETTINGS ROUTES =====

// Get user chat settings
app.get('/api/user-chat-settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    
    const [settings] = await db.execute(`
      SELECT * FROM user_chat_settings 
      WHERE user_id = ?
    `, [userId]);

    if (settings.length === 0) {
      // Return default settings if none exist
      return res.json({
        success: true,
        data: {
          user_id: userId,
          notifications_enabled: true,
          sound_enabled: true,
          theme: 'light',
          font_size: 'medium',
          auto_download_media: true,
          show_read_receipts: true,
          language: 'id'
        }
      });
    }

    res.json({
      success: true,
      data: settings[0]
    });
  } catch (error) {
    console.error('Get user chat settings error:', error);
    res.status(500).json({ error: 'Failed to get user chat settings' });
  }
});

// Create or update user chat settings
app.post('/api/user-chat-settings', authenticateToken, validate(schemas.userChatSettings), async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      notifications_enabled = true,
      sound_enabled = true,
      theme = 'light',
      font_size = 'medium',
      auto_download_media = true,
      show_read_receipts = true,
      language = 'id'
    } = req.body;

    // Check if settings already exist
    const [existingSettings] = await db.execute(
      'SELECT id FROM user_chat_settings WHERE user_id = ?',
      [userId]
    );

    if (existingSettings.length > 0) {
      // Update existing settings
      await db.execute(`
        UPDATE user_chat_settings 
        SET notifications_enabled = ?, sound_enabled = ?, theme = ?, 
            font_size = ?, auto_download_media = ?, show_read_receipts = ?, 
            language = ?, updated_at = NOW()
        WHERE user_id = ?
      `, [notifications_enabled, sound_enabled, theme, font_size, 
          auto_download_media, show_read_receipts, language, userId]);

      const [updatedSettings] = await db.execute(
        'SELECT * FROM user_chat_settings WHERE user_id = ?',
        [userId]
      );

      res.json({
        success: true,
        message: 'Chat settings updated successfully',
        data: updatedSettings[0]
      });
    } else {
      // Create new settings
      const [result] = await db.execute(`
        INSERT INTO user_chat_settings 
        (user_id, notifications_enabled, sound_enabled, theme, font_size, 
         auto_download_media, show_read_receipts, language)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `, [userId, notifications_enabled, sound_enabled, theme, font_size,
          auto_download_media, show_read_receipts, language]);

      const [newSettings] = await db.execute(
        'SELECT * FROM user_chat_settings WHERE id = ?',
        [result.insertId]
      );

      res.status(201).json({
        success: true,
        message: 'Chat settings created successfully',
        data: newSettings[0]
      });
    }
  } catch (error) {
    console.error('Create/Update user chat settings error:', error);
    res.status(500).json({ error: 'Failed to save user chat settings' });
  }
});

// Update user chat settings
app.put('/api/user-chat-settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;
    const {
      notifications_enabled,
      sound_enabled,
      theme,
      font_size,
      auto_download_media,
      show_read_receipts,
      language
    } = req.body;

    // Check if settings exist
    const [existingSettings] = await db.execute(
      'SELECT id FROM user_chat_settings WHERE user_id = ?',
      [userId]
    );

    if (existingSettings.length === 0) {
      return res.status(404).json({ error: 'Chat settings not found' });
    }

    await db.execute(`
      UPDATE user_chat_settings 
      SET notifications_enabled = ?, sound_enabled = ?, theme = ?, 
          font_size = ?, auto_download_media = ?, show_read_receipts = ?, 
          language = ?, updated_at = NOW()
      WHERE user_id = ? AND is_active = TRUE
    `, [notifications_enabled, sound_enabled, theme, font_size,
        auto_download_media, show_read_receipts, language, userId]);

    const [updatedSettings] = await db.execute(
      'SELECT * FROM user_chat_settings WHERE user_id = ?',
      [userId]
    );

    res.json({
      success: true,
      message: 'Chat settings updated successfully',
      data: updatedSettings[0]
    });
  } catch (error) {
    console.error('Update user chat settings error:', error);
    res.status(500).json({ error: 'Failed to update user chat settings' });
  }
});

// Delete user chat settings (soft delete)
app.delete('/api/user-chat-settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.id;

    // Check if settings exist
    const [existingSettings] = await db.execute(
      'SELECT id FROM user_chat_settings WHERE user_id = ?',
      [userId]
    );

    if (existingSettings.length === 0) {
      return res.status(404).json({ error: 'Chat settings not found' });
    }

    // Soft delete
    await db.execute(
      'UPDATE user_chat_settings SET is_active = FALSE WHERE user_id = ?',
      [userId]
    );

    res.json({
      success: true,
      message: 'Chat settings deleted successfully'
    });
  } catch (error) {
    console.error('Delete user chat settings error:', error);
    res.status(500).json({ error: 'Failed to delete user chat settings' });
  }
});

// Admin: Get all user chat settings
app.get('/api/admin/user-chat-settings', authenticateToken, authorize(['owner', 'school_admin']), async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const [settings] = await db.execute(`
      SELECT ucs.*, u.username, u.full_name 
      FROM user_chat_settings ucs
      JOIN users u ON ucs.user_id = u.id
      ORDER BY ucs.updated_at DESC
      LIMIT ? OFFSET ?
    `, [limit, offset]);

    const [countResult] = await db.execute(
      'SELECT COUNT(*) as total FROM user_chat_settings'
    );

    res.json({
      success: true,
      data: settings,
      pagination: {
        page,
        limit,
        total: countResult[0].total,
        totalPages: Math.ceil(countResult[0].total / limit)
      }
    });
  } catch (error) {
    console.error('Get all user chat settings error:', error);
    res.status(500).json({ error: 'Failed to get user chat settings' });
  }
});

// ==================== USER CHAT SETTINGS ROUTES ====================

// Get user chat settings
app.get('/api/users/:userId/chat-settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;

    // Check authorization - users can only see their own settings unless admin
    if (req.user.id !== parseInt(userId) && !['owner', 'school_admin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const [rows] = await db.execute('SELECT * FROM user_chat_settings WHERE user_id = ?', [userId]);

    if (rows.length === 0) {
      // Return default settings if none exist
      return res.json({
        success: true,
        data: {
          user_id: parseInt(userId),
          notifications_enabled: true,
          sound_enabled: true,
          theme: 'light',
          font_size: 'medium',
          auto_download_media: true,
          show_read_receipts: true,
          show_online_status: true
        }
      });
    }

    res.json({
      success: true,
      data: rows[0]
    });
  } catch (error) {
    console.error('Get user chat settings error:', error);
    res.status(500).json({ error: 'Failed to fetch chat settings' });
  }
});

// Update user chat settings
app.put('/api/users/:userId/chat-settings', authenticateToken, async (req, res) => {
  try {
    const userId = req.params.userId;

    // Check authorization - users can only update their own settings
    if (req.user.id !== parseInt(userId)) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const {
      notifications_enabled,
      sound_enabled,
      theme,
      font_size,
      auto_download_media,
      show_read_receipts,
      show_online_status
    } = req.body;

    // Check if settings exist
    const [existingSettings] = await db.execute('SELECT id FROM user_chat_settings WHERE user_id = ?', [userId]);

    if (existingSettings.length === 0) {
      // Create new settings
      const [result] = await db.execute(`
        INSERT INTO user_chat_settings (
          user_id, notifications_enabled, sound_enabled, theme, font_size,
          auto_download_media, show_read_receipts, show_online_status
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        userId,
        notifications_enabled !== undefined ? notifications_enabled : true,
        sound_enabled !== undefined ? sound_enabled : true,
        theme || 'light',
        font_size || 'medium',
        auto_download_media !== undefined ? auto_download_media : true,
        show_read_receipts !== undefined ? show_read_receipts : true,
        show_online_status !== undefined ? show_online_status : true
      ]);

      const [newSettings] = await db.execute('SELECT * FROM user_chat_settings WHERE id = ?', [result.insertId]);

      res.status(201).json({
        success: true,
        message: 'Chat settings created successfully',
        data: newSettings[0]
      });
    } else {
      // Update existing settings
      await db.execute(`
        UPDATE user_chat_settings 
        SET notifications_enabled = ?, sound_enabled = ?, theme = ?, font_size = ?,
            auto_download_media = ?, show_read_receipts = ?, show_online_status = ?
        WHERE user_id = ?
      `, [
        notifications_enabled !== undefined ? notifications_enabled : true,
        sound_enabled !== undefined ? sound_enabled : true,
        theme || 'light',
        font_size || 'medium',
        auto_download_media !== undefined ? auto_download_media : true,
        show_read_receipts !== undefined ? show_read_receipts : true,
        show_online_status !== undefined ? show_online_status : true,
        userId
      ]);

      const [updatedSettings] = await db.execute('SELECT * FROM user_chat_settings WHERE user_id = ?', [userId]);

      res.json({
        success: true,
        message: 'Chat settings updated successfully',
        data: updatedSettings[0]
      });
    }
  } catch (error) {
    console.error('Update user chat settings error:', error);
    res.status(500).json({ error: 'Failed to update chat settings' });
  }
});

// Routes
app.get('/', (req, res) => {
  res.json({
    message: 'Selamat datang di API Seangkatan',
    status: 'Server berjalan dengan baik',
    version: '1.0.0',
    features: [
      'Authentication & Authorization',
      'Event Planner',
      'Quiz Interaktif',
      'Mading Online',
      'Galeri Foto',
      'Room Chat Kelas'
    ],
    timestamp: new Date().toISOString()
  });
});

// API Routes
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    message: 'Server sehat',
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    timestamp: new Date().toISOString()
  });
});

// Get API documentation
app.get('/api/docs', (req, res) => {
  res.json({
    message: 'API Documentation - Seangkatan Platform',
    endpoints: {
      authentication: {
        'POST /api/auth/register': 'Register new user',
        'POST /api/auth/login': 'Login user',
        'GET /api/auth/profile': 'Get user profile'
      },
      events: {
        'GET /api/events': 'Get all events',
        'POST /api/events': 'Create new event',
        'POST /api/events/:id/book': 'Book event',
        'GET /api/events/bookings': 'Get user bookings'
      },
      quizzes: {
        'GET /api/quizzes': 'Get all quizzes',
        'POST /api/quizzes': 'Create new quiz',
        'POST /api/quizzes/:id/questions': 'Add question to quiz',
        'POST /api/quizzes/:id/start': 'Start quiz attempt',
        'GET /api/quizzes/badges': 'Get user badges'
      },
      posts: {
        'GET /api/posts': 'Get all posts',
        'POST /api/posts': 'Create new post',
        'POST /api/posts/:id/moderate': 'Moderate post',
        'POST /api/posts/:id/like': 'Like/unlike post'
      },
      albums: {
        'GET /api/albums': 'Get all albums',
        'POST /api/albums': 'Create new album',
        'POST /api/albums/:id/photos': 'Upload photos to album'
      },
      chat: {
        'GET /api/chat-rooms': 'Get chat rooms',
        'POST /api/chat-rooms': 'Create chat room',
        'POST /api/chat-rooms/:id/messages': 'Send message'
      }
    }
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    error: 'Terjadi kesalahan pada server',
    message: err.message
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint tidak ditemukan',
    message: `Route ${req.originalUrl} tidak tersedia`
  });
});

// Initialize server
async function startServer() {
  try {
    // Initialize database connection first
    console.log('Initializing database connection...');
    await initDatabase();
    console.log('✅ Database connection successful');
    
    // Test database connection
    console.log('Testing database connection...');
    await db.execute('SELECT 1');
    console.log('✅ Database test successful');
    
    // Create uploads directories
    await createUploadsDir();
    console.log('✅ Upload directories created');
    
    // Start server
    app.listen(PORT, () => {
      console.log('\n🚀 Seangkatan API Server Started Successfully!');
      console.log('=' .repeat(50));
      console.log(`📍 Server URL: http://localhost:${PORT}`);
      console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
      console.log(`📚 API Docs: http://localhost:${PORT}/api/docs`);
      console.log('=' .repeat(50));
      console.log('\n📋 Available Features:');
      console.log('  • Authentication & Authorization (JWT)');
      console.log('  • Event Planner (Meetings & Competitions)');
      console.log('  • Quiz Interaktif (BTH & Science)');
      console.log('  • Mading Online (Student Works)');
      console.log('  • Galeri Foto (Albums & Watermarks)');
      console.log('  • Room Chat Kelas (Slow Mode & Stickers)');
      console.log('\n🔐 Supported Roles: owner, school_admin, teacher, parent, student');
      console.log('\n⚡ Server is ready to accept requests!');
    });
    
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    console.error('\n🔧 Troubleshooting:');
    console.error('  1. Check if MySQL is running');
    console.error('  2. Verify database credentials in .env file');
    console.error('  3. Ensure database exists');
    console.error('  4. Check if port', PORT, 'is available');
    process.exit(1);
  }
}

// Handle graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down server gracefully...');
  try {
    await db.end();
    console.log('✅ Database connection closed');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error during shutdown:', error);
    process.exit(1);
  }
});

// Start the server
startServer();

module.exports = app;