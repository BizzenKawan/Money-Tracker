import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class DBHelper {
  DBHelper._();
  static final DBHelper instance = DBHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'money_tracker.db'),
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2 added the settings table. Existing installs are upgraded in
        // place so no reinstall (and no data loss) is needed.
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            iconName TEXT NOT NULL,
            colorValue INTEGER NOT NULL,
            openingBalance REAL NOT NULL DEFAULT 0,
            sortOrder INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            iconName TEXT NOT NULL,
            colorValue INTEGER NOT NULL,
            sortOrder INTEGER NOT NULL DEFAULT 0,
            isCustom INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            categoryId INTEGER,
            accountId INTEGER,
            toAccountId INTEGER,
            note TEXT,
            adDate TEXT NOT NULL,
            bsYear INTEGER NOT NULL,
            bsMonth INTEGER NOT NULL,
            bsDay INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bsYear INTEGER NOT NULL,
            bsMonth INTEGER NOT NULL,
            amount REAL NOT NULL,
            UNIQUE(bsYear, bsMonth)
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_tx_month ON transactions(bsYear, bsMonth)',
        );

        await _seed(db);
      },
    );
  }

  Future<void> _seed(Database db) async {
    const expenses = [
      ('Food', 'restaurant', 0xFF2ECC9B),
      ('Transportation', 'directions_bus', 0xFFD9938C),
      ('Shopping', 'shopping_cart', 0xFFE8B93C),
      ('Phone', 'phone_android', 0xFFF25CA2),
      ('Entertainment', 'sports_esports', 0xFF3FBF4F),
      ('Education', 'school', 0xFFF57C1F),
      ('Beauty', 'content_cut', 0xFFF2555A),
      ('Sports', 'directions_run', 0xFFB57BE8),
      ('Social', 'people', 0xFF3FA9F5),
      ('Clothing', 'checkroom', 0xFF8CC63F),
      ('Car', 'directions_car', 0xFF3FC1C9),
      ('Health', 'monitor_heart', 0xFFF2555A),
      ('Housing', 'home', 0xFFE8615F),
      ('Electronics', 'computer', 0xFF3B6FE0),
      ('Travel', 'flight', 0xFF3FC1C9),
      ('Pets', 'pets', 0xFFF7B267),
      ('Repairs', 'build', 0xFF9A9A9A),
      ('Credit', 'credit_card', 0xFF3FC1C9),
      ('Gifts', 'card_giftcard', 0xFFF25CA2),
      ('Donations', 'volunteer_activism', 0xFF8B7BE8),
      ('Snacks', 'cookie', 0xFFE8B93C),
      ('Vegetables', 'eco', 0xFF3FBF4F),
      ('Fruits', 'local_florist', 0xFFF2555A),
      ('Utilities', 'bolt', 0xFFD4C13A),
      ('Others', 'more_horiz', 0xFF9A9A9A),
    ];

    const incomes = [
      ('Salary', 'work', 0xFFE8B93C),
      ('Investments', 'trending_up', 0xFFF25CA2),
      ('Part-Time', 'payments', 0xFF2ECC9B),
      ('Bonus', 'emoji_events', 0xFF3FBF4F),
      ('Business', 'storefront', 0xFF3FA9F5),
      ('Gifts', 'card_giftcard', 0xFFB57BE8),
      ('Others', 'monetization_on', 0xFFF57C1F),
    ];

    var order = 0;
    for (final (name, icon, color) in expenses) {
      await db.insert('categories', {
        'name': name,
        'type': 'expense',
        'iconName': icon,
        'colorValue': color,
        'sortOrder': order++,
        'isCustom': 0,
      });
    }

    order = 0;
    for (final (name, icon, color) in incomes) {
      await db.insert('categories', {
        'name': name,
        'type': 'income',
        'iconName': icon,
        'colorValue': color,
        'sortOrder': order++,
        'isCustom': 0,
      });
    }

    await db.insert('accounts', {
      'name': 'Cash',
      'iconName': 'wallet',
      'colorValue': 0xFFE8B93C,
      'openingBalance': 0.0,
      'sortOrder': 0,
    });
  }

  // ---------------------------------------------------------------- accounts

  Future<List<Account>> getAccounts() async {
    final db = await database;
    final rows = await db.query('accounts', orderBy: 'sortOrder ASC, id ASC');
    return rows.map(Account.fromMap).toList();
  }

  Future<int> insertAccount(Account a) async {
    final db = await database;
    return db.insert('accounts', a.toMap()..remove('id'));
  }

  Future<void> updateAccount(Account a) async {
    final db = await database;
    await db.update('accounts', a.toMap(), where: 'id = ?', whereArgs: [a.id]);
  }

  /// Deleting an account leaves its transactions in place but detaches them,
  /// so history and totals are never silently lost.
  Future<void> deleteAccount(int id) async {
    final db = await database;
    await db.update('transactions', {'accountId': null},
        where: 'accountId = ?', whereArgs: [id]);
    await db.update('transactions', {'toAccountId': null},
        where: 'toAccountId = ?', whereArgs: [id]);
    await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderAccounts(List<Account> ordered) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update('accounts', {'sortOrder': i},
          where: 'id = ?', whereArgs: [ordered[i].id]);
    }
    await batch.commit(noResult: true);
  }

  /// opening balance + income - expense + transfers in - transfers out
  Future<double> accountBalance(int accountId) async {
    final db = await database;

    Future<double> sum(String sql, List<Object?> args) async {
      final r = await db.rawQuery(sql, args);
      return (r.first.values.first as num?)?.toDouble() ?? 0;
    }

    final opening = await sum(
      'SELECT openingBalance FROM accounts WHERE id = ?',
      [accountId],
    );
    final income = await sum(
      "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='income' AND accountId = ?",
      [accountId],
    );
    final expense = await sum(
      "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='expense' AND accountId = ?",
      [accountId],
    );
    final inbound = await sum(
      "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='transfer' AND toAccountId = ?",
      [accountId],
    );
    final outbound = await sum(
      "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='transfer' AND accountId = ?",
      [accountId],
    );

    return opening + income - expense + inbound - outbound;
  }

  // -------------------------------------------------------------- categories

  Future<List<Category>> getCategories(String type) async {
    final db = await database;
    final rows = await db.query(
      'categories',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'sortOrder ASC, id ASC',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<Map<int, Category>> getCategoryLookup() async {
    final db = await database;
    final rows = await db.query('categories');
    final list = rows.map(Category.fromMap);
    return {for (final c in list) c.id!: c};
  }

  Future<int> insertCategory(Category c) async {
    final db = await database;
    final maxOrder = Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COALESCE(MAX(sortOrder), -1) FROM categories WHERE type = ?',
          [c.type],
        )) ??
        -1;
    return db.insert(
      'categories',
      c.copyWith(sortOrder: maxOrder + 1).toMap()..remove('id'),
    );
  }

  Future<void> updateCategory(Category c) async {
    final db = await database;
    await db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  /// Returns how many transactions still reference this category.
  Future<int> categoryUsageCount(int categoryId) async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery(
          'SELECT COUNT(*) FROM transactions WHERE categoryId = ?',
          [categoryId],
        )) ??
        0;
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> reorderCategories(List<Category> ordered) async {
    final db = await database;
    final batch = db.batch();
    for (var i = 0; i < ordered.length; i++) {
      batch.update('categories', {'sortOrder': i},
          where: 'id = ?', whereArgs: [ordered[i].id]);
    }
    await batch.commit(noResult: true);
  }

  // ------------------------------------------------------------ transactions

  Future<int> insertTransaction(MoneyTransaction t) async {
    final db = await database;
    return db.insert('transactions', t.toMap()..remove('id'));
  }

  Future<void> updateTransaction(MoneyTransaction t) async {
    final db = await database;
    await db.update('transactions', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MoneyTransaction>> transactionsForMonth(
    int bsYear,
    int bsMonth,
  ) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'bsYear = ? AND bsMonth = ?',
      whereArgs: [bsYear, bsMonth],
      orderBy: 'bsDay DESC, id DESC',
    );
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  Future<List<MoneyTransaction>> searchTransactions(String term) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT t.* FROM transactions t
      LEFT JOIN categories c ON c.id = t.categoryId
      WHERE t.note LIKE ? OR c.name LIKE ?
      ORDER BY t.adDate DESC, t.id DESC
      LIMIT 300
    ''', ['%$term%', '%$term%']);
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  /// Every transaction in one category for one BS month, oldest day first.
  Future<List<MoneyTransaction>> transactionsForCategoryMonth(
    int bsYear,
    int bsMonth,
    int categoryId,
  ) async {
    final db = await database;
    final rows = await db.query(
      'transactions',
      where: 'bsYear = ? AND bsMonth = ? AND categoryId = ?',
      whereArgs: [bsYear, bsMonth, categoryId],
      orderBy: 'bsDay ASC, id ASC',
    );
    return rows.map(MoneyTransaction.fromMap).toList();
  }

  /// Totals for a month: (expense, income). Transfers are deliberately
  /// excluded — moving your own money is not spending or earning.
  Future<({double expense, double income})> monthTotals(
    int bsYear,
    int bsMonth,
  ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT type, COALESCE(SUM(amount), 0) AS total
      FROM transactions
      WHERE bsYear = ? AND bsMonth = ? AND type IN ('expense','income')
      GROUP BY type
    ''', [bsYear, bsMonth]);

    double expense = 0, income = 0;
    for (final r in rows) {
      final total = (r['total'] as num).toDouble();
      if (r['type'] == 'expense') expense = total;
      if (r['type'] == 'income') income = total;
    }
    return (expense: expense, income: income);
  }

  /// Per-category totals for one month, largest first.
  Future<List<({Category category, double total})>> categoryBreakdown(
    int bsYear,
    int bsMonth,
    String type,
  ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.*, SUM(t.amount) AS total
      FROM transactions t
      JOIN categories c ON c.id = t.categoryId
      WHERE t.bsYear = ? AND t.bsMonth = ? AND t.type = ?
      GROUP BY c.id
      ORDER BY total DESC
    ''', [bsYear, bsMonth, type]);

    return rows
        .map((r) => (
              category: Category.fromMap(r),
              total: (r['total'] as num).toDouble(),
            ))
        .toList();
  }

  /// Per-day expense/income totals for one BS month, keyed by BS day.
  /// Used by the calendar grid.
  Future<Map<int, ({double expense, double income})>> dailyTotals(
    int bsYear,
    int bsMonth,
  ) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT bsDay, type, SUM(amount) AS total
      FROM transactions
      WHERE bsYear = ? AND bsMonth = ? AND type IN ('expense','income')
      GROUP BY bsDay, type
    ''', [bsYear, bsMonth]);

    final result = <int, ({double expense, double income})>{};
    for (final r in rows) {
      final day = r['bsDay'] as int;
      final total = (r['total'] as num).toDouble();
      final current = result[day] ?? (expense: 0.0, income: 0.0);
      result[day] = r['type'] == 'expense'
          ? (expense: current.expense + total, income: current.income)
          : (expense: current.expense, income: current.income + total);
    }
    return result;
  }

  /// Every BS month that has activity, newest first. Optionally limited to a
  /// single account.
  Future<List<({int year, int month, double expense, double income})>>
      monthlyHistory({int? accountId}) async {
    final db = await database;
    final accountFilter = accountId == null ? '' : 'AND accountId = ?';
    final args = <Object?>[if (accountId != null) accountId];

    final rows = await db.rawQuery('''
      SELECT bsYear, bsMonth, type, SUM(amount) AS total
      FROM transactions
      WHERE type IN ('expense','income') $accountFilter
      GROUP BY bsYear, bsMonth, type
      ORDER BY bsYear DESC, bsMonth DESC
    ''', args);

    final map = <String, ({int year, int month, double expense, double income})>{};
    for (final r in rows) {
      final y = r['bsYear'] as int;
      final m = r['bsMonth'] as int;
      final total = (r['total'] as num).toDouble();
      final key = '$y-$m';
      final current =
          map[key] ?? (year: y, month: m, expense: 0.0, income: 0.0);
      map[key] = r['type'] == 'expense'
          ? (
              year: y,
              month: m,
              expense: current.expense + total,
              income: current.income
            )
          : (
              year: y,
              month: m,
              expense: current.expense,
              income: current.income + total
            );
    }

    final list = map.values.toList();
    list.sort((a, b) {
      final byYear = b.year.compareTo(a.year);
      return byYear != 0 ? byYear : b.month.compareTo(a.month);
    });
    return list;
  }

  /// Net worth across every account, including money not tied to an account.
  Future<double> totalBalance() async {
    final db = await database;

    Future<double> sum(String sql) async {
      final r = await db.rawQuery(sql);
      return (r.first.values.first as num?)?.toDouble() ?? 0;
    }

    final opening =
        await sum('SELECT COALESCE(SUM(openingBalance),0) FROM accounts');
    final income = await sum(
        "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='income'");
    final expense = await sum(
        "SELECT COALESCE(SUM(amount),0) FROM transactions WHERE type='expense'");

    // Transfers move money between accounts, so they cancel out overall.
    return opening + income - expense;
  }

  /// Lifetime expense/income totals, optionally for one account.
  Future<({double expense, double income})> lifetimeTotals({
    int? accountId,
  }) async {
    final db = await database;
    final filter = accountId == null ? '' : 'AND accountId = ?';
    final args = <Object?>[if (accountId != null) accountId];

    final rows = await db.rawQuery('''
      SELECT type, COALESCE(SUM(amount),0) AS total
      FROM transactions
      WHERE type IN ('expense','income') $filter
      GROUP BY type
    ''', args);

    double expense = 0, income = 0;
    for (final r in rows) {
      final total = (r['total'] as num).toDouble();
      if (r['type'] == 'expense') expense = total;
      if (r['type'] == 'income') income = total;
    }
    return (expense: expense, income: income);
  }

  // ---------------------------------------------------------------- settings

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows =
        await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final raw = await getSetting(key);
    if (raw == null) return fallback;
    return raw == '1';
  }

  Future<void> setBool(String key, bool value) =>
      setSetting(key, value ? '1' : '0');

  // ----------------------------------------------------------------- budgets

  Future<double?> getBudget(int bsYear, int bsMonth) async {
    final db = await database;
    final rows = await db.query(
      'budgets',
      where: 'bsYear = ? AND bsMonth = ?',
      whereArgs: [bsYear, bsMonth],
    );
    if (rows.isEmpty) return null;
    return (rows.first['amount'] as num).toDouble();
  }

  Future<void> setBudget(int bsYear, int bsMonth, double amount) async {
    final db = await database;
    await db.insert(
      'budgets',
      {'bsYear': bsYear, 'bsMonth': bsMonth, 'amount': amount},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearBudget(int bsYear, int bsMonth) async {
    final db = await database;
    await db.delete('budgets',
        where: 'bsYear = ? AND bsMonth = ?', whereArgs: [bsYear, bsMonth]);
  }

  // ------------------------------------------------------------------- admin

  Future<void> eraseAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('budgets');
  }
}
