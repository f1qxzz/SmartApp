import 'package:flutter/material.dart';

import 'package:smartlife_app/core/theme/app_theme.dart';

class AppConstants {
  static const String appName = 'SmartLife';
  static const String appVersion = '1.0.0';
  static const String appLogoPath = 'assets/images/app_logo_transparent.png';
}

class FinanceCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const FinanceCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

final List<FinanceCategory> financeCategories = <FinanceCategory>[
  FinanceCategory(
    id: 'food',
    name: 'Makanan',
    icon: Icons.restaurant_rounded,
    color: AppColors.categoryColorsList[0],
  ),
  FinanceCategory(
    id: 'transport',
    name: 'Transport',
    icon: Icons.directions_car_rounded,
    color: AppColors.categoryColorsList[1],
  ),
  FinanceCategory(
    id: 'shopping',
    name: 'Belanja',
    icon: Icons.shopping_bag_rounded,
    color: AppColors.categoryColorsList[2],
  ),
  FinanceCategory(
    id: 'health',
    name: 'Kesehatan',
    icon: Icons.favorite_rounded,
    color: AppColors.categoryColorsList[3],
  ),
  FinanceCategory(
    id: 'entertainment',
    name: 'Hiburan',
    icon: Icons.movie_rounded,
    color: AppColors.categoryColorsList[4],
  ),
  FinanceCategory(
    id: 'education',
    name: 'Pendidikan',
    icon: Icons.school_rounded,
    color: AppColors.categoryColorsList[5],
  ),
  FinanceCategory(
    id: 'bills',
    name: 'Tagihan',
    icon: Icons.receipt_long_rounded,
    color: AppColors.categoryColorsList[6],
  ),
  FinanceCategory(
    id: 'other',
    name: 'Lainnya',
    icon: Icons.more_horiz_rounded,
    color: AppColors.categoryColorsList[7],
  ),
];

class MockTransaction {
  final String id;
  final String category;
  final String description;
  final double amount;
  final DateTime date;

  MockTransaction({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
  });
}

class MockMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final String? avatarUrl;

  MockMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.avatarUrl,
  });
}

class MockContact {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastSeen;
  final bool isOnline;
  final int unreadCount;
  final String avatarUrl;

  MockContact({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastSeen,
    required this.isOnline,
    required this.unreadCount,
    required this.avatarUrl,
  });
}

final List<MockTransaction> mockTransactions = <MockTransaction>[
  MockTransaction(
    id: '1',
    category: 'food',
    description: 'Makan siang di GoFood',
    amount: 45000,
    date: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  MockTransaction(
    id: '2',
    category: 'transport',
    description: 'Grab ke kantor',
    amount: 23000,
    date: DateTime.now().subtract(const Duration(hours: 5)),
  ),
  MockTransaction(
    id: '3',
    category: 'shopping',
    description: 'Beli sepatu Nike',
    amount: 850000,
    date: DateTime.now().subtract(const Duration(days: 1)),
  ),
  MockTransaction(
    id: '4',
    category: 'entertainment',
    description: 'Netflix subscription',
    amount: 54000,
    date: DateTime.now().subtract(const Duration(days: 2)),
  ),
  MockTransaction(
    id: '5',
    category: 'health',
    description: 'Vitamin dan suplemen',
    amount: 120000,
    date: DateTime.now().subtract(const Duration(days: 3)),
  ),
  MockTransaction(
    id: '6',
    category: 'bills',
    description: 'Listrik PLN',
    amount: 278000,
    date: DateTime.now().subtract(const Duration(days: 4)),
  ),
  MockTransaction(
    id: '7',
    category: 'food',
    description: 'Kopi Starbucks',
    amount: 65000,
    date: DateTime.now().subtract(const Duration(days: 4)),
  ),
];

final List<MockContact> mockContacts = <MockContact>[
  MockContact(
    id: '1',
    name: 'Aditya Rizky',
    lastMessage: 'Oke siap, sampai besok ya!',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
    isOnline: true,
    unreadCount: 3,
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
  MockContact(
    id: '2',
    name: 'Sari Dewi',
    lastMessage: 'Transfer udah masuk belum?',
    lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
    isOnline: true,
    unreadCount: 0,
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
  ),
  MockContact(
    id: '3',
    name: 'Budi Santoso',
    lastMessage: 'Thanks infonya bro!',
    lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
    isOnline: false,
    unreadCount: 0,
    avatarUrl: 'https://i.pravatar.cc/150?img=3',
  ),
  MockContact(
    id: '4',
    name: 'Maya Putri',
    lastMessage: 'Meeting jam 3 sore ya',
    lastSeen: DateTime.now().subtract(const Duration(hours: 3)),
    isOnline: false,
    unreadCount: 1,
    avatarUrl: 'https://i.pravatar.cc/150?img=9',
  ),
  MockContact(
    id: '5',
    name: 'Rizal Firmansyah',
    lastMessage: 'Coba cek laporan ini dulu',
    lastSeen: DateTime.now().subtract(const Duration(days: 1)),
    isOnline: false,
    unreadCount: 0,
    avatarUrl: 'https://i.pravatar.cc/150?img=7',
  ),
];

final List<MockMessage> mockMessages = <MockMessage>[
  MockMessage(
    id: '1',
    text: 'Hei, gimana kabar keuangan bulan ini?',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
  MockMessage(
    id: '2',
    text: 'Lumayan sih, udah mulai tracking pengeluaran pake SmartLife.',
    isMe: true,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 25)),
    isRead: true,
  ),
  MockMessage(
    id: '3',
    text: 'Wah mantap! Bisa liat spending pattern ya?',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 20)),
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
  MockMessage(
    id: '4',
    text: 'Iya, ternyata aku paling boros di makanan. Hampir 40% total pengeluaran.',
    isMe: true,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
    isRead: true,
  ),
  MockMessage(
    id: '5',
    text: 'AI assistantnya bisa kasih saran gak?',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 10)),
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
  MockMessage(
    id: '6',
    text: 'Bisa banget, langsung analisa data pengeluaran dan kasih tips personal.',
    isMe: true,
    timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
    isRead: false,
  ),
  MockMessage(
    id: '7',
    text: 'Keren! Nanti aku coba juga ah.',
    isMe: false,
    timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    avatarUrl: 'https://i.pravatar.cc/150?img=1',
  ),
];

class MockAiMessage {
  final String text;
  final bool isAi;
  final DateTime timestamp;

  MockAiMessage({
    required this.text,
    required this.isAi,
    required this.timestamp,
  });
}

final List<MockAiMessage> mockAiMessages = <MockAiMessage>[
  MockAiMessage(
    text: 'Halo! Saya SmartLife AI Assistant. Saya siap bantu analisa keuangan kamu.',
    isAi: true,
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
];
