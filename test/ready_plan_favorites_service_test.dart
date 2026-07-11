import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitai/services/ready_plan_favorites_service.dart';

void main() {
  test('favoritos persistem localmente e não duplicam IDs', () async {
    SharedPreferences.setMockInitialValues({});
    final service = ReadyPlanFavoritesService.forTesting();

    await service.addFavorite('plan-1');
    await service.addFavorite('plan-1');
    expect(service.favoriteIds, {'plan-1'});

    final restored = ReadyPlanFavoritesService.forTesting();
    expect(await restored.loadFavoriteIds(), {'plan-1'});

    await restored.removeFavorite('plan-1');
    expect(restored.isFavorite('plan-1'), isFalse);
  });
}
