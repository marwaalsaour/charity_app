# عطاء | ATAA

تطبيق Flutter لجمعية خيرية سورية. يدعم ثلاث أدوار: **متبرع/متطوع**، **مستفيد**،
A Flutter charity app for donors/volunteer, beneficiaries

---

## المتطلبات | Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) **3.10.4** أو أحدث
- Android Studio أو VS Code
- اتصال بالإنترنت (التطبيق يعتمد على واجهة Laravel)

## تشغيل المشروع | Run the project

```bash
git clone https://github.com/marwaalsaour/charity_app.git
cd charity_app
git checkout main
flutter pub get
flutter run
```

استخدم فرع `main` دائماً.

Always use the `main` branch.

### أوامر مفيدة | Useful commands

```bash
flutter pub get
flutter analyze
flutter run
```

## ماذا يتضمن التطبيق | Features

- تسجيل الدخول وإنشاء حساب (متبرع / مستفيد / متطوع)
- التبرع لحالات التعليم والعلاج وكفالة الأيتام والحملات
- طلبات المساعدة للمستفيدين
- الإشعارات عبر Firebase Cloud Messaging
- ملف الشفافية، خريطة مراكز الجمعية، والمحفظة
- شهادات التطوع (PDF) وكفالات الأيتام

## البنية | Structure

| المسار | الوصف |
| --- | --- |
| `lib/features/` | شاشات ومنطق كل قسم (auth, home, donations, …) |
| `lib/core/` | الشبكة، التوجيه، الثيم، الإشعارات |
| `assets/translations/` | ملفات الترجمة `ar.json` / `en.json` |
| `backend_examples/` | ملاحظات وأمثلة Laravel للـ API |

عنوان الـ API معرف في `lib/core/network/api_constants.dart`.

## Firebase

ملف `android/app/google-services.json` موجود في المستودع لتشغيل إشعارات أندرويد. بعد الاستنساخ لا حاجة لنسخه يدوياً.

The Android Firebase config is already in the repo. After cloning you do not need to copy it by hand.

## ملاحظات للزملاء | For teammates

استنسخ المستودع من جديد أو حدّث فرع `main`:

```bash
git pull origin main
flutter pub get
```
