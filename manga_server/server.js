const express = require('express');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

require('dotenv').config(); // Load .env

const app = express();
const port = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

// Cấu hình DB
const dbConfig = {
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  port: parseInt(process.env.DB_PORT) || 3306,
  waitForConnections: true,
  connectionLimit: parseInt(process.env.DB_CONNECTION_LIMIT) || 10,
  queueLimit: 0,
};

const pool = mysql.createPool(dbConfig);

// --- Middlewares ---
app.use(express.json()); // Đọc body JSON
app.use((req, res, next) => {
  // Cho phép CORS
  res.header('Access-Control-Allow-Origin', '*');
  res.header(
    'Access-Control-Allow-Headers',
    'Origin, X-Requested-With, Content-Type, Accept, Authorization',
  );
  next();
});

// ===============================================
// --- SECTION MANGA ENDPOINTS ---
// ===============================================

app.get('/manga/latest', async (req, res) => {
  try {
    const [rows] = await pool.execute(
      `SELECT id, title, cover_filename 
       FROM mangas 
       ORDER BY COALESCE(last_chapter_uploaded_at, created_at) DESC 
       LIMIT 20`,
    );
    res.json({ result: 'ok', data: rows });
  } catch (error) {
    console.error('Lỗi khi lấy /manga/latest:', error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

app.get('/manga', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;
    const safeLimit = Math.max(1, limit);
    const safeOffset = Math.max(0, offset);

    const selectQuery = `
      SELECT id, title, cover_filename, status, publication_year 
      FROM mangas 
      ORDER BY COALESCE(last_chapter_uploaded_at, created_at) DESC 
      LIMIT ${safeLimit} OFFSET ${safeOffset}
    `;
    const [mangaRows] = await pool.execute(selectQuery);

    const countQuery = 'SELECT COUNT(*) as total FROM mangas';
    const [countRows] = await pool.execute(countQuery);
    const totalCount = countRows[0].total;

    res.json({
      result: 'ok',
      data: mangaRows,
      limit: safeLimit,
      offset: safeOffset,
      total: totalCount,
    });
  } catch (error) {
    console.error('Lỗi khi lấy /manga:', error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

app.get('/manga/:id', async (req, res) => {
  const mangaId = req.params.id;
  try {
    const mangaQuery = `
      SELECT id, title, description, cover_filename, status, publication_year, 
             content_rating, original_language, last_chapter_uploaded_at 
      FROM mangas 
      WHERE id = ?
    `;
    const [mangaRows] = await pool.execute(mangaQuery, [mangaId]);

    if (mangaRows.length === 0) {
      return res
        .status(404)
        .json({ result: 'error', message: 'Manga not found' });
    }
    const mangaData = mangaRows[0];

    const tagsQuery = `
      SELECT t.name 
      FROM tags t
      JOIN manga_tags mt ON t.id = mt.tag_id
      WHERE mt.manga_id = ?
      ORDER BY t.name ASC 
    `;
    const [tagRows] = await pool.execute(tagsQuery, [mangaId]);
    mangaData.tags = tagRows.map((row) => row.name);

    res.json({ result: 'ok', data: mangaData });
  } catch (error) {
    console.error(`Lỗi khi lấy /manga/${mangaId} (có tags):`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

app.get('/manga/:id/chapters', async (req, res) => {
  const mangaId = req.params.id;
  try {
    const query = `
      SELECT id, chapter_number, title, language, publish_date 
      FROM chapters 
      WHERE manga_id = ? 
      ORDER BY 
        COALESCE(CAST(chapter_number AS DECIMAL(10,2)), -1) DESC,
        COALESCE(publish_date, '1970-01-01') DESC
    `;
    const [rows] = await pool.execute(query, [mangaId]);
    res.json({ result: 'ok', data: rows });
  } catch (error) {
    console.error(`Lỗi khi lấy /manga/${mangaId}/chapters:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

app.get('/chapters/:id/pages', async (req, res) => {
  const chapterId = req.params.id;
  try {
    const query = `
      SELECT image_url 
      FROM chapter_pages 
      WHERE chapter_id = ? 
      ORDER BY page_number ASC
    `;
    const [rows] = await pool.execute(query, [chapterId]);
    const imageUrls = rows.map((row) => row.image_url);
    res.json({ result: 'ok', data: imageUrls });
  } catch (error) {
    console.error(`Lỗi khi lấy /chapters/${chapterId}/pages:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// --- ⚠️ ENDPOINT MỚI: TÌM KIẾM ---
app.get('/search', async (req, res) => {
  try {
    const q = (req.query.q || '').trim().toLowerCase();
    const tag = (req.query.tag || '').trim().toLowerCase();
    const tags = (req.query.tags || '').trim(); // ví dụ: "Thriller,Oneshot"
    const mode = (req.query.mode || 'and').toLowerCase(); // and | or
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    const safeLimit = Number.isInteger(limit) && limit > 0 ? limit : 20;
    const safeOffset = Number.isInteger(offset) && offset >= 0 ? offset : 0;

    let sql = `
      SELECT 
        m.id,
        m.title,
        m.cover_filename,
        m.status,
        m.publication_year,
        COALESCE(m.last_chapter_uploaded_at, m.created_at) AS order_time
      FROM mangas m
    `;

    const joins = [];
    const conditions = [];
    const params = [];

    // --- Nếu có tag hoặc tags thì join bảng tags
    if (tag || tags) {
      joins.push(`JOIN manga_tags mt ON mt.manga_id = m.id`);
      joins.push(`JOIN tags t ON t.id = mt.tag_id`);
    }

    // --- Điều kiện tìm theo tiêu đề
    if (q) {
      conditions.push(`LOWER(m.title) LIKE ?`);
      params.push(`%${q}%`);
    }

    // --- Nếu chỉ có 1 tag
    if (tag) {
      conditions.push(`LOWER(t.name) = ?`);
      params.push(tag);
    }

    // --- Nếu có nhiều tags
    let tagList = [];
    if (tags) {
      tagList = tags
        .split(',')
        .map(s => s.trim())
        .filter(Boolean)
        .map(s => s.toLowerCase());

      if (tagList.length > 0) {
        const placeholders = tagList.map(() => '?').join(',');
        conditions.push(`LOWER(t.name) IN (${placeholders})`);
        params.push(...tagList);
      }
    }

    if (joins.length) sql += joins.join(' ');
    if (conditions.length) sql += ' WHERE ' + conditions.join(' AND ');

    // --- GROUP BY + HAVING (nếu mode = and)
    if (tagList.length > 0) {
      sql += ` GROUP BY m.id `;
      if (mode === 'and') {
        sql += ` HAVING COUNT(DISTINCT t.name) = ${tagList.length} `;
      }
      // nếu mode = or thì không cần HAVING (chỉ cần có 1 tag là match)
    } else {
      sql += ` GROUP BY m.id `;
    }

    sql += `
      ORDER BY order_time DESC
      LIMIT ${safeLimit} OFFSET ${safeOffset}
    `;

    console.log('==== DEBUG /search ====');
    console.log('SQL:', sql);
    console.log('PARAMS:', params);
    console.log('MODE:', mode);

    const [rows] = await pool.execute(sql, params);

    const cleaned = rows.map(r => {
      const { order_time, ...rest } = r;
      return rest;
    });

    res.json({
      result: 'ok',
      data: cleaned,
      limit: safeLimit,
      offset: safeOffset,
      mode,
    });
  } catch (error) {
    console.error('Lỗi khi /search:', error);
    res.status(500).json({
      result: 'error',
      message: error.message,
    });
  }
});

// ===============================================
// --- SECTION AUTHENTICATION ---
// ===============================================

app.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ result: 'error', message: 'Vui lòng nhập đủ thông tin.' });
    }

    const salt = await bcrypt.genSalt(10);
    const password_hash = await bcrypt.hash(password, salt);

    await pool.execute(
      'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
      [username.trim(), email.trim(), password_hash]
    );

    res.status(201).json({ result: 'ok', message: 'Đăng ký thành công! Vui lòng đăng nhập.' });
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ result: 'error', message: 'Username hoặc Email đã tồn tại.' });
    }
    console.error(error);
    res.status(500).json({ result: 'error', message: 'Lỗi máy chủ.' });
  }
});

// --- LOGIN ---
app.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ result: 'error', message: 'Vui lòng nhập đủ thông tin.' });
    }

    const [rows] = await pool.execute('SELECT * FROM users WHERE username = ?', [username.trim()]);
    if (rows.length === 0) {
      return res.status(401).json({ result: 'error', message: 'Sai tên đăng nhập hoặc mật khẩu.' });
    }

    const user = rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ result: 'error', message: 'Sai tên đăng nhập hoặc mật khẩu.' });
    }

    const token = jwt.sign({ userId: user.id, username: user.username }, JWT_SECRET, { expiresIn: '1d' });
    res.json({
      result: 'ok',
      message: 'Đăng nhập thành công!',
      token,
      user: { id: user.id, username: user.username, email: user.email },
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ result: 'error', message: 'Lỗi máy chủ.' });
  }
});

app.post('/logout', (req, res) => {
  console.log('Logout attempt: Client should clear token.');
  res.json({ result: 'ok', message: 'Đăng xuất thành công (phía client).' });
});

// --- Middleware xác thực Token ---
function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (token == null) {
    return res
      .status(401)
      .json({ result: 'error', message: 'Chưa đăng nhập (không có token).' });
  }
  jwt.verify(token, JWT_SECRET, (err, userPayload) => {
    if (err) {
      console.warn('Token verification failed:', err.message);
      return res
        .status(403)
        .json({ result: 'error', message: 'Token không hợp lệ hoặc đã hết hạn.' });
    }
    req.user = userPayload; // Gắn payload vào request
    next();
  });
}

// --- Endpoint lấy thông tin người dùng hiện tại (Đã bảo vệ) ---
app.get('/me', authenticateToken, async (req, res) => {
  console.log(`Getting /me for userId: ${req.user.userId}`);
  try {
    const query = 'SELECT id, username, email, created_at FROM users WHERE id = ?';
    const [rows] = await pool.execute(query, [req.user.userId]);
    if (rows.length === 0) {
      return res
        .status(404)
        .json({ result: 'error', message: 'Không tìm thấy người dùng.' });
    }
    res.json({ result: 'ok', user: rows[0] });
  } catch (error) {
    console.error(`Lỗi khi lấy /me cho userId ${req.user.userId}:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});
app.get('/tags', async (req, res) => {
  let connection;
  try {
    connection = await mysql.createConnection(dbConfig);

    const [rows] = await connection.execute('SELECT name FROM tags ORDER BY name ASC');

    // Trả về danh sách tên tag
    const tagList = rows.map(row => row.name);

    res.json({
      result: 'ok',
      data: tagList
    });
  } catch (err) {
    console.error('Error fetching tags:', err);
    res.status(500).json({
      result: 'error',
      message: 'Failed to fetch tags'
    });
  } finally {
    if (connection) {
      await connection.end();
    }
  }
});
// ===============================================
// --- SECTION USER ACTIONS (Protected) ---
// ===============================================

// --- Cập nhật lịch sử đọc ---
app.post('/history/read', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  const { chapterId } = req.body;

  if (!chapterId) {
    return res
      .status(400)
      .json({ result: 'error', message: 'Chapter ID is required.' });
  }

  try {
    const findMangaQuery = 'SELECT manga_id FROM chapters WHERE id = ?';
    const [chapterRows] = await pool.execute(findMangaQuery, [chapterId]);

    if (chapterRows.length === 0) {
      console.warn(`History update failed: Chapter ID ${chapterId} not found.`);
      return res
        .status(404)
        .json({ result: 'error', message: 'Chapter not found.' });
    }
    const mangaId = chapterRows[0].manga_id;

    const upsertQuery = `
      INSERT INTO user_reading_history (user_id, manga_id, chapter_id, last_read_at)
      VALUES (?, ?, ?, CURRENT_TIMESTAMP)
      ON DUPLICATE KEY UPDATE
        chapter_id = VALUES(chapter_id),
        last_read_at = CURRENT_TIMESTAMP;
    `;
    await pool.execute(upsertQuery, [userId, mangaId, chapterId]);

    res.json({ result: 'ok', message: 'Reading history updated.' });
  } catch (error) {
    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      console.warn(
        `History update failed: Chapter ID ${chapterId} or User ID ${userId} not found in foreign tables.`,
      );
      return res
        .status(404)
        .json({ result: 'error', message: 'Chapter or User not found.' });
    }
    console.error(`Lỗi khi cập nhật /history/read:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// --- Lấy Thư viện (Theo dõi) ---
app.get('/library', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  console.log(`Lấy /library cho user ${userId}`);
  try {
    const query = `
      SELECT 
        m.id, m.title, m.cover_filename, m.status AS manga_status,
        l.status AS user_status, l.updated_at
      FROM user_library l
      JOIN mangas m ON l.manga_id = m.id
      WHERE l.user_id = ?
      ORDER BY l.updated_at DESC;
    `;
    const [rows] = await pool.execute(query, [userId]);
    res.json({ result: 'ok', data: rows });
  } catch (error) {
    console.error(`Lỗi khi lấy /library cho user ${userId}:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// --- Lấy Lịch sử đọc ---
app.get('/history', authenticateToken, async (req, res) => {
  const { userId } = req.user;
  console.log(`Lấy /history cho user ${userId}`);
  try {
    const query = `
      SELECT 
        m.id AS manga_id, m.title AS manga_title, m.cover_filename,
        c.id AS chapter_id, c.chapter_number, c.title AS chapter_title,
        h.last_read_at
      FROM user_reading_history h
      JOIN chapters c ON h.chapter_id = c.id
      JOIN mangas m ON c.manga_id = m.id
      WHERE h.user_id = ?
      ORDER BY h.last_read_at DESC
      LIMIT 50; -- Chỉ lấy 50 chapter đọc gần nhất
    `;
    const [rows] = await pool.execute(query, [userId]);
    res.json({ result: 'ok', data: rows });
  } catch (error) {
    console.error(`Lỗi khi lấy /history cho user ${userId}:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// --- Thêm/Cập nhật Manga trong thư viện ---
app.post('/library/add', authenticateToken, async (req, res) => {
  const userId = req.user.userId;
  const { mangaId, status } = req.body;
  const libraryStatus = status || 'reading'; // Mặc định là 'reading' nếu không cung cấp

  if (!mangaId) {
    return res.status(400).json({ result: 'error', message: 'Thiếu mangaId.' });
  }

  try {
    const query = `
      INSERT INTO user_library (user_id, manga_id, status)
      VALUES (?, ?, ?)
      ON DUPLICATE KEY UPDATE status = ?
    `;
    const [result] = await pool.execute(query, [
      userId,
      mangaId,
      libraryStatus,
      libraryStatus,
    ]);

    if (result.affectedRows > 0) {
      const message =
        result.affectedRows === 1
          ? 'Đã thêm manga vào thư viện.'
          : 'Đã cập nhật trạng thái manga.';
      res.json({ result: 'ok', message: message });
    } else {
      res.json({ result: 'ok', message: 'Không có gì thay đổi.' });
    }
  } catch (error) {
    if (error.code === 'ER_NO_REFERENCED_ROW_2') {
      return res
        .status(404)
        .json({ result: 'error', message: 'Manga không tồn tại.' });
    }
    console.error(`Lỗi khi /library/add cho userId ${userId}:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// --- Xóa Manga khỏi thư viện ---
app.post('/library/remove', authenticateToken, async (req, res) => {
  const userId = req.user.userId;
  const { mangaId } = req.body;

  if (!mangaId) {
    return res.status(400).json({ result: 'error', message: 'Thiếu mangaId.' });
  }

  try {
    const query = `
      DELETE FROM user_library 
      WHERE user_id = ? AND manga_id = ?
    `;
    const [result] = await pool.execute(query, [userId, mangaId]);

    if (result.affectedRows > 0) {
      res.json({ result: 'ok', message: 'Đã xóa manga khỏi thư viện.' });
    } else {
      res
        .status(404)
        .json({
          result: 'error',
          message: 'Manga không tìm thấy trong thư viện của bạn.',
        });
    }
  } catch (error) {
    console.error(`Lỗi khi /library/remove cho userId ${userId}:`, error);
    res.status(500).json({ result: 'error', message: error.message });
  }
});

// ===============================================
// --- SECTION UTILITY ---
// ===============================================

// --- Endpoint kiểm tra kết nối database (Dùng Pool) ---
app.get('/test', async (req, res) => {
  let connection;
  try {
    connection = await pool.getConnection();
    await connection.ping();
    console.log('Kiểm tra kết nối DB (từ pool) thành công!');
    res.json({ status: 'ok', message: 'Kết nối database (pool) thành công!' });
  } catch (error) {
    console.error('Lỗi khi kiểm tra kết nối DB (pool):', error);
    res.status(500).json({
      status: 'error',
      message: 'Kết nối database (pool) thất bại',
      error: error.message,
    });
  } finally {
    if (connection) {
      connection.release(); // Trả kết nối về pool
    }
  }
});

// --- Khởi động server (Cập nhật log) ---
app.listen(port, () => {
  console.log(`Backend API đang chạy tại http://localhost:${port}`);
  console.log('Endpoints (Manga):');
  console.log(
    `  GET /manga/latest, /manga, /manga/:id, /manga/:id/chapters, /chapters/:id/pages`,
  );
  console.log('Endpoints (Search):'); // ⚠️ THÊM MỚI
  console.log(`  GET /search?q=...&tags=...`); // ⚠️ THÊM MỚI
  console.log('Endpoints (Auth):');
  console.log(`  POST /register, POST /login, GET /me`);
  console.log('Endpoints (User Action):');
  console.log(`  POST /history/read (Requires token)`);
  console.log(`  GET /library (Requires token)`);
  console.log(`  GET /history (Requires token)`);
  console.log('Endpoints (Utility):');
  console.log(`  GET /test`);
});

