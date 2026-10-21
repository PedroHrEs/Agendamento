import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../models/patient.dart';
import '../services/patient_repository.dart';
import '../services/schedule_repository.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _primary = Color(0xFF007A78);
  final ScheduleRepository _repository = ScheduleRepository();
  final PatientRepository _patientRepository = PatientRepository();
  late final Stream<List<ScheduleModel>> _schedules;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _schedules = _repository.streamMySchedules();
  }

  Future<void> _openScheduleDialog([ScheduleModel? schedule]) async {
    final current = schedule == null
        ? _nextAvailableDate()
        : DateTime.tryParse(schedule.horario) ?? _nextAvailableDate();
    DateTime selectedDate = DateTime(current.year, current.month, current.day);
    int selectedHour = current.hour < 8 ? 8 : (current.hour > 18 ? 18 : current.hour);
    PatientModel? selectedPatient;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(schedule == null ? 'Novo agendamento' : 'Editar agendamento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Data da consulta'),
                  subtitle: Text(_formatDate(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(DateTime.now().year + 2),
                    );
                    if (date != null) setDialogState(() => selectedDate = date);
                  },
                ),
                const SizedBox(height: 12),
                StreamBuilder<List<PatientModel>>(
                  stream: _patientRepository.streamMyPatients(),
                  builder: (context, patientSnapshot) {
                    final patients = patientSnapshot.data ?? const <PatientModel>[];
                    if (selectedPatient == null && schedule != null) {
                      for (final patient in patients) {
                        if (patient.id == schedule.patientId) selectedPatient = patient;
                      }
                    }
                    return DropdownButtonFormField<String>(
                      value: selectedPatient?.id,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Paciente',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      hint: Text(patientSnapshot.hasData ? 'Selecione o paciente' : 'Carregando pacientes...'),
                      items: patients.map((patient) => DropdownMenuItem<String>(
                        value: patient.id,
                        child: Text(patient.name, overflow: TextOverflow.ellipsis),
                      )).toList(),
                      onChanged: patients.isEmpty
                          ? null
                          : (patientId) {
                              if (patientId == null) return;
                              setDialogState(() {
                                selectedPatient = patients.firstWhere(
                                  (patient) => patient.id == patientId,
                                );
                              });
                            },
                    );
                  },
                ),
                const SizedBox(height: 12),
                const Text('Horário disponível (08:00 às 18:00)'),
                const SizedBox(height: 10),
                StreamBuilder<Set<int>>(
                  stream: _repository.streamBookedHours(selectedDate),
                  builder: (context, snapshot) {
                    final bookedHours = snapshot.data ?? <int>{};
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(11, (index) {
                        final hour = index + 8;
                        final selectedDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          hour,
                        );
                        final isCurrentSchedule = schedule != null &&
                            schedule.uid.isNotEmpty &&
                            DateTime.tryParse(schedule.horario) ==
                                selectedDateTime;
                        final isBooked =
                            bookedHours.contains(hour) && !isCurrentSchedule;

                        return ChoiceChip(
                          label: Text('${hour.toString().padLeft(2, '0')}:00'),
                          selected: selectedHour == hour,
                          onSelected: isBooked || !snapshot.hasData
                              ? null
                              : (_) => setDialogState(() => selectedHour = hour),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDialogState(() => saving = true);
                      final dateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedHour,
                      );
                      if (selectedPatient == null) {
                        setDialogState(() => saving = false);
                        _showMessage('Selecione um paciente para o agendamento.');
                        return;
                      }
                      try {
                        if (schedule == null) {
                          await _repository.create(
                            dateTime: dateTime,
                            patientId: selectedPatient!.id,
                            patientName: selectedPatient!.name,
                          );
                        } else {
                          await _repository.update(
                            schedule: schedule,
                            dateTime: dateTime,
                            patientId: selectedPatient!.id,
                            patientName: selectedPatient!.name,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.pop(dialogContext);
                        _showMessage('Agendamento salvo com sucesso.');
                      } catch (error) {
                        if (!context.mounted) return;
                        setDialogState(() => saving = false);
                        _showMessage(error.toString().replaceFirst('Exception: ', ''));
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
              ),
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
  }

  Future<void> _delete(ScheduleModel schedule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir agendamento?'),
        content: Text('A consulta de ${_formatDateTime(schedule.horario)} será removida.'),
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
    if (confirm != true) return;
    try {
      await _repository.delete(schedule);
      if (mounted) _showMessage('Agendamento excluído.');
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus agendamentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScheduleDialog,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agendar'),
      ),
      body: StreamBuilder<List<ScheduleModel>>(
        stream: _schedules,
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final schedules = snapshot.data!;
          if (schedules.isEmpty) {
            return const Center(child: Text('Você ainda não possui agendamentos.'));
          }
          final query = _searchQuery.trim().toLowerCase();
          final filteredSchedules = schedules.where((schedule) =>
              schedule.patientName.toLowerCase().contains(query) ||
              _formatDateTime(schedule.horario).toLowerCase().contains(query)).toList();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Pesquisar agendamento',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: filteredSchedules.isEmpty
                  ? const Center(child: Text('Nenhum agendamento encontrado.'))
                  : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: filteredSchedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final schedule = filteredSchedules[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F3F1),
                    foregroundColor: _primary,
                    child: Icon(Icons.event_available_outlined),
                  ),
                  title: Text(_formatDateTime(schedule.horario)),
                  subtitle: Text(schedule.patientName.isEmpty
                      ? 'Paciente não informado'
                      : 'Paciente: ${schedule.patientName}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'edit') _openScheduleDialog(schedule);
                      if (action == 'delete') _delete(schedule);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir')),
                    ],
                  ),
                ),
              );
            },
          ),
            ),
          ]);
        },
      ),
    );
  }

  DateTime _nextAvailableDate() {
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    if (nextHour.day != now.day || nextHour.hour > 18) {
      return DateTime(nextHour.year, nextHour.month, nextHour.day, 8);
    }
    return nextHour.hour < 8 ? DateTime(now.year, now.month, now.day, 8) : nextHour;
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String _formatDateTime(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    return '${_formatDate(date)} às ${date.hour.toString().padLeft(2, '0')}:00';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
