import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/network/supabase_client.dart';

final searchResultsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('products')
      .select('id, title, slug, brand, price_coins, images, vehicle_make, vehicle_model, avg_rating')
      .or('title.ilike.%$query%,brand.ilike.%$query%,vehicle_make.ilike.%$query%,vehicle_model.ilike.%$query%')
      .eq('is_active', true).eq('is_approved', true).limit(24);
  return List<Map<String, dynamic>>.from(data as List);
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(searchResultsProvider(_query));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl, autofocus: true,
          onSubmitted: (v) => setState(() => _query = v.trim()),
          decoration: const InputDecoration(hintText: 'Search parts, brands, vehicles...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
        ),
        actions: [TextButton(onPressed: () => setState(() => _query = _ctrl.text.trim()), child: const Text('Search'))],
      ),
      body: _query.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('🔍', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text('Search for auto parts', style: TextStyle(fontSize: 16, color: AppTheme.textMuted)),
              SizedBox(height: 8),
              Text('Try "Brembo brakes" or "BMW M3 suspension"', style: TextStyle(fontSize: 12, color: AppTheme.textDim)),
            ]))
          : resultsAsync.when(
              data: (results) => results.isEmpty
                  ? Center(child: Text('No results for "$_query"', style: const TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16), itemCount: results.length,
                      itemBuilder: (ctx, i) {
                        final p = results[i];
                        return GestureDetector(
                          onTap: () => context.push('/product/${p["slug"]}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
                            child: Row(children: [
                              Container(width: 56, height: 56, decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor)), child: const Center(child: Text('⚙️', style: TextStyle(fontSize: 28)))),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                Text('${p['brand'] ?? ''} · ${p['vehicle_make'] ?? ''} ${p['vehicle_model'] ?? ''}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              ])),
                              Text('${p['price_coins']} AXC', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.goldPrimary)),
                            ]),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
    );
  }
}
