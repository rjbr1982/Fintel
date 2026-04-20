// 🔒 STATUS: EDITED (Implemented Code-Based Map for English support & Unified L10n Logic)
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'he': {
      'app_title': 'Fintel',
      'appTitle': 'Fintel',
      'dashboard': 'דשבורד',
      'budget_title': 'תקציב',
      'debts_title': 'מנמיכות',
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

      // Legal & Auth
      'login_with_google': 'התחברות באמצעות Google',
      'legal_terms': 'תנאי שימוש ופרטיות',
      'accept_terms_link': 'אני מאשר את תנאי השימוש',
      'must_accept_terms': 'יש לאשר את תנאי השימוש כדי להמשיך',
      'close': 'סגור',
      'terms_full_text': 'כתב ויתור והצהרת פרטיות:\nהמערכת אינה מהווה ייעוץ פיננסי מקצועי ואינה תחליף לייעוץ. הנתונים מוצגים AS IS והאחריות על כל החלטה כלכלית חלה על המשתמש בלבד.',
    },
    'en': {
      'app_title': 'Fintel',
      'appTitle': 'Fintel',
      'dashboard': 'Dashboard',
      'budget_title': 'Budget',
      'debts_title': 'Reducing (Debts)',
      'shopping_list': 'Shopping List',
      'loading': 'Loading data...',
      'currency_symbol': '₪',
      'cancel': 'Cancel',
      'save': 'Save',
      'add': 'Add',
      'delete': 'Delete',
      
      // P&L
      'pnl': 'P&L Statement',
      'income': 'Income',
      'fixed_expenses': 'Fixed Expenses',
      'variable_expenses': 'Variable Expenses',
      'future_expenses': 'Future Expenses',
      'financial_expenses': 'Financial Expenses',
      'reducing_expenses': 'Reducing Expenses (Debts)',
      'pcf': 'Free Cash Flow (PCF)',
      
      // Assets
      'assets_portfolio': 'Assets Portfolio',
      'no_assets': 'No assets currently',
      'add_asset': 'Add New Asset',
      'asset_name': 'Asset Name',
      'asset_value': 'Current Value',
      'net_worth': 'Net Worth',
      'passive_income': 'Passive Income',
      
      // Freedom
      'years_to_freedom': 'Years to Freedom',
      'freedom_year': 'Freedom Year',
      'timeline_title': 'Freedom Timeline',
      'infinite': 'Infinite',
      'years': 'Years',
      'potential_mode': 'Potential Scenario',

      // Legal & Auth
      'login_with_google': 'Sign in with Google',
      'legal_terms': 'Terms of Use & Privacy',
      'accept_terms_link': 'I accept the terms of use',
      'must_accept_terms': 'You must accept the terms to continue',
      'close': 'Close',
      'terms_full_text': 'Legal Disclaimer:\nThis system does not constitute professional financial advice and is not a substitute for consulting. Data is provided AS IS and the user bears sole responsibility for any financial decisions.',
    },
  };

  /// מתודת התרגום הדינמית (תומכת באנגלית ובעברית בהתאם לשפת המכשיר)
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? _localizedValues['he']?[key] ?? key;
  }

  /// תאימות לאחור - מעטפת עבור מסכים ישנים שמשתמשים ב-get במקום ב-translate
  String get(String key) => translate(key);
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