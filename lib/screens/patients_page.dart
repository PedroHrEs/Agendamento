import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/patient.dart';
import '../services/patient_repository.dart';
import '../utils/date_formatter.dart';
import '../utils/phone_formatter.dart';

class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key, this.openRegistration = false});

  final bool openRegistration;

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  static const _primary = Color(0xFF007A78);
  final _repository = PatientRepository();
  late final Stream<List<PatientModel>> _patients;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _patients = _repository.streamMyPatients();
    if (widget.openRegistration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openForm();
      });
    }
  }

  Future<void> _openForm([PatientModel? patient]) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: patient?.name ?? '');
    final cpf = TextEditingController(text: patient?.cpf ?? '');
    final phone = TextEditingController(
      text: formatBrazilianPhone(patient?.phone ?? ''),
    );
    final email = TextEditingController(text: patient?.email ?? '');
    final birthDate = TextEditingController(text: patient?.birthDate ?? '');
    final address = TextEditingController(text: patient?.address ?? '');
    final notes = TextEditingController(text: patient?.notes ?? '');
    var saving = false;

    final dialogRoute = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(patient == null ? 'Cadastrar paciente' : 'Alterar paciente'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(name, 'Nome completo', Icons.person_outline),
                const SizedBox(height: 12),
                _field(
                  cpf,
                  'CPF',
                  Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validateCpf,
                ),
                const SizedBox(height: 12),
                _field(
                  phone,
                  'Telefone',
                  Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: const [BrazilianPhoneInputFormatter()],
                ),
                const SizedBox(height: 12),
                _field(
                  email,
                  'E-mail',
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 12),
                _field(
                  birthDate,
                  'Data de nascimento',
                  Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: const [BrazilianDateInputFormatter()],
                  validator: _validateBirthDate,
                ),
                const SizedBox(height: 12),
                _field(address, 'Endereço', Icons.location_on_outlined),
                const SizedBox(height: 12),
                _field(notes, 'Observações', Icons.notes_outlined, maxLines: 3),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        if (patient == null) {
                          await _repository.create(
                            name: name.text, cpf: cpf.text, phone: phone.text,
                            email: email.text, birthDate: birthDate.text,
                            address: address.text, notes: notes.text,
                          );
                        } else {
                          await _repository.update(patient.copyWith(
                            name: name.text, cpf: cpf.text, phone: phone.text,
                            email: email.text, birthDate: birthDate.text,
                            address: address.text, notes: notes.text,
                          ));
                        }
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _message('Paciente salvo com sucesso.');
                      } catch (error) {
                        if (!mounted) return;
                        setDialogState(() => saving = false);
                        _message(error.toString().replaceFirst('Exception: ', ''));
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(dialogRoute);
    await dialogRoute.completed;
    name.dispose(); cpf.dispose(); phone.dispose(); email.dispose();
    birthDate.dispose(); address.dispose(); notes.dispose();
  }

  TextFormField _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        readOnly: readOnly,
        onTap: onTap,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe o e-mail.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  String? _validateCpf(String? value) {
    final cpf = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) {
      return 'Informe um CPF válido.';
    }
    final firstDigit = _cpfDigit(cpf.substring(0, 9));
    final secondDigit = _cpfDigit(cpf.substring(0, 9) + firstDigit.toString());
    return cpf == '${cpf.substring(0, 9)}$firstDigit$secondDigit'
        ? null
        : 'Informe um CPF válido.';
  }

  int _cpfDigit(String digits) {
    var sum = 0;
    for (var index = 0; index < digits.length; index++) {
      sum += int.parse(digits[index]) * (digits.length + 1 - index);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  String? _validateBirthDate(String? value) {
    if (_parseBirthDate(value ?? '') == null) {
      return 'Selecione uma data de nascimento válida.';
    }
    return null;
  }

  DateTime? _parseBirthDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    final today = DateTime.now();
    if (date.year != year || date.month != month || date.day != day || date.isAfter(DateTime(today.year, today.month, today.day))) {
      return null;
    }
    return date;
  }

  Future<void> _delete(PatientModel patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir paciente?'),
        content: Text('O cadastro de ${patient.name} será removido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(patient);
      if (mounted) _message('Paciente excluído.');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Pacientes')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm, backgroundColor: _primary, foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1), label: const Text('Cadastrar'),
        ),
        body: StreamBuilder<List<PatientModel>>(
          stream: _patients,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final patients = snapshot.data!;
            if (patients.isEmpty) return const Center(child: Text('Nenhum paciente cadastrado.'));
            final query = _normalizeForSearch(_searchQuery);
            final numericQuery = query.replaceAll(RegExp(r'\D'), '');
            final filteredPatients = patients.where((patient) {
              final matchesText = _normalizeForSearch(patient.name).contains(query) ||
                  _normalizeForSearch(patient.email).contains(query) ||
                  _normalizeForSearch(patient.address).contains(query);
              final matchesNumber = numericQuery.isNotEmpty &&
                  (patient.cpf.replaceAll(RegExp(r'\D'), '').contains(numericQuery) ||
                      patient.phone
                          .replaceAll(RegExp(r'\D'), '')
                          .contains(numericQuery));

              return matchesText || matchesNumber;
            }).toList();
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar paciente',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: filteredPatients.isEmpty
                    ? const Center(child: Text('Nenhum paciente encontrado.'))
                    : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: filteredPatients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final patient = filteredPatients[index];
                return Card(child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFFE3F3F1), foregroundColor: _primary, child: Icon(Icons.person_outline)),
                  title: Text(patient.name),
                  subtitle: Text(
                    'CPF: ${patient.cpf}\n${formatBrazilianPhone(patient.phone)}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) => action == 'edit' ? _openForm(patient) : _delete(patient),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Alterar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ));
              },
            ),
              ),
            ]);
          },
        ),
      );

  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _normalizeForSearch(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll('ç', 'c');
}
