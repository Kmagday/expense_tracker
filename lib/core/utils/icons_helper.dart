import 'package:flutter/material.dart';

IconData iconFromString(String name) {
  switch (name) {
    case 'restaurant': return Icons.restaurant;
    case 'directions_car': return Icons.directions_car;
    case 'receipt_long': return Icons.receipt_long;
    case 'shopping_bag': return Icons.shopping_bag;
    case 'movie': return Icons.movie;
    case 'local_hospital': return Icons.local_hospital;
    case 'school': return Icons.school;
    case 'more_horiz': return Icons.more_horiz;
    case 'work': return Icons.work;
    case 'computer': return Icons.computer;
    case 'trending_up': return Icons.trending_up;
    case 'card_giftcard': return Icons.card_giftcard;
    case 'receipt': return Icons.receipt;
    default: return Icons.receipt;
  }
}
