import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/consultation.dart';
import '../models/patient.dart';
import '../services/consultation_repository.dart';
import '../services/patient_repository.dart';
import '../utils/date_formatter.dart';

class ConsultationsPage extends StatefulWidget {
  const ConsultationsPage({super.key});

  @override
  State<ConsultationsPage> createState() => _ConsultationsPageState();
}

class _ConsultationsPageState extends State<ConsultationsPage> {
  static const _primary = Color(0xFF007A78);
  final _repository = ConsultationRepository();
  final _patientRepository = PatientRepository();
  late final Stream<List<ConsultationModel>> _consultations;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _consultations = _repository.streamMyConsultations();
  }

  Future<void> _openForm([ConsultationModel? consultation]) async {
    List<PatientModel> patients;
    try {
      patients = await _patientRepository.streamMyPatients().first;
    } catch (error) {
      if (mounted) _message('Não foi possível carregar os pacientes: $error');
      return;
    }
    if (!mounted) return;
    if (patients.isEmpty) {
      _message('Cadastre um paciente antes de registrar uma consulta.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final description = TextEditingController(text: consultation?.description ?? '');
    final imageUrl = TextEditingController(text: consultation?.imageUrl ?? '');
    final date = TextEditingController(
      text: consultation == null ? '' : _formatDate(consultation.dateTime),
    );
    final time = TextEditingController(
      text: consultation == null ? '' : _formatTime(consultation.dateTime),
    );
    final totalValue = TextEditingController(
      text: consultation == null ? '' : _formatEditableValue(consultation.totalValue),
    );
    var selectedPatientId = patients.any((patient) => patient.id == consultation?.patientId)
        ? consultation?.patientId
        : null;
    var saving = false;

    final dialogRoute = DialogRoute<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(consultation == null ? 'Cadastrar consulta' : 'Alterar consulta'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedPatientId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Paciente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: patients
                          .map((patient) => DropdownMenuItem(
                                value: patient.id,
                                child: Text(patient.name, overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() => selectedPatientId = value),
                      validator: (value) => value == null ? 'Selecione o paciente.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: date,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [BrazilianDateInputFormatter()],
                      validator: (value) => _parseDate(value ?? '') == null
                          ? 'Use o formato dd/mm/aaaa.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Data',
                        hintText: 'dd/mm/aaaa',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: time,
                      keyboardType: TextInputType.datetime,
                      inputFormatters: const [_TimeInputFormatter()],
                      validator: (value) => _parseTime(value ?? '') == null
                          ? 'Use o formato HH:mm.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Horário',
                        hintText: 'HH:mm',
                        prefixIcon: Icon(Icons.access_time_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 4,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Descreva o que foi realizado.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Descrição do procedimento',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: totalValue,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
                      validator: (value) => _parseValue(value ?? '') == null
                          ? 'Informe um valor válido.'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Valor total (R\$)',
                        prefixIcon: Icon(Icons.attach_money_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: imageUrl,
                      keyboardType: TextInputType.url,
                      onChanged: (_) => setDialogState(() {}),
                      validator: _validateImageUrl,
                      decoration: const InputDecoration(
                        labelText: 'URL da imagem (opcional)',
                        prefixIcon: Icon(Icons.image_outlined),
                      ),
                    ),
                    if (imageUrl.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _ImagePreview(imageUrl: imageUrl.text.trim()),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final selectedPatient = patients.firstWhere(
                        (patient) => patient.id == selectedPatientId,
                      );
                      final value = _parseValue(totalValue.text)!;
                      final consultationDateTime = _combineDateAndTime(date.text, time.text)!;
                      setDialogState(() => saving = true);
                      try {
                        if (consultation == null) {
                          await _repository.create(
                            patientId: selectedPatient.id,
                            patientName: selectedPatient.name,
                            dateTime: consultationDateTime,
                            imageUrl: imageUrl.text,
                            description: description.text,
                            totalValue: value,
                          );
                        } else {
                          await _repository.update(consultation.copyWith(
                            patientId: selectedPatient.id,
                            patientName: selectedPatient.name,
                            dateTime: consultationDateTime,
                            imageUrl: imageUrl.text,
                            description: description.text,
                            totalValue: value,
                          ));
                        }
                        if (!mounted) return;
                        Navigator.pop(dialogContext);
                        _message('Consulta salva com sucesso.');
                      } catch (error) {
                        if (!mounted) return;
                        setDialogState(() => saving = false);
                        _message(error.toString().replaceFirst('Exception: ', ''));
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    await Navigator.of(context, rootNavigator: true).push(dialogRoute);
    description.dispose();
    imageUrl.dispose();
    date.dispose();
    time.dispose();
    totalValue.dispose();
  }

  Future<void> _delete(ConsultationModel consultation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir consulta?'),
        content: Text('A consulta de ${consultation.patientName} será removida.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(consultation);
      if (mounted) _message('Consulta excluída.');
    } catch (error) {
      if (mounted) _message(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Consultas')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openForm,
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Cadastrar'),
        ),
        body: StreamBuilder<List<ConsultationModel>>(
          stream: _consultations,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final query = _searchQuery.trim().toLowerCase();
            final consultations = snapshot.data!
                .where((consultation) => consultation.patientName.toLowerCase().contains(query) ||
                    consultation.description.toLowerCase().contains(query))
                .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: const InputDecoration(
                      labelText: 'Pesquisar consulta',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                Expanded(
                  child: consultations.isEmpty
                      ? Center(
                          child: Text(snapshot.data!.isEmpty
                              ? 'Nenhuma consulta cadastrada.'
                              : 'Nenhuma consulta encontrada.'),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          itemCount: consultations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final consultation = consultations[index];
                            return Card(
                              child: ListTile(
                                leading: consultation.imageUrl.trim().isEmpty
                                    ? const CircleAvatar(
                                        backgroundColor: Color(0xFFE3F3F1),
                                        foregroundColor: _primary,
                                        child: Icon(Icons.medical_services_outlined),
                                      )
                                    : ClipOval(
                                        child: Image.network(
                                          _imageSource(consultation.imageUrl),
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const CircleAvatar(
                                            backgroundColor: Color(0xFFE3F3F1),
                                            foregroundColor: _primary,
                                            child: Icon(Icons.broken_image_outlined),
                                          ),
                                        ),
                                      ),
                                title: Text(consultation.patientName),
                                subtitle: Text(
                                  '${_formatDateTime(consultation.dateTime)}\n'
                                  '${consultation.description}\n'
                                  'Total: ${_formatCurrency(consultation.totalValue)}',
                                ),
                                isThreeLine: true,
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) => action == 'edit'
                                      ? _openForm(consultation)
                                      : _delete(consultation),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(value: 'edit', child: Text('Alterar')),
                                    PopupMenuItem(value: 'delete', child: Text('Excluir')),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      );

  String? _validateImageUrl(String? value) {
    final url = value?.trim() ?? '';
    if (url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && uri.hasAuthority
        ? null
        : 'Informe uma URL válida.';
  }

  double? _parseValue(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;
    final lastComma = raw.lastIndexOf(',');
    final lastDot = raw.lastIndexOf('.');
    final decimalIndex = lastComma > lastDot ? lastComma : lastDot;
    final normalized = decimalIndex == -1
        ? raw.replaceAll(RegExp(r'[^0-9]'), '')
        : '${raw.substring(0, decimalIndex).replaceAll(RegExp(r'[^0-9]'), '')}.'
            '${raw.substring(decimalIndex + 1).replaceAll(RegExp(r'[^0-9]'), '')}';
    final parsed = double.tryParse(normalized);
    return parsed != null && parsed >= 0 ? parsed : null;
  }

  String _formatEditableValue(double value) => value.toStringAsFixed(2).replaceAll('.', ',');

  String _formatDateTime(DateTime value) => '${_formatDate(value)} ${_formatTime(value)}';

  String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  String _formatTime(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String value) {
    final match = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value.trim());
    if (match == null) return null;
    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final result = DateTime(year, month, day);
    return result.year == year && result.month == month && result.day == day
        ? result
        : null;
  }

  TimeOfDay? _parseTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour <= 23 && minute <= 59 ? TimeOfDay(hour: hour, minute: minute) : null;
  }

  DateTime? _combineDateAndTime(String date, String time) {
    final selectedDate = _parseDate(date);
    final selectedTime = _parseTime(time);
    if (selectedDate == null || selectedTime == null) return null;
    return DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
  }

  String _formatCurrency(double value) =>
      'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imageSource(imageUrl),
          height: 130,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            height: 80,
            child: Center(child: Text('Não foi possível carregar a imagem.')),
          ),
        ),
      );
}

String _imageSource(String value) =>
    Uri.encodeFull(value.trim().replaceAll('\\', '/'));

/// Formata a digitação do horário como `HH:mm`.
class _TimeInputFormatter extends TextInputFormatter {
  const _TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final formatted = switch (limited.length) {
      <= 2 => limited,
      _ => '${limited.substring(0, 2)}:${limited.substring(2)}',
    };
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
