const bcrypt = require('bcryptjs');
const { query, pool } = require('./src/config/database');

const PASSWORD = '123456';

const students = [
  {
    email: 'student1@test.com',
    name: 'Nguyen Van Sinh Vien',
    university: 'Dai hoc Bach Khoa Ha Noi',
    major: 'Cong nghe thong tin',
    skills: ['Flutter', 'Dart', 'Node.js', 'PostgreSQL', 'Git'],
    location: 'Ha Noi',
    bio: 'Sinh vien nam 3 yeu thich phat trien ung dung mobile.',
    free_time: 'Sang T2-T6, cuoi tuan',
    experience: 'Da lam app Flutter ca nhan, biet REST API va Git.',
  },
  {
    email: 'student2@test.com',
    name: 'Tran Thi Hoc Vien',
    university: 'Dai hoc Kinh Te TP.HCM',
    major: 'Marketing',
    skills: ['Content Writing', 'SEO', 'Facebook Ads', 'Canva'],
    location: 'TP.HCM',
    bio: 'Mong muon tim viec part-time ve marketing va noi dung.',
    free_time: 'Chieu T2-T6',
    experience: 'Da quan ly fanpage CLB va viet bai blog cong nghe.',
  },
  {
    email: 'student3@test.com',
    name: 'Le Minh Anh',
    university: 'Dai hoc Ngoai Thuong',
    major: 'Kinh doanh quoc te',
    skills: ['Giao tiep', 'Ban hang', 'Excel', 'Tieng Anh'],
    location: 'Ha Noi',
    bio: 'Tu tin giao tiep, muon lam viec trong moi truong dich vu.',
    free_time: 'Toi va cuoi tuan',
    experience: 'Tung ho tro ban hang tai hoi cho sinh vien.',
  },
  {
    email: 'student4@test.com',
    name: 'Pham Quang Huy',
    university: 'FPT Polytechnic',
    major: 'Thiet ke do hoa',
    skills: ['Figma', 'Photoshop', 'Illustrator', 'UI Design'],
    location: 'Da Nang',
    bio: 'Sinh vien thiet ke muon nhan viec part-time ve UI va social post.',
    free_time: 'Sang T3-T7',
    experience: 'Da thiet ke poster su kien va landing page bang Figma.',
  },
  {
    email: 'student5@test.com',
    name: 'Do Thu Trang',
    university: 'Dai hoc Su pham Ha Noi',
    major: 'Ngon ngu Anh',
    skills: ['Tieng Anh', 'Giang day', 'Cham soc khach hang', 'PowerPoint'],
    location: 'Ha Noi',
    bio: 'Kien nhan, thich day hoc va giao tiep voi khach hang.',
    free_time: 'Chieu va toi',
    experience: 'Da tro giang lop tieng Anh cho hoc sinh cap 2.',
  },
  {
    email: 'student6@test.com',
    name: 'Nguyen Hoang Nam',
    university: 'Dai hoc Khoa hoc Tu nhien',
    major: 'Khoa hoc du lieu',
    skills: ['Python', 'SQL', 'Excel', 'Data Labeling', 'Power BI'],
    location: 'TP.HCM',
    bio: 'Quan tam den du lieu, bao cao va tu dong hoa bang Python.',
    free_time: 'Toi T2-T6',
    experience: 'Da lam dashboard Excel va bai tap phan tich du lieu.',
  },
];

const employers = [
  {
    email: 'employer1@test.com',
    name: 'Le Van Chu Shop',
    company_name: 'Van Phong Pham ABC',
    company_field: 'Ban le',
    company_address: '123 Cau Giay, Ha Noi',
    company_website: 'https://abc-stationery.vn',
    company_desc: 'Chuoi cua hang van phong pham va do dung hoc tap.',
  },
  {
    email: 'employer2@test.com',
    name: 'Nguyen Thi HR',
    company_name: 'Tech Mobile Co.',
    company_field: 'Cong nghe',
    company_address: '456 Quan 1, TP.HCM',
    company_website: 'https://techmobile.vn',
    company_desc: 'Cong ty outsource phan mem mobile cho startup va SME.',
  },
  {
    email: 'employer3@test.com',
    name: 'Tran Minh Quan',
    company_name: 'Cafe Nova',
    company_field: 'F&B',
    company_address: 'Hoan Kiem, Ha Noi',
    company_website: 'https://cafenova.vn',
    company_desc: 'Quan cafe danh cho sinh vien va dan van phong.',
  },
  {
    email: 'employer4@test.com',
    name: 'Pham Ha Linh',
    company_name: 'Bright English Center',
    company_field: 'Giao duc',
    company_address: 'Dong Da, Ha Noi',
    company_website: 'https://brightenglish.vn',
    company_desc: 'Trung tam tieng Anh cho hoc sinh va sinh vien.',
  },
  {
    email: 'employer5@test.com',
    name: 'Hoang Duc Event',
    company_name: 'Young Event Agency',
    company_field: 'Su kien',
    company_address: 'Quan 3, TP.HCM',
    company_website: 'https://youngevent.vn',
    company_desc: 'To chuc activation, hoi thao va su kien sinh vien.',
  },
  {
    email: 'employer6@test.com',
    name: 'Vu Anh Data',
    company_name: 'DataStart Lab',
    company_field: 'Du lieu',
    company_address: 'Thu Duc, TP.HCM',
    company_website: 'https://datastart.vn',
    company_desc: 'Dich vu xu ly du lieu, gan nhan va bao cao BI.',
  },
  {
    email: 'employer7@test.com',
    name: 'Mai Phuong Design',
    company_name: 'Pixel House Studio',
    company_field: 'Thiet ke',
    company_address: 'Hai Chau, Da Nang',
    company_website: 'https://pixelhouse.vn',
    company_desc: 'Studio thiet ke thuong hieu, UI va social media.',
  },
];

const jobs = [
  {
    employerEmail: 'employer2@test.com',
    title: 'Thuc tap sinh Flutter',
    description: 'Tham gia phat trien ung dung mobile, tich hop REST API va viet UI theo Figma.',
    salary: '2-5 trieu/thang',
    location: 'TP.HCM',
    category: 'IT',
    type: 'Internship',
    shift: 'Linh hoat 4 buoi/tuan',
    skills: ['Flutter', 'Dart', 'Git', 'REST API'],
    requirements: ['Sinh vien CNTT', 'Biet OOP', 'Co san pham ca nhan la loi the'],
    benefits: ['Mentor 1-1', 'Co hoi len chinh thuc', 'Ho tro dau moc thuc tap'],
  },
  {
    employerEmail: 'employer2@test.com',
    title: 'Cong tac vien test ung dung mobile',
    description: 'Kiem thu app Android/iOS, ghi bug, viet checklist test case co ban.',
    salary: '35,000d/gio',
    location: 'Remote',
    category: 'IT',
    type: 'Part-time',
    shift: 'Toi hoac cuoi tuan',
    skills: ['Testing', 'Excel', 'Mobile App', 'Giao tiep'],
    requirements: ['Can than', 'Co dien thoai Android hoac iPhone', 'Biet ghi mo ta bug ro rang'],
    benefits: ['Lam tu xa', 'Duoc huong dan QA co ban'],
  },
  {
    employerEmail: 'employer2@test.com',
    title: 'Tro ly lap trinh Node.js part-time',
    description: 'Ho tro viet API Express, thao tac PostgreSQL va viet tai lieu API.',
    salary: '4-7 trieu/thang',
    location: 'TP.HCM',
    category: 'IT',
    type: 'Part-time',
    shift: 'Chieu T2-T6',
    skills: ['Node.js', 'Express', 'PostgreSQL', 'Git'],
    requirements: ['Biet JavaScript co ban', 'Da tung dung database'],
    benefits: ['Lam voi du an that', 'Review code hang tuan'],
  },
  {
    employerEmail: 'employer6@test.com',
    title: 'Nhan vien gan nhan du lieu AI',
    description: 'Gan nhan hinh anh va van ban, kiem tra chat luong du lieu dau vao cho he thong AI.',
    salary: '30,000-45,000d/gio',
    location: 'TP.HCM',
    category: 'Data',
    type: 'Part-time',
    shift: 'Toi T2-T6',
    skills: ['Data Labeling', 'Excel', 'Tieng Anh', 'Can than'],
    requirements: ['Tap trung tot', 'Co laptop ca nhan'],
    benefits: ['Dao tao quy trinh', 'Co KPI thuong'],
  },
  {
    employerEmail: 'employer6@test.com',
    title: 'Thuc tap sinh phan tich du lieu',
    description: 'Lam sach du lieu, tao bao cao Excel/Power BI va viet truy van SQL co ban.',
    salary: '3-6 trieu/thang',
    location: 'Thu Duc, TP.HCM',
    category: 'Data',
    type: 'Internship',
    shift: '3-4 ngay/tuan',
    skills: ['Python', 'SQL', 'Excel', 'Power BI'],
    requirements: ['Biet thong ke co ban', 'Ham hoc hoi'],
    benefits: ['Duoc training BI', 'Xac nhan thuc tap'],
  },
  {
    employerEmail: 'employer1@test.com',
    title: 'Nhan vien ban hang part-time',
    description: 'Tu van khach hang, sap xep ke hang, ho tro thu ngan tai cua hang van phong pham.',
    salary: '25,000-35,000d/gio',
    location: 'Cau Giay, Ha Noi',
    category: 'Ban le',
    type: 'Part-time',
    shift: 'Sang 8h-12h',
    skills: ['Giao tiep', 'Ban hang', 'Sap xep', 'Cham soc khach hang'],
    requirements: ['Dung gio', 'Trung thuc', 'Than thien voi khach'],
    benefits: ['Giam gia mua hang', 'Moi truong tre'],
  },
  {
    employerEmail: 'employer1@test.com',
    title: 'Thu ngan ca toi',
    description: 'Xu ly thanh toan, chot ca, ho tro kiem hang cuoi ngay.',
    salary: '3.5-5 trieu/thang',
    location: 'Ha Noi',
    category: 'Ban le',
    type: 'Part-time',
    shift: '18h-22h',
    skills: ['Excel', 'Thu ngan', 'Can than', 'Giao tiep'],
    requirements: ['Co the lam toi thieu 4 buoi/tuan'],
    benefits: ['Lich lam on dinh', 'Thuong chuyen can'],
  },
  {
    employerEmail: 'employer3@test.com',
    title: 'Barista part-time',
    description: 'Pha che do uong co ban, phuc vu khach va giu ve sinh khu vuc quay bar.',
    salary: '28,000-38,000d/gio',
    location: 'Hoan Kiem, Ha Noi',
    category: 'F&B',
    type: 'Part-time',
    shift: 'Sang hoac toi',
    skills: ['Pha che', 'Giao tiep', 'Lam viec nhom', 'Dich vu khach hang'],
    requirements: ['Co the xoay ca', 'Uu tien da tung lam F&B'],
    benefits: ['Dao tao pha che', 'Do uong mien phi theo ca'],
  },
  {
    employerEmail: 'employer3@test.com',
    title: 'Nhan vien phuc vu cuoi tuan',
    description: 'Don ban, nhan order va ho tro khach trong khung gio cao diem.',
    salary: '30,000d/gio',
    location: 'Ha Noi',
    category: 'F&B',
    type: 'Part-time',
    shift: 'Thu 7 - Chu nhat',
    skills: ['Giao tiep', 'Phuc vu', 'Nhanh nhen'],
    requirements: ['Co mat dung gio', 'Thai do tot'],
    benefits: ['Tip theo ca', 'Lich lam phu hop sinh vien'],
  },
  {
    employerEmail: 'employer4@test.com',
    title: 'Tro giang tieng Anh',
    description: 'Ho tro giao vien trong lop, cham bai co ban va quan ly hoc sinh.',
    salary: '40,000-60,000d/gio',
    location: 'Dong Da, Ha Noi',
    category: 'Giao duc',
    type: 'Part-time',
    shift: 'Toi T2-T6',
    skills: ['Tieng Anh', 'Giang day', 'PowerPoint', 'Giao tiep'],
    requirements: ['IELTS 6.0 hoac tuong duong la loi the', 'Kien nhan'],
    benefits: ['Chung nhan tro giang', 'Moi truong giao duc'],
  },
  {
    employerEmail: 'employer4@test.com',
    title: 'Gia su online tieng Anh cap 2',
    description: 'Day online 1-1 cho hoc sinh cap 2, soan bai theo giao trinh co san.',
    salary: '80,000-120,000d/buoi',
    location: 'Remote',
    category: 'Giao duc',
    type: 'Remote',
    shift: 'Toi linh hoat',
    skills: ['Tieng Anh', 'Giang day', 'Zoom', 'Giao tiep'],
    requirements: ['Co laptop', 'Noi chuyen ro rang'],
    benefits: ['Lam online', 'Chu dong lich day'],
  },
  {
    employerEmail: 'employer5@test.com',
    title: 'Cong tac vien su kien activation',
    description: 'Ho tro check-in, phat sampling, huong dan khach va chup anh su kien.',
    salary: '250,000-400,000d/ngay',
    location: 'Quan 3, TP.HCM',
    category: 'Su kien',
    type: 'Part-time',
    shift: 'Theo lich su kien',
    skills: ['Giao tiep', 'Lam viec nhom', 'Nhanh nhen', 'Chup anh'],
    requirements: ['Ngoai hinh gon gang', 'Co the di chuyen trong thanh pho'],
    benefits: ['Nhan luong theo ngay', 'Mo rong quan he'],
  },
  {
    employerEmail: 'employer5@test.com',
    title: 'MC ho tro workshop sinh vien',
    description: 'Dan chuong trinh workshop nho, tuong tac voi khach moi va sinh vien tham du.',
    salary: '500,000-800,000d/buoi',
    location: 'TP.HCM',
    category: 'Su kien',
    type: 'Part-time',
    shift: 'Cuoi tuan',
    skills: ['Thuyet trinh', 'Giao tiep', 'Tieng Anh', 'To chuc su kien'],
    requirements: ['Tu tin truoc dam dong', 'Gui demo ngan la loi the'],
    benefits: ['Thu nhap theo buoi', 'Co profile su kien'],
  },
  {
    employerEmail: 'employer7@test.com',
    title: 'Thuc tap sinh UI/UX Designer',
    description: 'Thiet ke wireframe, UI mobile/web va chuan bi prototype trong Figma.',
    salary: '2-4 trieu/thang',
    location: 'Da Nang',
    category: 'Thiet ke',
    type: 'Internship',
    shift: 'Linh hoat',
    skills: ['Figma', 'UI Design', 'Prototype', 'Photoshop'],
    requirements: ['Co portfolio thiet ke', 'Biet typography va layout co ban'],
    benefits: ['Mentor designer senior', 'Du an dua vao portfolio'],
  },
  {
    employerEmail: 'employer7@test.com',
    title: 'CTV thiet ke social media',
    description: 'Thiet ke banner, post Facebook, thumbnail va asset cho campaign.',
    salary: '70,000-150,000d/mau',
    location: 'Remote',
    category: 'Thiet ke',
    type: 'Remote',
    shift: 'Theo deadline',
    skills: ['Photoshop', 'Canva', 'Illustrator', 'Sang tao'],
    requirements: ['Co laptop', 'Gui 3 mau da lam'],
    benefits: ['Lam tu xa', 'Tra tien theo san pham'],
  },
  {
    employerEmail: 'employer2@test.com',
    title: 'CTV Content Marketing cong nghe',
    description: 'Viet bai blog, fanpage va mo ta san pham cho ung dung mobile.',
    salary: '60,000-120,000d/bai',
    location: 'Remote',
    category: 'Marketing',
    type: 'Remote',
    shift: 'Tu do',
    skills: ['Content Writing', 'SEO', 'Canva', 'Cong nghe'],
    requirements: ['Van phong ro rang', 'Biet nghien cuu keyword'],
    benefits: ['Lam tu xa', 'Thuong theo KPI'],
  },
  {
    employerEmail: 'employer2@test.com',
    title: 'Tro ly chay quang cao Facebook Ads',
    description: 'Ho tro len content, theo doi chi so ads va bao cao hieu qua chien dich.',
    salary: '3-5 trieu/thang',
    location: 'TP.HCM',
    category: 'Marketing',
    type: 'Part-time',
    shift: 'Chieu T2-T6',
    skills: ['Facebook Ads', 'Excel', 'Content Writing', 'Marketing'],
    requirements: ['Biet doc chi so co ban', 'Can than voi ngan sach'],
    benefits: ['Hoc tu media buyer', 'Co du lieu campaign that'],
  },
  {
    employerEmail: 'employer6@test.com',
    title: 'Nhan vien nhap lieu online',
    description: 'Nhap lieu san pham, kiem tra thong tin va cap nhat file Excel hang ngay.',
    salary: '25,000-35,000d/gio',
    location: 'Remote',
    category: 'Van phong',
    type: 'Remote',
    shift: 'Linh hoat',
    skills: ['Excel', 'Nhap lieu', 'Can than', 'Google Sheets'],
    requirements: ['Co laptop', 'Internet on dinh'],
    benefits: ['Lam tu xa', 'Lich linh hoat'],
  },
  {
    employerEmail: 'employer1@test.com',
    title: 'Nhan vien kho part-time',
    description: 'Sap xep hang hoa, kiem hang va dong goi don nho.',
    salary: '30,000-40,000d/gio',
    location: 'Ha Noi',
    category: 'Kho van',
    type: 'Part-time',
    shift: 'Chieu 13h-17h',
    skills: ['Sap xep', 'Can than', 'Lam viec nhom'],
    requirements: ['Suc khoe tot', 'Lam toi thieu 3 buoi/tuan'],
    benefits: ['Luong theo gio', 'Thuong chuyen can'],
  },
  {
    employerEmail: 'employer3@test.com',
    title: 'Nhan vien truc fanpage ca toi',
    description: 'Tra loi tin nhan khach hang, ghi nhan don dat ban va xu ly phan hoi co ban.',
    salary: '3-4 trieu/thang',
    location: 'Remote',
    category: 'Cham soc khach hang',
    type: 'Remote',
    shift: '18h-22h',
    skills: ['Cham soc khach hang', 'Giao tiep', 'Facebook', 'Nhanh nhen'],
    requirements: ['Phan hoi nhanh', 'Co laptop hoac dien thoai on dinh'],
    benefits: ['Lam tu xa', 'Duoc huong dan kich ban chat'],
  },
];

async function upsertStudent(student, hashedPass) {
  const result = await query(
    `INSERT INTO users (
       email, password, name, role, is_verified, university, major,
       skills, location, bio, free_time, experience
     )
     VALUES ($1, $2, $3, 'student', TRUE, $4, $5, $6, $7, $8, $9, $10)
     ON CONFLICT (email) DO UPDATE SET
       name = EXCLUDED.name,
       is_verified = TRUE,
       university = EXCLUDED.university,
       major = EXCLUDED.major,
       skills = EXCLUDED.skills,
       location = EXCLUDED.location,
       bio = EXCLUDED.bio,
       free_time = EXCLUDED.free_time,
       experience = EXCLUDED.experience,
       updated_at = NOW()
     RETURNING id`,
    [
      student.email,
      hashedPass,
      student.name,
      student.university,
      student.major,
      student.skills,
      student.location,
      student.bio,
      student.free_time,
      student.experience,
    ]
  );
  return result.rows[0].id;
}

async function upsertEmployer(employer, hashedPass) {
  const result = await query(
    `INSERT INTO users (
       email, password, name, role, is_verified, company_name, company_field,
       company_address, company_website, company_desc
     )
     VALUES ($1, $2, $3, 'employer', TRUE, $4, $5, $6, $7, $8)
     ON CONFLICT (email) DO UPDATE SET
       name = EXCLUDED.name,
       is_verified = TRUE,
       company_name = EXCLUDED.company_name,
       company_field = EXCLUDED.company_field,
       company_address = EXCLUDED.company_address,
       company_website = EXCLUDED.company_website,
       company_desc = EXCLUDED.company_desc,
       updated_at = NOW()
     RETURNING id`,
    [
      employer.email,
      hashedPass,
      employer.name,
      employer.company_name,
      employer.company_field,
      employer.company_address,
      employer.company_website,
      employer.company_desc,
    ]
  );
  return result.rows[0].id;
}

async function upsertJob(job, employerId) {
  const existing = await query(
    'SELECT id FROM jobs WHERE user_id = $1 AND title = $2 LIMIT 1',
    [employerId, job.title]
  );

  if (existing.rows.length > 0) {
    const result = await query(
      `UPDATE jobs SET
         description = $3,
         salary = $4,
         location = $5,
         category = $6,
         type = $7,
         shift = $8,
         skills = $9,
         requirements = $10,
         benefits = $11,
         is_active = TRUE,
         updated_at = NOW()
       WHERE id = $1 AND user_id = $2
       RETURNING id`,
      [
        existing.rows[0].id,
        employerId,
        job.description,
        job.salary,
        job.location,
        job.category,
        job.type,
        job.shift,
        job.skills,
        job.requirements,
        job.benefits,
      ]
    );
    return result.rows[0].id;
  }

  const result = await query(
    `INSERT INTO jobs (
       user_id, title, description, salary, location, category, type, shift,
       skills, requirements, benefits, is_active
     )
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, TRUE)
     RETURNING id`,
    [
      employerId,
      job.title,
      job.description,
      job.salary,
      job.location,
      job.category,
      job.type,
      job.shift,
      job.skills,
      job.requirements,
      job.benefits,
    ]
  );
  return result.rows[0].id;
}

async function seedApplications(studentIds, jobIds) {
  const samples = [
    { student: 'student1@test.com', job: 'Tro ly lap trinh Node.js part-time', status: 'viewed', score: 88 },
    { student: 'student2@test.com', job: 'CTV Content Marketing cong nghe', status: 'pending', score: 91 },
    { student: 'student3@test.com', job: 'Nhan vien ban hang part-time', status: 'interview', score: 78 },
    { student: 'student4@test.com', job: 'Thuc tap sinh UI/UX Designer', status: 'pending', score: 86 },
    { student: 'student5@test.com', job: 'Tro giang tieng Anh', status: 'accepted', score: 92 },
    { student: 'student6@test.com', job: 'Thuc tap sinh phan tich du lieu', status: 'pending', score: 89 },
  ];

  for (const item of samples) {
    const userId = studentIds.get(item.student);
    const jobId = jobIds.get(item.job);
    if (!userId || !jobId) continue;

    await query(
      `INSERT INTO applications (job_id, user_id, status, match_score, cover_letter)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (job_id, user_id) DO UPDATE SET
         status = EXCLUDED.status,
         match_score = EXCLUDED.match_score,
         cover_letter = EXCLUDED.cover_letter,
         updated_at = NOW()`,
      [
        jobId,
        userId,
        item.status,
        item.score,
        'Em quan tam den cong viec nay va tin rang ky nang hien co phu hop voi yeu cau.',
      ]
    );
  }
}

async function seedNotifications(studentIds) {
  const userId = studentIds.get('student1@test.com');
  if (!userId) return;

  await query(
    `INSERT INTO notifications (user_id, type, title, body, ref_type)
     SELECT $1, 'system', 'Ho so cua ban da san sang', 'Hay cap nhat CV de AI de xuat viec chinh xac hon.', 'profile'
     WHERE NOT EXISTS (
       SELECT 1 FROM notifications
       WHERE user_id = $1 AND type = 'system' AND title = 'Ho so cua ban da san sang'
     )`,
    [userId]
  );
}

async function seed() {
  console.log('[Seed] Starting sample data seeding...');

  try {
    const hashedPass = await bcrypt.hash(PASSWORD, 12);
    const studentIds = new Map();
    const employerIds = new Map();
    const jobIds = new Map();

    for (const student of students) {
      const id = await upsertStudent(student, hashedPass);
      studentIds.set(student.email, id);
    }

    for (const employer of employers) {
      const id = await upsertEmployer(employer, hashedPass);
      employerIds.set(employer.email, id);
    }

    for (const job of jobs) {
      const employerId = employerIds.get(job.employerEmail);
      if (!employerId) continue;
      const id = await upsertJob(job, employerId);
      jobIds.set(job.title, id);
    }

    await seedApplications(studentIds, jobIds);
    await seedNotifications(studentIds);

    console.log(`[Seed] Done. Students: ${students.length}, employers: ${employers.length}, jobs: ${jobs.length}`);
    console.log('[Seed] Login samples: student1@test.com / 123456, employer1@test.com / 123456');
  } catch (err) {
    console.error('[Seed] Failed:', err);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

seed();
