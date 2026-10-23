import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/dentist.dart';
import '../services/dentist_jsonbin_repository.dart';

class DentistsJsonBinPage extends StatefulWidget {
  const DentistsJsonBinPage({super.key});

  @override
  State<DentistsJsonBinPage> createState() => _DentistsJsonBinPageState();
}

class _DentistsJsonBinPageState extends State<DentistsJsonBinPage> {
  static const _primary = Color(0xFF007A78);
  final _repository = DentistJsonBinRepository();
  late Future<List<DentistModel>> _dentists;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _dentists = _repository.getAll();
  }

  Future<void> _reload() async {
    final refreshedDentists = await _repository.getAll();
    if (!mounted) return;
    setState(() {
      _dentists = Future.value(refreshedDentists);
    });
  }

  Future<void> _openForm([DentistModel? dentist]) async {
    final result = await showDialog<DentistModel>(
      context: context,
      builder: (_) => _DentistFormDialog(dentist: dentist),
    );
    if (result == null || !mounted) return;
    try {
      if (dentist == null) {
        await _repository.create(result);
      } else {
        await _repository.update(dentist.cro, result);
      }
      await _reload();
      if (mounted) {
        _message(dentist == null ? 'Dentista cadastrado.' : 'Dentista atualizado.');
      }
    } catch (error) {
      if (mounted) _message(_errorText(error));
    }
  }

  Future<void> _delete(DentistModel dentist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir dentista?'),
        content: Text('O(a) ${dentist.nome} será removido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(dentist.cro);
      await _reload();
      if (mounted) _message('Dentista excluído.');
    } catch (error) {
      if (mounted) _message(_errorText(error));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dentistas')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Cadastrar'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(labelText: 'Consultar dentistas', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<DentistModel>>(
              future: _dentists,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return _errorView(snapshot.error!);
                final query = _search.trim().toLowerCase();
                final dentists = snapshot.data!.where((item) =>
                  item.nome.toLowerCase().contains(query) || item.cro.toLowerCase().contains(query) ||
                  item.especialidade.toLowerCase().contains(query)).toList();
                if (dentists.isEmpty) return Center(child: Text(snapshot.data!.isEmpty
                    ? 'Nenhum dentista cadastrado.' : 'Nenhum dentista encontrado.'));
                return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: dentists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final dentist = dentists[index];
                      return Card(child: ListTile(
                        leading: _avatar(dentist.img),
                        title: Text(dentist.nome),
                        subtitle: Text('${dentist.especialidade}\nCRO: ${dentist.cro} • ${dentist.telefone}'),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) => action == 'edit' ? _openForm(dentist) : _delete(dentist),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Alterar')),
                            PopupMenuItem(value: 'delete', child: Text('Excluir')),
                          ],
                        ),
                      ));
                    },
                  );
              },
            ),
          ),
        ]),
      );

  Widget _errorView(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: _primary),
            const SizedBox(height: 12),
            Text(_errorText(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
          ]),
        ),
      );

  Widget _avatar(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      return const CircleAvatar(child: Icon(Icons.medical_services_outlined));
    }
    return CircleAvatar(backgroundImage: NetworkImage(url), onBackgroundImageError: (_, __) {});
  }

  Widget _field(TextEditingController controller, String label,
      {bool required = true, TextInputType? keyboard}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Informe $label.';
            if (label == 'URL da imagem' && text.isNotEmpty) {
              final uri = Uri.tryParse(text);
              if (uri == null || !uri.hasScheme || !uri.hasAuthority) return 'Informe uma URL válida.';
            }
            return null;
          },
        ),
      );

  String _errorText(Object error) => error.toString().replaceFirst('Exception: ', '');
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _DentistFormDialog extends StatefulWidget {
  const _DentistFormDialog({this.dentist});

  final DentistModel? dentist;

  @override
  State<_DentistFormDialog> createState() => _DentistFormDialogState();
}

class _DentistFormDialogState extends State<_DentistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nome;
  late final TextEditingController _cro;
  late final TextEditingController _especialidade;
  late final TextEditingController _telefone;
  late final TextEditingController _img;

  @override
  void initState() {
    super.initState();
    final dentist = widget.dentist;
    _nome = TextEditingController(text: dentist?.nome);
    _cro = TextEditingController(text: dentist?.cro);
    _especialidade = TextEditingController(text: dentist?.especialidade);
    _telefone = TextEditingController(text: dentist?.telefone);
    _img = TextEditingController(text: dentist?.img);
  }

  @override
  void dispose() {
    _nome.dispose();
    _cro.dispose();
    _especialidade.dispose();
    _telefone.dispose();
    _img.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.dentist == null ? 'Cadastrar dentista' : 'Alterar dentista'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(_nome, 'Nome'),
                _field(_cro, 'CRO'),
                _field(_especialidade, 'Especialidade'),
                _field(_telefone, 'Telefone', keyboard: TextInputType.phone),
                _field(_img, 'URL da imagem', keyboard: TextInputType.url),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, DentistModel(
                nome: _nome.text,
                cro: _cro.text,
                especialidade: _especialidade.text,
                telefone: _telefone.text,
                img: _img.text,
              ));
            },
            child: const Text('Salvar'),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label,
          {bool required = true, TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: label == 'Telefone'
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ()-]'))]
              : null,
          decoration: InputDecoration(labelText: label),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (required && text.isEmpty) return 'Informe $label.';
            if (label == 'Nome' && text.length < 5) {
              return 'O nome deve ter pelo menos 5 caracteres.';
            }
            if (label == 'CRO' && text.length < 5) {
              return 'O CRO deve ter pelo menos 5 caracteres.';
            }
            if (label == 'Especialidade' && text.length < 3) {
              return 'A especialidade deve ter pelo menos 3 caracteres.';
            }
            if (label == 'Telefone') {
              final digits = text.replaceAll(RegExp(r'\D'), '');
              if (!RegExp(r'^(\d{8,9}|\d{10,11})$').hasMatch(digits)) {
                return 'Use 8 ou 9 dígitos, com DDD opcional.';
              }
            }
            if (label == 'URL da imagem' && text.isNotEmpty) {
              final uri = Uri.tryParse(text);
              if (uri == null || !uri.hasScheme || !uri.hasAuthority ||
                  (uri.scheme != 'http' && uri.scheme != 'https')) {
                return 'Informe uma URL válida.';
              }
            }
            return null;
          },
        ),
      );
}
