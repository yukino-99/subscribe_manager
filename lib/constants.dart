// lib/constants.dart

/// 支払い方法の選択肢
const List<String> paymentMethods = ['クレカ', '携帯合算', 'iTunes決済', 'その他'];

/// フィルター用（先頭に「全て」を付ける場合はこっちを使う）
const List<String> paymentMethodsForFilter = ['全て', ...paymentMethods];
