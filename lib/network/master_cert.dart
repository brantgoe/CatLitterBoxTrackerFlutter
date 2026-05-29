import 'dart:convert';
import 'dart:io';

import 'package:basic_utils/basic_utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A self-signed RSA cert + matching private key + the cert's SHA-256
/// fingerprint. Generated once per device, persisted to app-private storage.
class MasterCert {
  const MasterCert({
    required this.certPem,
    required this.keyPem,
    required this.fingerprintHex,
  });

  final String certPem;
  final String keyPem;

  /// Lowercase hex SHA-256 of the cert's DER encoding. Clients pin to this.
  final String fingerprintHex;
}

/// Ensure a master cert exists on disk, generating one on first call.
///
/// The cert is intentionally long-lived (10 years) — trust is established
/// via a fingerprint pin, not a CA chain, so cert rotation is unnecessary
/// until the user explicitly "forgets" the pin on every client.
Future<MasterCert> ensureMasterCert() async {
  final dir = await getApplicationDocumentsDirectory();
  final certFile = File('${dir.path}/master_cert.pem');
  final keyFile = File('${dir.path}/master_key.pem');

  if (await certFile.exists() && await keyFile.exists()) {
    try {
      final certPem = await certFile.readAsString();
      final keyPem = await keyFile.readAsString();
      return MasterCert(
        certPem: certPem,
        keyPem: keyPem,
        fingerprintHex: fingerprintOfCertPem(certPem),
      );
    } catch (e) {
      debugPrint('[MasterCert] reload failed, regenerating: $e');
    }
  }

  final pair = CryptoUtils.generateRSAKeyPair(keySize: 2048);
  final privateKey = pair.privateKey as RSAPrivateKey;
  final publicKey = pair.publicKey as RSAPublicKey;
  final dn = {'CN': 'Cat Litter Box Master'};
  final csrPem = X509Utils.generateRsaCsrPem(dn, privateKey, publicKey);
  final certPem = X509Utils.generateSelfSignedCertificate(
    privateKey,
    csrPem,
    3650, // ten years
  );
  final keyPem = CryptoUtils.encodeRSAPrivateKeyToPem(privateKey);

  await certFile.writeAsString(certPem, flush: true);
  await keyFile.writeAsString(keyPem, flush: true);

  return MasterCert(
    certPem: certPem,
    keyPem: keyPem,
    fingerprintHex: fingerprintOfCertPem(certPem),
  );
}

/// Lowercase hex SHA-256 of the cert encoded as DER. Identical algorithm
/// to `openssl x509 -fingerprint -sha256 -noout` minus the colons.
String fingerprintOfCertPem(String pem) {
  final body = pem
      .split('\n')
      .where((l) => !l.startsWith('-----') && l.isNotEmpty)
      .join();
  final der = base64Decode(body);
  return sha256.convert(der).bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}
