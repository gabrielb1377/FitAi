import 'package:fitai/core/auth/local_account_data_boundary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('arquiva dados legados por conta sem expor A para B', () async {
    final preferences = await SharedPreferences.getInstance();
    final boundary = LocalAccountDataBoundary();

    await preferences.setString('perfilPeso', '78 kg');
    await preferences.setStringList('historicoTreinos', ['workout-a']);
    await preferences.setInt('passos', 8500);
    await preferences.setString('fitia.settings.device.v1', 'device');

    await boundary.activate('user-a', claimUnownedData: true);
    await boundary.activate('user-b');

    expect(preferences.getString('perfilPeso'), isNull);
    expect(preferences.getStringList('historicoTreinos'), isNull);
    expect(preferences.getInt('passos'), isNull);
    expect(preferences.getString('fitia.settings.device.v1'), 'device');

    await preferences.setString('perfilPeso', '92 kg');
    await preferences.setInt('passos', 1200);
    await boundary.activate('user-a');

    expect(preferences.getString('perfilPeso'), '78 kg');
    expect(preferences.getStringList('historicoTreinos'), ['workout-a']);
    expect(preferences.getInt('passos'), 8500);

    await boundary.activate('user-b');
    expect(preferences.getString('perfilPeso'), '92 kg');
    expect(preferences.getInt('passos'), 1200);
  });

  test('login novo nao reivindica dados legados sem dono', () async {
    final preferences = await SharedPreferences.getInstance();
    final boundary = LocalAccountDataBoundary();
    await preferences.setString('perfilNome', 'Pessoa anterior');

    await boundary.activate('user-b');

    expect(preferences.getString('perfilNome'), isNull);
    expect(
      preferences.getString('fitia.localAccountBoundary.owner.v1'),
      'user-b',
    );
    expect(
      preferences.getString(
        'fitia.localAccountBoundary.archive.legacy-unowned.v1',
      ),
      isNotNull,
    );
  });
}
