import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class SeshGlyph extends StatelessWidget {
  const SeshGlyph({super.key, this.size = 44});
  final double size;
  @override Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: AppColors.egyptianBlue, borderRadius: BorderRadius.circular(size * .28)),
    child: Center(child: Text('𓂀', style: TextStyle(color: AppColors.limestone, fontSize: size * .45))),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});
  final String label; final VoidCallback? onPressed; final IconData? icon;
  @override Widget build(BuildContext context) => SizedBox(
    height: 52, child: FilledButton.icon(onPressed: onPressed, icon: Icon(icon ?? Icons.arrow_forward_rounded),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .5))),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({super.key, required this.controller, required this.onSubmitted});
  final TextEditingController controller; final ValueChanged<String> onSubmitted;
  @override Widget build(BuildContext context) => TextField(
    controller: controller, onSubmitted: onSubmitted,
    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search Ancient Egypt…'),
  );
}

class NewsCard extends StatelessWidget {
  const NewsCard({super.key, required this.article, required this.onTap});
  final dynamic article; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias, child: InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg), child: Row(children: [
        SizedBox(width: 72, height: 72, child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: article.imageUrl == null
              ? ColoredBox(color: AppColors.egyptianBlue.withValues(alpha: .18), child: const Icon(Icons.auto_stories_outlined, color: AppColors.egyptianBlue, size: 30))
              : Image.network(article.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.egyptianBlue, child: Icon(Icons.auto_stories_outlined, color: AppColors.limestone, size: 30))),
        )),
        const SizedBox(width: AppSpacing.lg), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('DISCOVERY', style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.3)),
          const SizedBox(height: 5), Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6), Text(article.source, style: Theme.of(context).textTheme.bodySmall),
        ])),
      ]),
    )),
  );
}
