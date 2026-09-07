import 'package:flutter/material.dart';

import '../models/schedule.dart';
import '../services/schedule_repository.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  static const _primary = Color(0xFF007A78);
  final ScheduleRepository _repository = ScheduleRepository();
  late final Stream<List<ScheduleModel>> _schedules;

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
                const Text('Horário disponível (08:00 às 18:00)'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(11, (index) {
                    final hour = index + 8;
                    return ChoiceChip(
                      label: Text('${hour.toString().padLeft(2, '0')}:00'),
                      selected: selectedHour == hour,
                      onSelected: (_) => setDialogState(() => selectedHour = hour),
                    );
                  }),
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
                      try {
                        if (schedule == null) {
                          await _repository.create(dateTime: dateTime);
                        } else {
                          await _repository.update(schedule: schedule, dateTime: dateTime);
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
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final schedule = schedules[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE3F3F1),
                    foregroundColor: _primary,
                    child: Icon(Icons.event_available_outlined),
                  ),
                  title: Text(_formatDateTime(schedule.horario)),
                  subtitle: const Text('Consulta agendada'),
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
          );
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
