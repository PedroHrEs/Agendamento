import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/dentist.dart';


class DentistJsonBinRepository {
  DentistJsonBinRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _binId = '6adaabfeffd5d16053843509';
  // Access Key fornecida para este bin do JSONBin.
  static const _accessKey = r'$2a$10$06WpFol4mbRCGTD7ilBEy.NgBDv7JsOarjJqwWUx1gdCvaT/o.dti';
  final http.Client _client;
  Uri get _uri => Uri.https('api.jsonbin.io', '/v3/b/$_binId');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Access-Key': _accessKey,
      };

  Future<List<DentistModel>> getAll() async {
    final response = await _client.get(_uri.replace(path: '${_uri.path}/latest'), headers: _headers);
    _check(response);
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    final record = root['record'] as Map<String, dynamic>? ?? root;
    final list = record['dentistas'] as List<dynamic>? ?? const [];
    return list.map((item) => DentistModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<void> create(DentistModel dentist) async {
    _validateDentist(dentist);
    final dentists = await getAll();
    if (dentists.any((item) => item.cro.toLowerCase() == dentist.cro.toLowerCase())) {
      throw Exception('Já existe um dentista com esse CRO.');
    }
    await _save([...dentists, dentist]);
  }

  Future<void> update(String originalCro, DentistModel dentist) async {
    _validateDentist(dentist);
    final dentists = await getAll();
    final index = dentists.indexWhere((item) => item.cro == originalCro);
    if (index < 0) throw Exception('Dentista não encontrado. Atualize a lista e tente novamente.');
    if (dentists.asMap().entries.any((entry) => entry.key != index &&
        entry.value.cro.toLowerCase() == dentist.cro.toLowerCase())) {
      throw Exception('Já existe um dentista com esse CRO.');
    }
    dentists[index] = dentist;
    await _save(dentists);
  }

  Future<void> delete(String cro) async {
    final dentists = await getAll();
    dentists.removeWhere((item) => item.cro == cro);
    await _save(dentists);
  }

  Future<void> _save(List<DentistModel> dentists) async {
    final response = await _client.put(_uri,
        headers: _headers, body: jsonEncode({'dentistas': dentists.map((item) => item.toJson()).toList()}));
    _check(response);
  }

  void _validateDentist(DentistModel dentist) {
    if (dentist.nome.trim().length < 5) {
      throw Exception('O nome deve ter pelo menos 5 caracteres.');
    }
    if (dentist.cro.trim().length < 5) {
      throw Exception('O CRO deve ter pelo menos 5 caracteres.');
    }
    if (dentist.especialidade.trim().length < 3) {
      throw Exception('A especialidade deve ter pelo menos 3 caracteres.');
    }
    final phone = dentist.telefone.trim();
    if (!RegExp(r'^[0-9 ()-]+$').hasMatch(phone)) {
      throw Exception('O telefone pode conter apenas números, espaços, parênteses e hífen.');
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^(\d{8,9}|\d{10,11})$').hasMatch(digits)) {
      throw Exception('Use telefone fixo/celular com 8 ou 9 dígitos, com DDD opcional.');
    }
    final uri = Uri.tryParse(dentist.img.trim());
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception('Informe uma URL de imagem válida (http ou https).');
    }
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha no JSONBin (HTTP ${response.statusCode}): ${response.body}');
    }
  }
}
