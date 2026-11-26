import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

// Floating card-style message used across the app instead of the plain
// SnackBar: an icon badge, a title, a short message and an optional action.
// Light card on purpose, so it stands out against the dark green screens.
const _toastBackground = offWhite;
const _toastTitle = Color(0xFF0B0F0C);
const _toastMessage = Color(0xFF4A554D);
const _toastAction = Color(0xFF0A7A3D);

void showAppSnackBar(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? message,
  Color accent = gainColor,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: _toastBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _toastTitle,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _toastMessage,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _toastAction,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ),
      ),
    );
}

// Watchlist add/remove feedback with an Undo, shared by every screen
void showWatchlistSnackBar(
  BuildContext context, {
  required String coinName,
  required bool added,
  required VoidCallback onUndo,
}) {
  showAppSnackBar(
    context,
    icon: added ? Icons.star : Icons.star_border,
    accent: added ? starColor : Colors.grey,
    title: added ? 'Added to watchlist' : 'Removed from watchlist',
    message: added
        ? '$coinName is now in your watchlist'
        : '$coinName is no longer in your watchlist',
    actionLabel: 'Undo',
    onAction: onUndo,
  );
}

void showComingSoonSnackBar(BuildContext context, String feature) {
  showAppSnackBar(
    context,
    icon: Icons.rocket_launch_outlined,
    title: '$feature coming soon',
    message: "We're working on it. Stay tuned!",
  );
}
