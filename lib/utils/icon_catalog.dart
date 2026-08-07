import 'package:flutter/material.dart';

/// Icons are stored in the database by name (a stable String) so that the
/// database never depends on Flutter internals. This map turns a stored name
/// back into a drawable icon.
const Map<String, IconData> kIconsByName = {
  // Food & drink
  'restaurant': Icons.restaurant,
  'fastfood': Icons.fastfood,
  'local_cafe': Icons.local_cafe,
  'local_bar': Icons.local_bar,
  'local_pizza': Icons.local_pizza,
  'bakery_dining': Icons.bakery_dining,
  'icecream': Icons.icecream,
  'ramen_dining': Icons.ramen_dining,
  'rice_bowl': Icons.rice_bowl,
  'lunch_dining': Icons.lunch_dining,
  'egg': Icons.egg,
  'liquor': Icons.liquor,
  'wine_bar': Icons.wine_bar,
  'coffee': Icons.coffee,
  'cookie': Icons.cookie,
  'set_meal': Icons.set_meal,

  // Shopping
  'shopping_cart': Icons.shopping_cart,
  'shopping_bag': Icons.shopping_bag,
  'storefront': Icons.storefront,
  'local_mall': Icons.local_mall,
  'checkroom': Icons.checkroom,
  'diamond': Icons.diamond,
  'watch': Icons.watch,
  'redeem': Icons.redeem,
  'local_offer': Icons.local_offer,
  'sell': Icons.sell,

  // Transport
  'directions_bus': Icons.directions_bus,
  'directions_car': Icons.directions_car,
  'two_wheeler': Icons.two_wheeler,
  'local_taxi': Icons.local_taxi,
  'flight': Icons.flight,
  'train': Icons.train,
  'pedal_bike': Icons.pedal_bike,
  'local_gas_station': Icons.local_gas_station,
  'local_parking': Icons.local_parking,
  'directions_walk': Icons.directions_walk,

  // Home & bills
  'home': Icons.home,
  'chair': Icons.chair,
  'bed': Icons.bed,
  'kitchen': Icons.kitchen,
  'lightbulb': Icons.lightbulb,
  'water_drop': Icons.water_drop,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'phone_android': Icons.phone_android,
  'router': Icons.router,
  'cleaning_services': Icons.cleaning_services,
  'build': Icons.build,
  'handyman': Icons.handyman,

  // Health & personal
  'favorite': Icons.favorite,
  'monitor_heart': Icons.monitor_heart,
  'medical_services': Icons.medical_services,
  'medication': Icons.medication,
  'local_hospital': Icons.local_hospital,
  'content_cut': Icons.content_cut,
  'spa': Icons.spa,
  'fitness_center': Icons.fitness_center,
  'directions_run': Icons.directions_run,
  'sports_soccer': Icons.sports_soccer,
  'self_improvement': Icons.self_improvement,

  // Life & family
  'people': Icons.people,
  'person': Icons.person,
  'child_care': Icons.child_care,
  'pets': Icons.pets,
  'card_giftcard': Icons.card_giftcard,
  'volunteer_activism': Icons.volunteer_activism,
  'celebration': Icons.celebration,
  'cake': Icons.cake,
  'family_restroom': Icons.family_restroom,

  // Education & work
  'school': Icons.school,
  'menu_book': Icons.menu_book,
  'edit': Icons.edit,
  'work': Icons.work,
  'business_center': Icons.business_center,
  'computer': Icons.computer,
  'print': Icons.print,
  'science': Icons.science,

  // Entertainment
  'sports_esports': Icons.sports_esports,
  'movie': Icons.movie,
  'music_note': Icons.music_note,
  'headphones': Icons.headphones,
  'theaters': Icons.theaters,
  'tv': Icons.tv,
  'sports_bar': Icons.sports_bar,
  'casino': Icons.casino,
  'photo_camera': Icons.photo_camera,
  'send': Icons.send,

  // Money & finance
  'account_balance': Icons.account_balance,
  'account_balance_wallet': Icons.account_balance_wallet,
  'savings': Icons.savings,
  'payments': Icons.payments,
  'credit_card': Icons.credit_card,
  'trending_up': Icons.trending_up,
  'trending_down': Icons.trending_down,
  'attach_money': Icons.attach_money,
  'currency_exchange': Icons.currency_exchange,
  'receipt_long': Icons.receipt_long,
  'emoji_events': Icons.emoji_events,
  'paid': Icons.paid,
  'wallet': Icons.wallet,
  'monetization_on': Icons.monetization_on,

  // Misc
  'category': Icons.category,
  'star': Icons.star,
  'smoking_rooms': Icons.smoking_rooms,
  'local_florist': Icons.local_florist,
  'eco': Icons.eco,
  'devices_other': Icons.devices_other,
  'luggage': Icons.luggage,
  'beach_access': Icons.beach_access,
  'more_horiz': Icons.more_horiz,
};

IconData iconFor(String name) => kIconsByName[name] ?? Icons.category;

/// Grouped listing used by the icon picker UI.
const Map<String, List<String>> kIconGroups = {
  'Food & Drink': [
    'restaurant', 'fastfood', 'local_cafe', 'local_bar', 'local_pizza',
    'bakery_dining', 'icecream', 'ramen_dining', 'rice_bowl', 'lunch_dining',
    'egg', 'liquor', 'wine_bar', 'coffee', 'cookie', 'set_meal',
  ],
  'Shopping': [
    'shopping_cart', 'shopping_bag', 'storefront', 'local_mall', 'checkroom',
    'diamond', 'watch', 'redeem', 'local_offer', 'sell',
  ],
  'Transport': [
    'directions_bus', 'directions_car', 'two_wheeler', 'local_taxi', 'flight',
    'train', 'pedal_bike', 'local_gas_station', 'local_parking',
    'directions_walk',
  ],
  'Home & Bills': [
    'home', 'chair', 'bed', 'kitchen', 'lightbulb', 'water_drop', 'bolt',
    'wifi', 'phone_android', 'router', 'cleaning_services', 'build', 'handyman',
  ],
  'Health & Personal': [
    'favorite', 'monitor_heart', 'medical_services', 'medication',
    'local_hospital', 'content_cut', 'spa', 'fitness_center', 'directions_run',
    'sports_soccer', 'self_improvement',
  ],
  'Life & Family': [
    'people', 'person', 'child_care', 'pets', 'card_giftcard',
    'volunteer_activism', 'celebration', 'cake', 'family_restroom',
  ],
  'Education & Work': [
    'school', 'menu_book', 'edit', 'work', 'business_center', 'computer',
    'print', 'science',
  ],
  'Entertainment': [
    'sports_esports', 'movie', 'music_note', 'headphones', 'theaters', 'tv',
    'sports_bar', 'casino', 'photo_camera', 'send',
  ],
  'Money': [
    'account_balance', 'account_balance_wallet', 'savings', 'payments',
    'credit_card', 'trending_up', 'trending_down', 'attach_money',
    'currency_exchange', 'receipt_long', 'emoji_events', 'paid', 'wallet',
    'monetization_on',
  ],
  'Other': [
    'category', 'star', 'smoking_rooms', 'local_florist', 'eco',
    'devices_other', 'luggage', 'beach_access', 'more_horiz',
  ],
};
