require('dotenv').config(); // Load .env

const fetch = require('node-fetch'); // node-fetch v2
const mysql = require('mysql2/promise');

// --- Cấu hình DB từ .env ---
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

const mangadexApiUrl = 'https://api.mangadex.org'; // Mặc định
const LIMIT_MANGA_PER_REQUEST = 21;
const DELAY_MANGA_MS = 0;
const DELAY_CHAPTER_MS = 0;
const DELAY_PAGE_FETCH_MS = 1025;


function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// --- Hàm lấy dữ liệu MangaDex (không thay đổi) ---
async function fetchMangaDexData(offset = 0, limit = LIMIT_MANGA_PER_REQUEST) {
  try {
    const url = `${mangadexApiUrl}/manga?limit=${limit}&offset=${offset}&includes[]=cover_art&includes[]=tag`;
    const response = await fetch(url);
    if (!response.ok) {
      if (response.status === 429) {
          console.warn('Manga API Rate Limited! Chờ 10s...');
          await sleep(10000);
          return fetchMangaDexData(offset, limit);
      }
      throw new Error(`MangaDex Manga API error: ${response.status} ${response.statusText}`);
    }
    const json = await response.json();
    return json.data ?? [];
  } catch (error) {
    console.error('Lỗi khi gọi MangaDex Manga API:', error);
    return [];
  }
}

// --- HÀM MỚI: Lấy và Chèn Trang (Pages) của Chapter ---
async function fetchAndInsertChapterPages(connection, chapterId) {
  console.log(`       -> Lấy pages cho chapter: ${chapterId}`);
  let addedPageCount = 0;
  let skippedPageCount = 0;
  const insertPageSql = `
    INSERT IGNORE INTO chapter_pages
      (chapter_id, page_number, image_url)
    VALUES (?, ?, ?)
  `;

  try {
    // 1. Gọi API /at-home/server/
    const atHomeUrl = `${mangadexApiUrl}/at-home/server/${chapterId}`;
    const response = await fetch(atHomeUrl);

    if (!response.ok) {
       if (response.status === 429) {
          console.warn(`       -> At-Home API Rate Limited! Chờ 10s...`);
          await sleep(10000);
          return fetchAndInsertChapterPages(connection, chapterId); // Thử lại
       }
       // Nếu lỗi khác (vd 404), coi như chapter không có page hoặc bị lỗi
       console.warn(`       -> Lỗi At-Home API ${response.status} cho chapter ${chapterId}. Bỏ qua pages.`);
       return; // Thoát hàm
    }

    const json = await response.json();

    // 2. Lấy thông tin cần thiết
    const baseUrl = json.baseUrl;
    const chapterHash = json.chapter?.hash;
    const pageFilenames = json.chapter?.dataSaver; // Lấy chất lượng gốc 'data'

    // Kiểm tra xem có đủ thông tin không
    if (!baseUrl || !chapterHash || !pageFilenames || pageFilenames.length === 0) {
      console.warn(`       -> Không tìm thấy thông tin pages hợp lệ cho chapter ${chapterId}.`);
      return;
    }

    // 3. Lặp qua danh sách tên file ảnh
    for (let i = 0; i < pageFilenames.length; i++) {
      const filename = pageFilenames[i];
      const pageNumber = i + 1; // Số trang bắt đầu từ 1

      // 4. Xây dựng URL ảnh hoàn chỉnh
      const imageUrl = `${baseUrl}/data-saver/${chapterHash}/${filename}`;

      // 5. Insert vào DB
      const values = [chapterId, pageNumber, imageUrl];
      try {
        const [result] = await connection.execute(insertPageSql, values);
        if (result.affectedRows > 0) {
          addedPageCount++;
        } else {
          skippedPageCount++;
        }
      } catch (dbError) {
         console.error(`       -> Lỗi khi insert page ${pageNumber} cho chapter ${chapterId}:`, dbError.message);
      }
    } // Kết thúc vòng lặp pages

  } catch (error) {
    console.error(`Lỗi nghiêm trọng khi lấy/chèn pages cho chapter ${chapterId}:`, error);
  } finally {
    console.log(`       -> Pages: Thêm ${addedPageCount}, Bỏ qua ${skippedPageCount}.`);
    // Thêm độ trễ nhỏ sau khi xử lý xong pages của 1 chapter
    await sleep(DELAY_PAGE_FETCH_MS);
  }
}


// --- HÀM LẤY VÀ CHÈN CHAPTERS (Đã Cập nhật - Gọi hàm chèn Pages) ---
async function fetchAndInsertChapters(connection, mangaId, mangaTitle) {
  console.log(`   -> Bắt đầu lấy chapters [en] cho: ${mangaTitle} (ID: ${mangaId})`);
  let totalChaptersFetched = 0;
  let addedChapterCount = 0;
  let skippedChapterCount = 0;
  const insertChapterSql = `
    INSERT IGNORE INTO chapters
      (id, manga_id, chapter_number, title, language, publish_date)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  try {
    const feedUrl = `${mangadexApiUrl}/manga/${mangaId}/feed` +
                    `?translatedLanguage[]=en` +
                    `&includeFuturePublishAt=0` +
                    `&includeExternalUrl=0`; // Chỉ lấy chapter có page

    const response = await fetch(feedUrl);

    if (!response.ok) { /* ... (Xử lý lỗi API Feed giữ nguyên) ... */
        if (response.status === 429) {
          console.warn(`     -> Feed API Rate Limited! Chờ 5s...`);
          await sleep(5000);
          return fetchAndInsertChapters(connection, mangaId, mangaTitle);
        }
        console.warn(`     -> Lỗi Feed API ${response.status} cho manga ${mangaId}. Bỏ qua chapters.`);
        console.log(`   -> Chapters [en]: Tổng lấy ${totalChaptersFetched}, Thêm ${addedChapterCount}, Bỏ qua ${skippedChapterCount}.`);
        return;
    }

    const json = await response.json();
    const chaptersData = json.data ?? [];
    totalChaptersFetched = chaptersData.length;

    for (const chapter of chaptersData) {
      const chapterId = chapter.id;
      const attrs = chapter.attributes;
      const chapterNum = attrs?.chapter ?? null;
      const chapterTitle = attrs?.title ?? null;
      const language = attrs?.translatedLanguage ?? '?';
      const publishDateStr = attrs?.publishAt;
      const publishDate = publishDateStr ? new Date(publishDateStr) : null;
      let isNewChapter = false; // Cờ để biết chapter có mới không

      if (language === 'en') {
          const values = [chapterId, mangaId, chapterNum, chapterTitle, language, publishDate];
          try {
            const [result] = await connection.execute(insertChapterSql, values);
            if (result.affectedRows > 0) {
              addedChapterCount++;
              isNewChapter = true; // Đánh dấu là chapter mới
              // console.log(`       -> Đã thêm chapter mới: ${chapterNum ?? chapterId}`); // Bỏ comment nếu muốn xem chi tiết
            } else {
              skippedChapterCount++;
            }
          } catch (dbError) {
             console.error(`     -> Lỗi khi insert chapter ID ${chapterId} cho manga ${mangaId}:`, dbError.message);
             continue; // Bỏ qua chapter này nếu insert lỗi
          }

          // --- ⚠️ GỌI HÀM LẤY PAGES NẾU LÀ CHAPTER MỚI ---
          if (isNewChapter) {
            await fetchAndInsertChapterPages(connection, chapterId);
            // Không cần sleep ở đây vì đã có sleep trong fetchAndInsertChapterPages
          }

      } else {
          console.warn(`     -> API trả về chapter ngôn ngữ '${language}' dù đã lọc 'en'. Bỏ qua chapter ID ${chapterId}.`);
          skippedChapterCount++;
      }
    } // Kết thúc vòng lặp for

  } catch (error) {
    console.error(`Lỗi nghiêm trọng khi lấy/chèn chapters cho manga ${mangaId}:`, error);
  }

  console.log(`   -> Chapters [en]: Tổng lấy ${totalChaptersFetched}, Thêm ${addedChapterCount}, Bỏ qua ${skippedChapterCount}.`);
}


// --- Hàm insertMangaIntoDB (không thay đổi) ---
async function insertMangaIntoDB(mangaDataList) {
 // ... (Code hàm insertMangaIntoDB giữ nguyên) ...
  let connection;
  try {
    connection = await mysql.createConnection(dbConfig);
    let addedMangaCount = 0;
    let skippedMangaCount = 0;
    let addedTagCount = 0;
    let addedMangaTagCount = 0;

    const insertMangaSql = `
      INSERT IGNORE INTO mangas
        (id, title, description, cover_filename, status, publication_year)
      VALUES (?, ?, ?, ?, ?, ?)
    `;
    const insertTagSql = `
      INSERT IGNORE INTO tags (id, name, \`group\`) VALUES (?, ?, ?)
    `;
    const insertMangaTagSql = `
      INSERT IGNORE INTO manga_tags (manga_id, tag_id) VALUES (?, ?)
    `;

    for (const manga of mangaDataList) {
      const mangaId = manga.id;
      const titles = manga.attributes?.title ?? {};
      const title = titles.en ?? Object.values(titles)[0] ?? 'N/A';
      const description = manga.attributes?.description?.en ?? '';
      const status = manga.attributes?.status ?? 'ongoing';
      const year = manga.attributes?.year;
      const safeYear = typeof year === 'number' ? year : null;

      let coverFilename = null;
      const coverRel = manga.relationships?.find(rel => rel.type === 'cover_art');
      if (coverRel && coverRel.attributes) {
        coverFilename = coverRel.attributes.fileName;
      }

      // --- Insert Manga ---
      try {
        const mangaValues = [mangaId, title, description, coverFilename, status, safeYear];
        const [mangaResult] = await connection.execute(insertMangaSql, mangaValues);
        if (mangaResult.affectedRows > 0) {
          addedMangaCount++;
          console.log(` -> Đã thêm manga mới: ${title}`);
        } else {
          skippedMangaCount++;
        }
      } catch (dbError) {
        console.error(` -> Lỗi khi insert manga ID ${mangaId} (${title}):`, dbError.message);
        continue;
      }

      // --- Insert Tags và Manga_Tags ---
      const tags = manga.attributes?.tags ?? [];
      for (const tag of tags) {
        const tagId = tag.id;
        const tagName = tag.attributes?.name?.en ?? 'N/A';
        const tagGroup = tag.attributes?.group ?? null;
        if (tagName === 'N/A') continue;
        try {
          const [tagResult] = await connection.execute(insertTagSql, [tagId, tagName, tagGroup]);
          if (tagResult.affectedRows > 0) addedTagCount++;
        } catch (dbError) { console.error(` -> Lỗi khi insert tag ID ${tagId} (${tagName}):`, dbError.message); }
        try {
          const [mangaTagResult] = await connection.execute(insertMangaTagSql, [mangaId, tagId]);
          if (mangaTagResult.affectedRows > 0) addedMangaTagCount++;
        } catch (dbError) { console.error(` -> Lỗi khi liên kết manga ${mangaId} với tag ${tagId}:`, dbError.message); }
      }

      // --- GỌI HÀM LẤY CHAPTERS CHO TẤT CẢ MANGA ---
      await fetchAndInsertChapters(connection, mangaId, title);
      await sleep(DELAY_CHAPTER_MS); // Giữ lại độ trễ giữa các manga

    } // Kết thúc vòng lặp mangas

    console.log(` -> Import batch: Manga(Thêm ${addedMangaCount}, Bỏ qua ${skippedMangaCount}), Tags(Thêm ${addedTagCount}), Liên kết(Thêm ${addedMangaTagCount}).`);

  } catch (error) {
    console.error('Lỗi nghiêm trọng khi import vào DB:', error);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

// --- Hàm chạy chính (Không thay đổi) ---
async function runImport() {
  let currentOffset = 0;
  let totalProcessed = 0;

  // Cập nhật log ban đầu
  console.log(`Bắt đầu quá trình import tự động TOÀN BỘ MANGA (limit=${LIMIT_MANGA_PER_REQUEST}, delay=${DELAY_MANGA_MS / 1000}s)...`);
  console.log('Script sẽ chạy cho đến khi lấy hết dữ liệu từ MangaDex.');

  // Vòng lặp while(true) sẽ chạy mãi cho đến khi 'break'
  while (true) {
    console.log(`\n--- Lấy dữ liệu từ offset: ${currentOffset} (Đã xử lý: ${totalProcessed}) ---`); // Cập nhật log

    // ⚠️ XÓA LOGIC TÍNH TOÁN currentLimit VÀ remaining
    // Luôn gọi API với limit mặc định
    const mangaData = await fetchMangaDexData(currentOffset); // Không cần truyền limit nữa

    // Nếu API trả về rỗng -> Đã hết dữ liệu -> Dừng lại
    if (mangaData.length === 0) {
      console.log('Không còn dữ liệu từ MangaDex (hoặc có lỗi API). Dừng import.');
      break; // Thoát khỏi vòng lặp while
    }

    console.log(`Đã lấy ${mangaData.length} truyện. Bắt đầu import vào DB...`);
    await insertMangaIntoDB(mangaData);

    // Cập nhật tổng số đã xử lý
    totalProcessed += mangaData.length;

    // Tăng offset cho lần gọi tiếp theo
    // ⚠️ QUAN TRỌNG: Vẫn tăng offset theo LIMIT_MANGA_PER_REQUEST
    // Nếu tăng theo mangaData.length, bạn có thể bị lặp lại dữ liệu nếu API lỗi
    currentOffset += LIMIT_MANGA_PER_REQUEST;

    // ⚠️ XÓA ĐIỀU KIỆN DỪNG THEO TARGET_MANGA_COUNT
    // if (totalProcessed >= TARGET_MANGA_COUNT) { ... }

    // Chờ trước khi gọi API tiếp
    console.log(`Chờ ${DELAY_MANGA_MS / 1000} giây trước khi lấy batch tiếp theo...`);
    await sleep(DELAY_MANGA_MS);
  } // Kết thúc vòng lặp while

  console.log(`\n=== KẾT THÚC QUÁ TRÌNH IMPORT ===`);
  console.log(`Đã xử lý tổng cộng ${totalProcessed} truyện.`);
}

// Chạy hàm import
runImport();