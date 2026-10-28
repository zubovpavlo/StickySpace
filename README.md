# StickySpace — персональні стікери для Windows та iPhone

Стартова версія Flutter-застосунку, в якому ті самі нотатки доступні на Windows та iPhone. Інтерфейс українською.

## Що працює

- Реєстрація / вхід за e-mail і паролем.
- Створення, редагування і видалення нотаток.
- Шість кольорів паперу, пошук, перетягування на дошці Windows.
- Мобільна сітка нотаток на iPhone.
- Автозбереження тексту під час редагування (після паузи 650 мс).
- Live-sync через Supabase Postgres Changes за активного інтернету.
- RLS-політики: кожен акаунт бачить лише власні нотатки.

**Поточні обмеження:** офлайн-редагування/черга відкладеної синхронізації, вкладення, нагадування, рукописні нотатки, керування конфліктами одночасного редагування ще не реалізовані. Під час одночасного редагування однієї нотатки на двох пристроях може перемогти останнє збереження. Немає зібраних `.exe`/`.ipa`: для цього потрібні відповідні SDK і комп'ютери.

## Підготуй Supabase

1. Створи власний проєкт на https://supabase.com/ .
2. В Dashboard відкрий **SQL Editor** і запусти `supabase/schema.sql` **один раз**. Повторний запуск без видалення старих політик призведе до помилки `policy already exists`.
3. В **Authentication -> Providers -> Email** залиш e-mail authentication увімкненою. Якщо ввімкнене підтвердження e-mail, підтвердь лист перед входом.
4. В **Project Settings / Connect** знайди **Project URL** та **publishable key** (або legacy `anon` key). **НЕ використовуй** `service_role` чи secret key у клієнтському застосунку.
5. Перевір у **Database / Publications** (або Realtime), що таблиця `public.notes` додана до `supabase_realtime`. SQL намагається додати її автоматично.

## Windows

1. Установи Flutter SDK, Git та Visual Studio 2022/2026 з workload **Desktop development with C++** (не лише VS Code). Перевір `flutter doctor -v`.
2. Розпакуй цю папку і у PowerShell перейди до неї.
3. Згенеруй файли Windows платформи:

```powershell
flutter create --platforms=windows .
flutter pub get
```

4. Запусти, підставивши власні URL і publishable/anon key:

```powershell
flutter run -d windows --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

5. Створи `.exe`-збірку:

```powershell
flutter build windows --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Застосунок потребує всього комплекту файлів з `build/windows/x64/runner/Release` (а не лише одного `.exe`). Для ARM64 шлях може відрізнятися.

## iPhone (потрібен Mac із Xcode)

1. Встанови Xcode, Flutter, налаштуй підпис застосунків у Xcode; перевір `flutter doctor -v`.
2. На Mac розпакуй цей самий архів і у Terminal відкрий папку.
3. Згенеруй платформу iOS:

```bash
flutter create --platforms=ios .
flutter pub get
```

4. Під'єднай iPhone до Mac, довірся комп'ютеру, ввімкни Developer Mode на iPhone (за потреби). У `ios/Runner.xcworkspace` налаштуй Signing & Capabilities і власний Team / Bundle Identifier.
5. Запусти на фізичному пристрої, де `<DEVICE_ID>` — ідентифікатор з `flutter devices`:

```bash
flutter devices
flutter run -d <DEVICE_ID> --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLISHABLE_KEY
```

Для постійного розповсюдження через TestFlight/App Store знадобиться Apple Developer Program. Для особистого тестування можна почати з безплатного Apple ID та Xcode, з обмеженнями строку дії підпису.

**Важливо:** на обох пристроях потрібно використовувати однаковий Supabase URL/key і входити під тим самим обліковим записом. Синхронізація потребує інтернету. iOS-застосунок, згорнутий у фон, може тимчасово роз'єднувати Realtime-сокет; після повернення в активний стан клієнт перепідключиться.

## Перевірка синхронізації

1. Увійди під одним e-mail на Windows і на iPhone.
2. Створи нотатку на ПК, натисни **Готово**.
3. У відкритому iPhone-застосунку вона має з'явитися автоматично.
4. Зміни текст чи колір на iPhone: на ПК зміна має відобразитися після синхронізації.

## Наступні етапи

- Кеш SQLite та надійна офлайн-черга з вирішенням конфліктів.
- Фотографії, аудіозаписи, ручне малювання на нотатках.
- Категорії, дошки і важливі/закріплені записки.
- Резервне копіювання, експорт та відновлення.
- Спрощене встановлення на Windows та стабільне підписування для iOS.
