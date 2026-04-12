import 'package:flutter/material.dart';

class BrowseCategory {
  const BrowseCategory(this.title, this.color, this.icon);

  final String title;
  final Color color;
  final IconData icon;
}

class BrowseCategoryTile extends StatelessWidget {
  const BrowseCategoryTile({
    super.key,
    required this.category,
  });

  final BrowseCategory category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: category.color,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 14,
                right: 56,
                child: Text(
                  category.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -6,
                child: Transform.rotate(
                  angle: -0.38,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 32,
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
