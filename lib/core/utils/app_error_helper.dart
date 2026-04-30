import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class AppErrorHelper {
  static String toUserMessage(
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (error == null) return fallback;

    if (error is DioException) {
      final statusCode = error.response?.statusCode;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The request timed out. Please check your internet and try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect right now. Please check your internet connection.';
        case DioExceptionType.badResponse:
          if (statusCode == 401) {
            return 'Your session has expired. Please log in again.';
          }
          if (statusCode == 403) {
            return 'You do not have permission to perform this action.';
          }
          if (statusCode == 404) {
            return 'The requested information could not be found.';
          }
          if (statusCode == 422) {
            return _extractMessage(error.response?.data) ??
                'Some information is invalid. Please review and try again.';
          }
          if (statusCode != null && statusCode >= 500) {
            return 'The server is temporarily unavailable. Please try again later.';
          }
          return _extractMessage(error.response?.data) ??
              'We could not complete the request right now. Please try again.';
        case DioExceptionType.cancel:
          return 'The request was cancelled.';
        case DioExceptionType.badCertificate:
          return 'A secure connection could not be established.';
        case DioExceptionType.unknown:
          return 'Unexpected network error. Please try again.';
      }
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is TimeoutException) {
      return 'The request took too long. Please try again.';
    }

    if (error is FormatException) {
      return 'We received invalid data from the server. Please try again later.';
    }

    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = message.toLowerCase();

    if (lower.contains(
      'type \'null\' is not a subtype of type \'map<string, dynamic>\'',
    )) {
      return 'Some data from the server is incomplete right now. Please try again later.';
    }
    if (lower.contains('failed to load categories') ||
        lower.contains('error fetching categories')) {
      return 'Categories are unavailable right now. Please try again shortly.';
    }
    if (lower.contains('failed to load notifications')) {
      return 'Notifications could not be loaded right now.';
    }
    if (lower.contains('failed to load stores')) {
      return 'Store information is unavailable right now.';
    }
    if (lower.contains('failed to load orders')) {
      return 'Orders could not be loaded right now.';
    }
    if (lower.contains('failed to fetch available shops')) {
      return 'Nearby shops could not be loaded for this address right now.';
    }
    if (lower.contains('failed to add to cart')) {
      return 'Could not add the item to your cart. Please try again.';
    }
    if (lower.contains('failed to update cart')) {
      return 'Could not update your cart right now. Please try again.';
    }
    if (lower.contains('failed to remove from cart')) {
      return 'Could not remove the item right now. Please try again.';
    }
    if (lower.contains('failed to fetch blog posts')) {
      return 'Blog posts are unavailable right now. Please try again later.';
    }
    if (lower.contains('failed to post comment')) {
      return 'Your comment could not be posted right now. Please try again.';
    }
    if (lower.contains('failed to fetch product details')) {
      return 'Product details are unavailable right now. Please try again later.';
    }
    if (lower.contains('permission')) {
      return 'Permission is required to continue with this action.';
    }

    if (message.isEmpty) return fallback;
    return message;
  }

  static void showSnackBar(
    BuildContext context,
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(content: Text(toUserMessage(error, fallback: fallback))),
    );
  }

  static void showGlobalSnackBar(
    GlobalKey<ScaffoldMessengerState> messengerKey,
    Object? error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    void showMessage() {
      final messenger = messengerKey.currentState;
      if (messenger == null) return;

      messenger.showSnackBar(
        SnackBar(content: Text(toUserMessage(error, fallback: fallback))),
      );
    }

    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      showMessage();
      return;
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      showMessage();
    });
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString().trim();
      }

      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first?.toString().trim();
            if (first != null && first.isNotEmpty) {
              return first;
            }
          }

          final text = value?.toString().trim();
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      }
    }
    return null;
  }
}

class AppErrorView extends StatelessWidget {
  final String message;

  const AppErrorView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F7FB),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFFF6B35),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
