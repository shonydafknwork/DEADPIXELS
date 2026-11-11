# DEAD PIXELS — موقع ستاتيك (بدون بناء)
## التشغيل على GitHub Pages (دقيقتين)
1. اعمل Repository جديد على GitHub (Public).
2. ارفع **كل الملفات دي** (index.html, config.js, logo.png, favicon.png, .nojekyll, schema.sql, README.md) — Add file ← Upload files.
3. Settings ← Pages ← Source: **Deploy from a branch** ← Branch: `main` / `(root)` ← Save.
4. بعد دقيقة الموقع يشتغل على `https://USERNAME.github.io/REPO/`.

## التعديل
كل حاجة في `config.js`: رقم واتساب، إيميل، إنستجرام، والأحداث (شيل `//` وعدّل المثال).

## الحجز
- من غير Supabase: الزائر يملأ الفورم ← يفتح واتساب/إيميل برسالة جاهزة فيها كود الحجز ← يبعتها. تتبّع التذاكر المتاحة يدوي (`left` في config.js).
- مع Supabase (اختياري): شغّل `schema.sql` في SQL Editor، حط `supabaseUrl` و`supabaseKey` (anon فقط) في config.js. وقتها الأحداث والحجوزات تتحفظ في قاعدة بيانات حقيقية ويمنع الـ overbooking. الأدمن يدير الأحداث والحجوزات من Table Editor في Supabase.
- GitHub Pages يستضيف الواجهة فقط ومفيهوش قاعدة بيانات.
