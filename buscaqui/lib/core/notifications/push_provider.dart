import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/supabase_config.dart';
import 'push_service.dart';

final pushServiceProvider = Provider<PushService>(
  (ref) => PushService(SupabaseConfig.client),
);
