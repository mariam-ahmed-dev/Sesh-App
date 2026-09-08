import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'core/network/news_api.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_radius.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/common.dart';
import 'features/news/domain/models.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const SeshBootstrap());

class SeshBootstrap extends StatelessWidget {
  const SeshBootstrap({super.key});
  @override Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => ThemeCubit()),
      BlocProvider(create: (_) => LanguageCubit()),
      BlocProvider(create: (_) => SavedCubit()),
      BlocProvider(create: (_) => InterestsCubit()..load()),
      BlocProvider(create: (_) => HomeCubit(NewsApiRepository())..load()),
      BlocProvider(create: (_) => OnboardingCubit()..load()),
    ],
    child: const SeshApp(),
  );
}

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);
  void set(ThemeMode mode) => emit(mode);
}
class InterestsCubit extends Cubit<Set<String>> {
  InterestsCubit() : super(<String>{});
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit((prefs.getStringList('interests') ?? const []).toSet());
  }
  Future<void> toggle(String interest) async {
    final next = {...state};
    next.contains(interest) ? next.remove(interest) : next.add(interest);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('interests', next.toList());
    emit(next);
  }
}
class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en'));
  void toggle() => emit(state.languageCode == 'en' ? const Locale('ar') : const Locale('en'));
}
class OnboardingCubit extends Cubit<bool> {
  OnboardingCubit() : super(false);
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    emit(prefs.getBool('onboarding_done') ?? false);
  }
  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    emit(true);
  }
}
class SavedCubit extends Cubit<Set<String>> {
  SavedCubit() : super(<String>{}) { _load(); }
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    emit((p.getStringList('saved_titles') ?? const []).toSet());
  }
  Future<void> toggle(String title) async {
    final next = {...state};
    next.contains(title) ? next.remove(title) : next.add(title);
    final p = await SharedPreferences.getInstance();
    await p.setStringList('saved_titles', next.toList());
    emit(next);
  }
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_titles');
    emit(<String>{});
  }
}
class HomeCubit extends Cubit<NewsState> {
  HomeCubit(this.repository) : super(const NewsState.loading());
  final NewsApiRepository repository;
  String _query = 'ancient Egypt';
  int _page = 0;
  bool _requestInFlight = false;
  Future<void> load([String query = 'ancient Egypt']) async {
    _query = query;
    _page = 1;
    emit(const NewsState.loading());
    try {
      final articles = await repository.search(query, page: _page);
      emit(NewsState.success(articles, hasMore: articles.isNotEmpty));
    } catch (error) {
      emit(NewsState.error(error.toString()));
    }
  }
  Future<void> loadMore() async {
    if (_requestInFlight || state.loading || !state.hasMore) return;
    _requestInFlight = true;
    emit(state.loadingMoreState());
    try {
      final nextPage = _page + 1;
      final incoming = await repository.search(_query, page: nextPage);
      final known = state.articles.map((article) => article.url ?? article.title).toSet();
      final additions = incoming.where((article) => !known.contains(article.url ?? article.title)).toList();
      _page = nextPage;
      emit(state.append(additions, hasMore: incoming.isNotEmpty));
    } catch (error) {
      emit(state.paginationErrorState(error.toString()));
    } finally {
      _requestInFlight = false;
    }
  }
}
class NewsState {
  const NewsState._(this.articles, this.loading, this.loadingMore, this.hasMore, this.error);
  const NewsState.loading() : this._(const [], true, false, true, null);
  const NewsState.success(List<NewsArticle> a, {bool hasMore = true}) : this._(a, false, false, hasMore, null);
  const NewsState.error(String e) : this._(const [], false, false, false, e);
  final List<NewsArticle> articles;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  NewsState loadingMoreState() => NewsState._(articles, false, true, hasMore, error);
  NewsState append(List<NewsArticle> incoming, {required bool hasMore}) => NewsState._([...articles, ...incoming], false, false, hasMore, null);
  NewsState paginationErrorState(String value) => NewsState._(articles, false, false, hasMore, value);
}

class SeshApp extends StatelessWidget {
  const SeshApp({super.key});
  @override Widget build(BuildContext context) => BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (_, mode) => BlocBuilder<LanguageCubit, Locale>(
      builder: (_, locale) => MaterialApp(
        debugShowCheckedModeBanner: false, title: 'SESH',
        theme: buildSeshTheme(Brightness.light), darkTheme: buildSeshTheme(Brightness.dark),
        themeMode: mode, locale: locale,
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: BlocBuilder<OnboardingCubit, bool>(builder: (_, done) => !done
            ? const OnboardingPage()
            : BlocBuilder<InterestsCubit, Set<String>>(builder: (_, interests) =>
                interests.isEmpty ? const InterestsPage() : const Shell())),
      ),
    ),
  );
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override State<OnboardingPage> createState() => _OnboardingPageState();
}
class _OnboardingPageState extends State<OnboardingPage> {
  final page = PageController(); int index = 0;
  final items = const [
    ('THE PAST IS FULL OF STORIES.', 'Discover Ancient Egypt beyond the headlines.'),
    ('TURN NEWS INTO KNOWLEDGE.', 'Explore people, places, and stories behind discoveries.'),
    ('YOUR JOURNEY STARTS HERE.', 'Read. Explore. Ask. Discover.'),
  ];
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(body: SafeArea(child: Padding(
    padding: const EdgeInsets.all(AppSpacing.xl), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SeshGlyph(size: 52), const Spacer(),
      SizedBox(height: 270, child: PageView.builder(controller: page, itemCount: items.length,
        onPageChanged: (i) => setState(() => index = i), itemBuilder: (_, i) => Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('SESH', style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 3, color: AppColors.gold)),
            const SizedBox(height: 18), Text(items[i].$1, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16), Text(items[i].$2, style: Theme.of(context).textTheme.titleMedium)]))),
      Row(children: List.generate(items.length, (i) => AnimatedContainer(duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(right: 6), width: i == index ? 32 : 8, height: 6,
        decoration: BoxDecoration(color: i == index ? AppColors.egyptianBlue : AppColors.limestone, borderRadius: BorderRadius.circular(9))))),
      const SizedBox(height: AppSpacing.xl),
      PrimaryButton(label: index == items.length - 1 ? l10n.startExploring : l10n.continueLabel,
        onPressed: () { if (index < items.length - 1) page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut); else context.read<OnboardingCubit>().complete(); }),
      TextButton(onPressed: () => context.read<OnboardingCubit>().complete(), child: Text(l10n.skip)),
    ],
  ))));
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override State<Shell> createState() => _ShellState();
}
class _ShellState extends State<Shell> {
  int selected = 0;
  final pages = const [HomePage(), ExplorePage(), MapPage(), AskPage(), SavedPage()];
  @override Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Row(children: [if (wide) _Sidebar(selected: selected, onSelected: (i) => setState(() => selected = i)), Expanded(child: pages[selected])]),
      bottomNavigationBar: wide ? null : NavigationBar(selectedIndex: selected, onDestinationSelected: (i) => setState(() => selected = i),
        destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'), NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'), NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'Ask'), NavigationDestination(icon: Icon(Icons.bookmark_outline), label: 'Saved')]),
    );
  }
}
class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.selected, required this.onSelected});
  final int selected; final ValueChanged<int> onSelected;
  @override Widget build(BuildContext context) => NavigationRail(
    selectedIndex: selected, onDestinationSelected: onSelected, labelType: NavigationRailLabelType.all,
    leading: const Padding(padding: EdgeInsets.all(16), child: SeshGlyph()),
    destinations: const [NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')),
      NavigationRailDestination(icon: Icon(Icons.explore_outlined), label: Text('Explore')), NavigationRailDestination(icon: Icon(Icons.map_outlined), label: Text('Map')),
      NavigationRailDestination(icon: Icon(Icons.auto_awesome_outlined), label: Text('Ask Sesh')), NavigationRailDestination(icon: Icon(Icons.bookmark_outline), label: Text('Saved'))],
  );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(onRefresh: () => context.read<HomeCubit>().load(), child: NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification.metrics.extentAfter < 280) context.read<HomeCubit>().loadMore();
      return false;
    },
    child: CustomScrollView(slivers: [
    SliverAppBar(title: const Text('SESH'), actions: [
      IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.settings_outlined)),
      IconButton(onPressed: () => context.read<LanguageCubit>().toggle(), icon: const Icon(Icons.language)),
      IconButton(onPressed: () => context.read<ThemeCubit>().set(Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark), icon: const Icon(Icons.brightness_6_outlined)),
    ]),
    SliverPadding(padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0), sliver: SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.goodEvening, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 6), Text('FOLLOW THE STORY.', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.gold, letterSpacing: 2)),
      const SizedBox(height: AppSpacing.xl), SearchField(controller: TextEditingController(), onSubmitted: (q) => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialQuery: q)))),
      const SizedBox(height: AppSpacing.xl), _HeroDiscovery(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExplorePage()))),
      const SizedBox(height: AppSpacing.xl), Text(l10n.discover, style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2, color: AppColors.gold)),
      const SizedBox(height: AppSpacing.md), Wrap(spacing: 10, runSpacing: 10, children: ['People', 'Places', 'Dynasties', 'Artifacts', 'Gods'].map((x) => ActionChip(label: Text(x), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryPage(category: x))))).toList()),
      const SizedBox(height: AppSpacing.xl), Text(l10n.latestNews, style: Theme.of(context).textTheme.labelLarge?.copyWith(letterSpacing: 2, color: AppColors.gold)),
    ]))),
    BlocBuilder<HomeCubit, NewsState>(builder: (_, state) {
      if (state.loading) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
      if (state.error != null && state.articles.isEmpty) return SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(l10n.offline),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => context.read<HomeCubit>().load(), child: Text(l10n.tryAgain)),
      ])));

      final footer = state.loadingMore || state.error != null;
      return SliverPadding(padding: const EdgeInsets.all(AppSpacing.xl), sliver: SliverList.builder(
        itemCount: state.articles.length + (footer ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == state.articles.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: state.loadingMore
                  ? const CircularProgressIndicator()
                  : const Text('Could not load more stories.')),
            );
          }
          return NewsCard(article: state.articles[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(article: state.articles[i]))));
        },
      ));
    }),
  ])));
}
}
class _HeroDiscovery extends StatelessWidget { const _HeroDiscovery({required this.onTap}); final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(color: AppColors.nileMidnight, child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text("TODAY'S DISCOVERY", style: TextStyle(color: AppColors.gold, letterSpacing: 1.5, fontWeight: FontWeight.bold)), const SizedBox(height: 48),
    const Text('The story is only the beginning.', style: TextStyle(color: AppColors.limestone, fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
    const Text('Read the news. Find the history.', style: TextStyle(color: AppColors.limestone)), const SizedBox(height: 24),
    FilledButton(onPressed: onTap, child: const Text('READ DISCOVERY')),
  ])))); }

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key, required this.article}); final NewsArticle article;
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(actions: [BlocBuilder<SavedCubit, Set<String>>(builder: (_, saved) => IconButton(onPressed: () => context.read<SavedCubit>().toggle(article.title), icon: Icon(saved.contains(article.title) ? Icons.bookmark : Icons.bookmark_outline)))]),
    body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      Text(article.category.toUpperCase(), style: const TextStyle(color: AppColors.gold, letterSpacing: 2, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), Text(article.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12), Text(article.source, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 28), Container(height: 190, decoration: BoxDecoration(color: AppColors.egyptianBlue.withValues(alpha: .2), borderRadius: BorderRadius.circular(18)), child: const Center(child: Icon(Icons.auto_stories, size: 72, color: AppColors.egyptianBlue))),
      const SizedBox(height: 24), Text(article.description ?? 'A discovery waiting to be understood.', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 36), Text('UNDERSTAND THE DISCOVERY', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.gold, letterSpacing: 1.8)),
      const SizedBox(height: 12), const Text('THIS STORY CONNECTS TO', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16), Wrap(spacing: 8, children: ['Location', 'Period', 'People', 'Related stories'].map((x) => Chip(label: Text(x))).toList()),
      const SizedBox(height: 24), PrimaryButton(label: 'READ FULL ARTICLE', onPressed: article.url == null ? null : () async {
        final uri = Uri.tryParse(article.url!);
        if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
      }),
    ]));
}

class InterestsPage extends StatelessWidget {
  const InterestsPage({super.key});
  static const interests = ['Archaeology', 'Pharaohs', 'Mythology', 'Museums', 'Travel', 'Ancient Life'];
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              const SeshGlyph(),
              const SizedBox(height: 32),
              Text(l10n.interestsTitle, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(l10n.interestsSubtitle),
              const SizedBox(height: 24),
              BlocBuilder<InterestsCubit, Set<String>>(builder: (_, selected) => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: interests.map((interest) => FilterChip(
                      label: Text(interest),
                      selected: selected.contains(interest),
                      onSelected: (_) => context.read<InterestsCubit>().toggle(interest),
                    )).toList(),
                  )),
              const SizedBox(height: 32),
              PrimaryButton(label: l10n.continueExploring, onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()))),
            ],
          ),
        ),
      );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key, this.initialQuery = ''});
  final String initialQuery;
  @override State<SearchPage> createState() => _SearchPageState();
}
class _SearchPageState extends State<SearchPage> {
  late final TextEditingController controller = TextEditingController(text: widget.initialQuery);
  late Future<List<NewsArticle>> request = _search(widget.initialQuery.isEmpty ? 'ancient Egypt' : widget.initialQuery);
  Future<List<NewsArticle>> _search(String query) => NewsApiRepository().search(query);
  void submit(String query) => setState(() => request = _search(query));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SEARCH')),
    body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      SearchField(controller: controller, onSubmitted: submit),
      const SizedBox(height: 24),
      const Text('NEWS', style: TextStyle(color: AppColors.gold, letterSpacing: 2, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      FutureBuilder<List<NewsArticle>>(future: request, builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('THE ARCHIVE IS TEMPORARILY OFFLINE')));
        final results = snapshot.data ?? const <NewsArticle>[];
        if (results.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("WE COULDN'T FIND THAT STORY.")));
        return Column(children: results.map((article) => NewsCard(
          article: article,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(article: article))),
        )).toList());
      }),
    ]),
  );
}

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key, required this.category});
  final String category;
  @override State<CategoryPage> createState() => _CategoryPageState();
}
class _CategoryPageState extends State<CategoryPage> {
  late Future<List<NewsArticle>> request = NewsApiRepository().category(widget.category);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.category.toUpperCase())),
    body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      Text('NEWS → CONTEXT → HISTORY', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.gold, letterSpacing: 1.5)),
      const SizedBox(height: 10),
      Text('Stories connected to ${widget.category.toLowerCase()}.'),
      const SizedBox(height: 20),
      FutureBuilder<List<NewsArticle>>(future: request, builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
        final articles = snapshot.data ?? const <NewsArticle>[];
        return Column(children: articles.map((article) => NewsCard(
          article: article,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(article: article))),
        )).toList());
      }),
      const SizedBox(height: 20),
      OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourcesPage(category: widget.category))), icon: const Icon(Icons.tune), label: const Text('CHOOSE A SOURCE')),
    ]),
  );
}

class SourcesPage extends StatelessWidget {
  const SourcesPage({super.key, required this.category});
  final String category;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SOURCES')),
    body: FutureBuilder<List<NewsSource>>(future: NewsApiRepository().getSources(), builder: (_, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Text(snapshot.error.toString()));
      final sources = snapshot.data ?? const <NewsSource>[];
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: sources.length,
        itemBuilder: (_, i) => Card(child: ListTile(
          leading: const Icon(Icons.public, color: AppColors.egyptianBlue),
          title: Text(sources[i].name),
          subtitle: Text(sources[i].description ?? 'Latest stories from this source.'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceArticlesPage(source: sources[i], category: category))),
        )),
      );
    }),
  );
}

class SourceArticlesPage extends StatelessWidget {
  const SourceArticlesPage({super.key, required this.source, required this.category});
  final NewsSource source;
  final String category;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(source.name)),
    body: FutureBuilder<List<NewsArticle>>(
      future: NewsApiRepository().search(category, sources: source.id),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final articles = snapshot.data ?? const <NewsArticle>[];
        return ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: articles.map((article) => NewsCard(article: article, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticlePage(article: article))))).toList());
      },
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('SETTINGS')),
    body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      const SeshGlyph(),
      const SizedBox(height: 24),
      Text('APPEARANCE', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.gold, letterSpacing: 1.5)),
      BlocBuilder<ThemeCubit, ThemeMode>(builder: (_, mode) => SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(value: ThemeMode.system, label: Text('System')),
          ButtonSegment(value: ThemeMode.light, label: Text('Light')),
          ButtonSegment(value: ThemeMode.dark, label: Text('Night')),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => context.read<ThemeCubit>().set(selection.first),
      )),
      const Divider(),
      ListTile(title: const Text('Interests'), trailing: const Icon(Icons.arrow_forward), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InterestsPage()))),
      ListTile(title: const Text('Language · English / العربية'), trailing: const Icon(Icons.language), onTap: () => context.read<LanguageCubit>().toggle()),
      ListTile(title: const Text('Clear saved discoveries'), trailing: const Icon(Icons.delete_outline), onTap: () async {
        await context.read<SavedCubit>().clear();
      }),
      const SizedBox(height: 24),
      const Text('SESH · Follow the story.'),
    ]),
  );
}

class ExplorePage extends StatelessWidget { const ExplorePage({super.key});
  @override Widget build(BuildContext context) => _SimplePage(title: 'EXPLORE ANCIENT EGYPT', subtitle: 'People, places and ideas that connect every story.', items: const [
    Discovery('People', 'Pharaohs · Scribes · Queens', '♙'), Discovery('Places', 'Temples · Tombs · Cities', '⌂'), Discovery('Dynasties', 'A living timeline of power', '◈'), Discovery('Artifacts', 'Statues · Jewelry · Writing', '◇'), Discovery('Mythology', 'Gods · Stories · Symbols', '✦'), Discovery('Daily Life', 'Food · Work · Family', '☼')]); }
class _SimplePage extends StatelessWidget { const _SimplePage({required this.title, required this.subtitle, required this.items}); final String title, subtitle; final List<Discovery> items;
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [const SeshGlyph(), const SizedBox(height: 28), Text(title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text(subtitle), const SizedBox(height: 28), ...items.map((d) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: Text(d.icon, style: const TextStyle(fontSize: 32)), title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(d.subtitle), trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: () {
    final page = switch (d.title) {
      'Places' => const MapPage(),
      'People' => const PersonDetailsPage(),
      'Dynasties' => const TimelinePage(),
      _ => null,
    };
    if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }))) ]); }
class PersonDetailsPage extends StatelessWidget { const PersonDetailsPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('TUTANKHAMUN')), body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
    const SeshGlyph(), const SizedBox(height: 24), Text('Tutankhamun', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), const Text('18th Dynasty · New Kingdom · c. 1341–1323 BCE'),
    const SizedBox(height: 28), const Text('STORY', style: TextStyle(color: AppColors.gold, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8), const Text('A young king whose discovery became one of the most enduring stories of Ancient Egypt.'),
    const SizedBox(height: 24), PrimaryButton(label: 'EXPLORE HIS WORLD', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimelinePage()))),
  ])); }
class TimelinePage extends StatefulWidget { const TimelinePage({super.key}); @override State<TimelinePage> createState() => _TimelinePageState(); }
class _TimelinePageState extends State<TimelinePage> {
  int selected = 0;
  static const periods = ['Early Dynastic', 'Old Kingdom', 'Middle Kingdom', 'New Kingdom', 'Late Period', 'Ptolemaic'];
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('TIMELINE')), body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
    const Text('HISTORY IN MOTION', style: TextStyle(color: AppColors.gold, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
    const SizedBox(height: 18), ...List.generate(periods.length, (i) => Card(color: i == selected ? AppColors.egyptianBlue : null, child: ListTile(onTap: () => setState(() => selected = i), title: Text(periods[i], style: TextStyle(color: i == selected ? AppColors.limestone : null, fontWeight: FontWeight.bold)), subtitle: Text(i == selected ? 'Selected historical skin' : 'Explore this period')))),
  ])); }
class MapPage extends StatefulWidget { const MapPage({super.key}); @override State<MapPage> createState() => _MapPageState(); }
class _MapPageState extends State<MapPage> {
  String filter = 'All';
  static const places = [
    ('Saqqara', 'Tombs', 'Memphis Necropolis · Old Kingdom'),
    ('Luxor', 'Temples', 'Temples · New Kingdom'),
    ('Alexandria', 'Museums', 'Mediterranean crossroads · Ptolemaic'),
    ('Giza', 'Discoveries', 'Monuments · Old Kingdom'),
  ];
  @override Widget build(BuildContext context) {
    final visible = filter == 'All' ? places : places.where((place) => place.$2 == filter).toList();
    return ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      const SeshGlyph(),
      const SizedBox(height: 24),
      Text('ANCIENT EGYPT MAP', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Trace the places behind the stories.'),
      const SizedBox(height: 20),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['All', 'Temples', 'Tombs', 'Museums', 'Cities', 'Discoveries'].map((item) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(label: Text(item), selected: filter == item, onSelected: (_) => setState(() => filter = item)),
      )).toList())),
      const SizedBox(height: 20),
      Container(height: 180, decoration: BoxDecoration(color: AppColors.nileMidnight, borderRadius: BorderRadius.circular(AppRadius.card)),
        child: const Center(child: Icon(Icons.map_outlined, color: AppColors.limestone, size: 64))),
      const SizedBox(height: 16),
      ...visible.map((place) => Card(child: ListTile(
        leading: const Icon(Icons.location_on_outlined, color: AppColors.egyptianBlue),
        title: Text(place.$1),
        subtitle: Text('${place.$2} · ${place.$3}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsPage(name: place.$1, contextLine: place.$3))),
      ))),
    ]);
  }
}
class PlaceDetailsPage extends StatelessWidget {
  const PlaceDetailsPage({super.key, required this.name, required this.contextLine});
  final String name;
  final String contextLine;
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(name)),
    body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
      Container(height: 190, decoration: BoxDecoration(color: AppColors.nileMidnight, borderRadius: BorderRadius.circular(AppRadius.card)), child: const Center(child: Icon(Icons.account_balance_outlined, color: AppColors.limestone, size: 72))),
      const SizedBox(height: 24),
      Text(name, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(contextLine, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 28), const Text('ABOUT', style: TextStyle(color: AppColors.gold, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('A place where architecture, people and discovery connect across time.'),
      const SizedBox(height: 24), const Text('RELATED DISCOVERIES', style: TextStyle(color: AppColors.gold, letterSpacing: 1.6, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), const Text('Explore nearby sites, historical context and the latest stories from the archive.'),
    ]),
  );
}
class AskPage extends StatefulWidget { const AskPage({super.key}); @override State<AskPage> createState() => _AskPageState(); }
class _AskPageState extends State<AskPage> { final controller = TextEditingController(); String answer = ''; bool loading = false;
  Future<void> ask(String question) async {
    if (question.trim().isEmpty) return;
    setState(() { loading = true; answer = ''; });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    setState(() {
      loading = false;
      answer = 'The Scribe connects this question to people, places and a living timeline of Ancient Egypt.';
    });
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
    const SeshGlyph(), const SizedBox(height: 24),
    Text('ASK THE SCRIBE', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
    const Text('Ask about Ancient Egypt.'),
    const SizedBox(height: 28),
    ...['Who built the pyramids?', 'What should I see in Luxor?', 'Explain this discovery.'].map((p) => AiPrompt(text: p, onTap: () => ask(p))),
    if (loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
    if (answer.isNotEmpty) Card(color: AppColors.lapis, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('ANSWER', style: TextStyle(color: AppColors.gold, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8), Text(answer, style: const TextStyle(color: AppColors.limestone, fontSize: 17)),
      const SizedBox(height: 16), const Text('RELATED · Luxor · New Kingdom · Scribes', style: TextStyle(color: AppColors.limestone)),
      const SizedBox(height: 8), const Text('SOURCES · SESH historical archive', style: TextStyle(color: AppColors.limestone)),
    ]))),
    const SizedBox(height: 16),
    TextField(controller: controller, onSubmitted: ask, decoration: const InputDecoration(hintText: 'Ask the Scribe…', suffixIcon: Icon(Icons.send))),
  ]); }
class AiPrompt extends StatelessWidget { const AiPrompt({super.key, required this.text, required this.onTap}); final String text; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(child: ListTile(onTap: onTap, title: Text(text), trailing: const Icon(Icons.arrow_forward))); }
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});
  @override
  Widget build(BuildContext context) {
    final saved = context.watch<SavedCubit>().state;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const SeshGlyph(),
        const SizedBox(height: 24),
        Text('MY DISCOVERIES', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Articles · Places · People · Topics'),
        const SizedBox(height: 24),
        if (saved.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.only(top: 80), child: Text('Your discoveries will appear here.')))
        else
          ...saved.map((title) => Card(child: ListTile(title: Text(title), leading: const Icon(Icons.bookmark), onTap: () {}))),
      ],
    );
  }
}
