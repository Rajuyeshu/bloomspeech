import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/constants/app_constants.dart';

/// Global language provider
final appLanguageProvider = StateProvider<AppLanguage>((ref) => AppLanguage.english);
