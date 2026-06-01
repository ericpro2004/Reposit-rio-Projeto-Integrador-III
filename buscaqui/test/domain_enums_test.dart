import 'package:buscaqui/features/attendance/domain/entities/presenca.dart';
import 'package:buscaqui/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('fromString mapeia valores conhecidos', () {
      expect(UserRole.fromString('motorista'), UserRole.motorista);
      expect(UserRole.fromString('responsavel'), UserRole.responsavel);
      expect(UserRole.fromString('passageiro'), UserRole.passageiro);
    });

    test('fromString usa passageiro como fallback', () {
      expect(UserRole.fromString('desconhecido'), UserRole.passageiro);
    });

    test('label é legível', () {
      expect(UserRole.motorista.label, 'Motorista');
    });
  });

  group('PresencaStatus / PresencaOrigem', () {
    test('status fromString e fallback', () {
      expect(PresencaStatus.fromString('presente'), PresencaStatus.presente);
      expect(PresencaStatus.fromString('justificado'),
          PresencaStatus.justificado);
      expect(PresencaStatus.fromString('xpto'), PresencaStatus.ausente);
    });

    test('origem labels', () {
      expect(PresencaOrigem.qrcode.label, 'QR Code');
      expect(PresencaOrigem.codigo.label, 'Código');
      expect(PresencaOrigem.manual.label, 'Manual');
    });
  });
}
