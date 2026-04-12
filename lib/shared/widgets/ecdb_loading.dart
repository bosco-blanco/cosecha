import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/ecdb_colors.dart';

/// Shimmer loading ECDB — skeleton mientras cargan datos.
class ECDBLoading extends StatelessWidget {
  final int itemCount;

  const ECDBLoading({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: ECDBColors.bgAlt,
      highlightColor: ECDBColors.surface,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: ECDBColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Indicador de carga centrado con estilo ECDB.
class ECDBLoadingIndicator extends StatelessWidget {
  final String? message;

  const ECDBLoadingIndicator({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: ECDBColors.wine,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ECDBColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
