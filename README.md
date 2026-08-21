# عطاء | ATAA

تطبيق Flutter لجمعية خيرية سورية. يدعم ثلاث أدوار: **متبرع**، **مستفيد**، و**متطوع**، مع العربية والإنجليزية والوضع الليلي.

A Flutter charity app for donors, beneficiaries, and volunteers. Arabic and English, with light and dark themes.

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

استخدم فرع `main` دائماً. لا تنسخ مجلدات البناء المحلية من جهاز آخر.

Always use the `main` branch. Do not copy local Gradle/build folders from another machine.

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

## ما لا يُرفع إلى GitHub | Not committed

هذه الملفات محلية وتُولَّد على كل جهاز، فلا ترفعها حتى لا يحدث تضارب:

- `android/build/` مخرجات Gradle
- `android/certs/` شهادات محلية
- `android/gradle_build_log.txt`
- `.gradle/` و `build/`
- `.vscode/settings.json` إعدادات المحرر المحلية

Flutter يولّد ملفات Gradle الناقصة تلقائياً عند `flutter run`.

## ملاحظات للزملاء | For teammates

1. استنسخ المستودع من جديد أو حدّث فرع `main`: `git pull origin main`
2. لا تدمج مجلد `android/build` من جهاز آخر
3. إذا ظهر تضارب، أبقِ نسخة GitHub لملفات المشروع واحذف مجلدات البناء ثم نفّذ `flutter clean` ثم `flutter pub get`
