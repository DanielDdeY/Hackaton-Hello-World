import 'package:flutter_test/flutter_test.dart';
import 'package:hackaton_hello_world/features/create_post/domain/entities/emergency_post_data.dart';

void main() {
  test('emergency report requires an address', () {
    expect(
      const EmergencyPostData(streetAddress: 'Av. Central').isValid,
      isTrue,
    );
    expect(const EmergencyPostData(streetAddress: '').isValid, isFalse);
  });

  test('supports all planned emergency categories', () {
    expect(EmergencyType.values, hasLength(8));
    expect(EmergencyType.values, contains(EmergencyType.missingPerson));
    expect(EmergencyType.values, contains(EmergencyType.other));
  });
}
