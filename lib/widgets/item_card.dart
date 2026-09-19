import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    required this.item,
    required this.onTap,
    super.key,
  });

  final Item item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ItemThumb(imageUrl: item.imageUrl, isLost: item.isLost),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        _TypeBadge(isLost: item.isLost),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${item.category}  •  ${item.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.referenceNumber,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({this.imageUrl, required this.isLost});

  final String? imageUrl;
  final bool isLost;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 108,
      decoration: BoxDecoration(
        color: isLost ? const Color(0xFFEAF0F7) : const Color(0xFFF4E9EA),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null
          ? Icon(
              isLost ? Icons.search_rounded : Icons.volunteer_activism_outlined,
              color: isLost ? AppTheme.navy : AppTheme.burgundy,
              size: 30,
            )
          : Image.network(imageUrl!, fit: BoxFit.cover),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.isLost});

  final bool isLost;

  @override
  Widget build(BuildContext context) {
    final color = isLost ? AppTheme.navy : AppTheme.burgundy;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.09),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isLost ? 'LOST' : 'FOUND',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
        ),
      ),
    );
  }
}
