import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'he': {
      'appTitle': 'Fintel',
      'dashboard': 'דשבורד',
      'budget_title': 'תקציב',
      'debts_title': 'ניהול חובות',
      'shopping_list': 'רשימת קניות',
      'loading': 'טוען נתונים...',
      'currency_symbol': '₪',
      'cancel': 'ביטול',
      'save': 'שמור',
      'add': 'הוסף',
      'delete': 'מחק',
      
      // P&L
      'pnl': 'דו"ח תזרים (P&L)',
      'income': 'הכנסות',
      'fixed_expenses': 'הוצאות קבועות',
      'variable_expenses': 'הוצאות משתנות',
      'future_expenses': 'הוצאות עתידיות',
      'financial_expenses': 'הוצאות פיננסיות',
      'reducing_expenses': 'הוצאות מנמיכות (חובות)',
      'pcf': 'תזרים פנוי (PCF)',
      
      // Assets
      'assets_portfolio': 'תיק נכסים',
      'no_assets': 'אין נכסים כרגע',
      'add_asset': 'הוסף נכס חדש',
      'asset_name': 'שם הנכס',
      'asset_value': 'שווי נוכחי',
      'net_worth': 'שווי נקי',
      'passive_income': 'הכנסה פסיבית',
      
      // Freedom
      'years_to_freedom': 'שנים לחירות',
      'freedom_year': 'שנת החירות',
      'timeline_title': 'ציר הזמן לחירות',
      'infinite': 'אינסוף',
      'years': 'שנים',
      'potential_mode': 'תרחיש פוטנציאל',
    },
    'en': {
      'appTitle': 'Fintel',
      // ... English implementation (skipped for brevity, defaulting to Hebrew)
    },
  };

  String get(String key) {
    return _localizedValues['he']?[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'he'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}