import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

const List<String> kMoodEmojis = ['🥰', '🥳', '😆', '🤯', '😵‍💫'];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graititude days',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pageBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.appBarBackground,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      supportedLocales: const [Locale('ko'), Locale('en'), Locale('ja')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const LaunchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------
// SharedPreferences Helper
// -----------------------------------------------------
Future<void> saveDiary(DiaryEntry entry) async {
  final prefs = await SharedPreferences.getInstance();
  final oldList = prefs.getStringList('items') ?? <String>[];
  oldList.add(entry.encode());
  await prefs.setStringList('items', oldList);
}

Future<void> deleteDiary(DiaryEntry entry) async {
  final prefs = await SharedPreferences.getInstance();
  final oldList = prefs.getStringList('items') ?? <String>[];
  oldList.remove(entry.encode());
  await prefs.setStringList('items', oldList);
}

Future<List<DiaryEntry>> loadDiary() async {
  final prefs = await SharedPreferences.getInstance();
  final rawList = prefs.getStringList('items') ?? <String>[];
  return rawList.map(DiaryEntry.fromRaw).toList();
}

// -----------------------------------------------------
// 1) 오늘 감사한 일 입력 화면
// -----------------------------------------------------
class TodayInputScreen extends StatefulWidget {
  const TodayInputScreen({super.key});

  @override
  State<TodayInputScreen> createState() => _TodayInputScreenState();
}

class _TodayInputScreenState extends State<TodayInputScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _emojis = kMoodEmojis;
  int? _selectedIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEntrySheet() async {
    if (_selectedIndex == null) return;
    final parentContext = context;
    _controller.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final strings = AppStrings.of(context);
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.entryTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: strings.entryHint,
                  filled: true,
                  fillColor: AppColors.fieldBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    final entry = DiaryEntry(
                      date: formatDate(DateTime.now()),
                      emoji: _emojis[_selectedIndex!],
                      text: text,
                    );
                    await saveDiary(entry);
                    if (!mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(parentContext, true);
                  },
                  child: Text(strings.save),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.moodPrompt,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_emojis.length, (index) {
                  final selected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                }),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _selectedIndex == null
                            ? AppColors.disabledButton
                            : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _selectedIndex == null ? null : _openEntrySheet,
                  child: Text(
                    strings.next,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// 0) Launch Screen
// -----------------------------------------------------
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('🌈', style: TextStyle(fontSize: 48)),
                  SizedBox(width: 8),
                  Text('☁️', style: TextStyle(fontSize: 42)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                strings.appTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiaryListScreen(),
                      ),
                    );
                  },
                  child: Text(
                    strings.start,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// 2) 메인 리스트 화면
// -----------------------------------------------------
class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> {
  List<DiaryEntry> _items = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await loadDiary();
    if (!mounted) return;
    setState(() {
      _items = items;
    });
  }

  Future<void> _openInput() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const TodayInputScreen()),
    );
    if (saved == true) {
      await _refresh();
    }
  }

  Future<void> _openDetail(DiaryEntry entry) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DiaryDetailScreen(entry: entry)),
    );
    if (deleted == true) {
      await _refresh();
    }
  }

  Future<void> _openStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MonthlyStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'stats_fab',
            onPressed: _openStats,
            backgroundColor: AppColors.fabBackground,
            child: const Icon(Icons.bar_chart, color: AppColors.primaryText),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'add_fab',
            onPressed: _openInput,
            backgroundColor: AppColors.fabBackground,
            child: const Icon(Icons.add, color: AppColors.primaryText),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  strings.diaryTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _items.isEmpty
                        ? Center(
                          child: Text(
                            strings.emptyMessage,
                            style: TextStyle(color: AppColors.primaryText),
                          ),
                        )
                        : GridView.builder(
                          itemCount: _items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.92,
                              ),
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return GestureDetector(
                              onTap: () => _openDetail(item),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        item.date,
                                        style: TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Text(
                                        item.emoji,
                                        style: const TextStyle(fontSize: 36),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// 2-1) 월별 감정 통계 화면
// -----------------------------------------------------
class MonthlyStatsScreen extends StatefulWidget {
  const MonthlyStatsScreen({super.key});

  @override
  State<MonthlyStatsScreen> createState() => _MonthlyStatsScreenState();
}

class _MonthlyStatsScreenState extends State<MonthlyStatsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final monthKey = formatMonthKey(_selectedMonth);
    final monthLabel = strings.monthLabel(_selectedMonth.year, _selectedMonth.month);
    final canGoNext = _selectedMonth.isBefore(currentMonth);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.statsTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<DiaryEntry>>(
          future: loadDiary(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final monthlyItems =
                snapshot.data!
                    .where((entry) => entry.date.startsWith('$monthKey-'))
                    .toList();

            final counts = <String, int>{for (final emoji in kMoodEmojis) emoji: 0};
            for (final item in monthlyItems) {
              counts[item.emoji] = (counts[item.emoji] ?? 0) + 1;
            }

            final totalCount = counts.values.fold<int>(0, (sum, value) => sum + value);
            final maxCount = counts.values.fold<int>(0, (max, value) => value > max ? value : max);
            final topEntry =
                counts.entries.reduce(
                  (current, next) => next.value > current.value ? next : current,
                );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: _goToPreviousMonth,
                          icon: const Icon(Icons.chevron_left),
                          color: AppColors.primaryText,
                        ),
                        Text(
                          monthLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: canGoNext ? _goToNextMonth : null,
                          icon: const Icon(Icons.chevron_right),
                          color: AppColors.primaryText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.statsPrompt(monthLabel),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (totalCount == 0)
                    Text(
                      strings.noMonthlyData,
                      style: TextStyle(color: AppColors.secondaryText),
                    )
                  else
                    Text(
                      strings.topEmotionLabel(topEntry.key, topEntry.value),
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: kMoodEmojis.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final emoji = kMoodEmojis[index];
                        final count = counts[emoji] ?? 0;
                        final widthFactor = maxCount == 0 ? 0.0 : count / maxCount;
                        return Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 20,
                                      color: AppColors.fieldBackground,
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: widthFactor,
                                      child: Container(
                                        height: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 28,
                              child: Text(
                                '$count',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// 3) 상세 화면
// -----------------------------------------------------
class DiaryDetailScreen extends StatelessWidget {
  final DiaryEntry entry;
  const DiaryDetailScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.detailTitle),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await deleteDiary(entry);
          if (!context.mounted) return;
          Navigator.pop(context, true);
        },
        backgroundColor: AppColors.fabBackground,
        child: const Icon(Icons.delete, color: AppColors.primaryText),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  entry.date,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Text(entry.emoji, style: const TextStyle(fontSize: 44)),
                const SizedBox(height: 18),
                Text(
                  entry.text,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------
// Models + Style
// -----------------------------------------------------
class DiaryEntry {
  final String date;
  final String emoji;
  final String text;

  const DiaryEntry({
    required this.date,
    required this.emoji,
    required this.text,
  });

  String encode() =>
      '$date${_DiaryStorage.separator}$emoji${_DiaryStorage.separator}$text';

  static DiaryEntry fromRaw(String raw) {
    final parts = raw.split(_DiaryStorage.separator);
    if (parts.length >= 3) {
      return DiaryEntry(
        date: parts[0],
        emoji: parts[1],
        text: parts.sublist(2).join(_DiaryStorage.separator),
      );
    }
    return DiaryEntry(date: formatDate(DateTime.now()), emoji: '🙂', text: raw);
  }
}

class _DiaryStorage {
  static const String separator = '|||';
}

String formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

String formatMonthKey(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$year-$month';
}

class AppColors {
  static const Color pageBackground = Color(0xFFF6F7FF);
  static const Color appBarBackground = Color(0xFFE5EBFF);
  static const Color cardBackground = Color(0xFFE2E4F0);
  static const Color fieldBackground = Color(0xFFEFEFF7);
  static const Color primary = Color(0xFF4E5A86);
  static const Color primaryText = Color(0xFF4E5A86);
  static const Color secondaryText = Color(0xFF6C7393);
  static const Color disabledButton = Color(0xFFBFC5DA);
  static const Color fabBackground = Color(0xFFDDE3FB);
}

class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings(locale);
  }

  String get _lang => locale.languageCode;

  String get appTitle {
    switch (_lang) {
      case 'ko':
        return '감사일기';
      case 'ja':
        return '感謝日記';
      default:
        return 'Gratitude Diary';
    }
  }

  String get start {
    switch (_lang) {
      case 'ko':
        return '시작';
      case 'ja':
        return 'スタート';
      default:
        return 'Start';
    }
  }

  String get moodPrompt {
    switch (_lang) {
      case 'ko':
        return '오늘의 기분을 알려주세요';
      case 'ja':
        return '今日の気分を教えてください';
      default:
        return 'How are you feeling today?';
    }
  }

  String get next {
    switch (_lang) {
      case 'ko':
        return '다음';
      case 'ja':
        return '次へ';
      default:
        return 'Next';
    }
  }

  String get diaryTitle {
    switch (_lang) {
      case 'ko':
        return '감사일기';
      case 'ja':
        return '感謝日記';
      default:
        return 'Gratitude Diary';
    }
  }

  String get emptyMessage {
    switch (_lang) {
      case 'ko':
        return '아직 기록이 없어요.';
      case 'ja':
        return 'まだ記録がありません。';
      default:
        return 'No entries yet.';
    }
  }

  String get detailTitle {
    switch (_lang) {
      case 'ko':
        return '감사일기 상세';
      case 'ja':
        return '感謝日記詳細';
      default:
        return 'Diary Detail';
    }
  }

  String get entryTitle {
    switch (_lang) {
      case 'ko':
        return '오늘 감사한 일';
      case 'ja':
        return '今日感謝したこと';
      default:
        return 'Today\'s gratitude';
    }
  }

  String get entryHint {
    switch (_lang) {
      case 'ko':
        return '예: 오늘 커피가 정말 맛있었어';
      case 'ja':
        return '例：今日のコーヒーが本当に美味しかった';
      default:
        return 'e.g. The coffee today was great';
    }
  }

  String get save {
    switch (_lang) {
      case 'ko':
        return '저장하기';
      case 'ja':
        return '保存する';
      default:
        return 'Save';
    }
  }

  String get statsTitle {
    switch (_lang) {
      case 'ko':
        return '감정 통계';
      case 'ja':
        return '感情統計';
      default:
        return 'Emotion Stats';
    }
  }

  String statsPrompt(String monthLabel) {
    switch (_lang) {
      case 'ko':
        return '$monthLabel의 당신의 감정을 알아보세요';
      case 'ja':
        return '$monthLabel のあなたの感情を見てみましょう';
      default:
        return 'See your emotions in $monthLabel';
    }
  }

  String topEmotionLabel(String emoji, int count) {
    switch (_lang) {
      case 'ko':
        return '가장 많이 선택한 감정: $emoji ($count회)';
      case 'ja':
        return '最も選んだ感情: $emoji ($count回)';
      default:
        return 'Most selected emotion: $emoji ($count)';
    }
  }

  String get noMonthlyData {
    switch (_lang) {
      case 'ko':
        return '이번 달 기록이 아직 없어요.';
      case 'ja':
        return '今月の記録はまだありません。';
      default:
        return 'No entries for this month yet.';
    }
  }

  String monthLabel(int year, int month) {
    switch (_lang) {
      case 'ko':
        return '$year년 $month월';
      case 'ja':
        return '$year年$month月';
      default:
        const names = [
          '',
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${names[month]} $year';
    }
  }
}
