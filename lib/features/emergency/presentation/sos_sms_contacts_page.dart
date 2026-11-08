import 'package:flutter/material.dart';

import '../data/sos_sms_contact_store.dart';
import '../domain/sos_sms_contact.dart';

class SosSmsContactsPage extends StatefulWidget {
  const SosSmsContactsPage({super.key, this.store});

  final SosSmsContactStore? store;

  @override
  State<SosSmsContactsPage> createState() => _SosSmsContactsPageState();
}

class _SosSmsContactsPageState extends State<SosSmsContactsPage> {
  late final SosSmsContactStore _store =
      widget.store ?? SecureSosSmsContactStore();
  List<SosSmsContact> _contacts = const [];
  Object? _loadError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _store.readContacts();
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loadError = null;
        _loading = false;
      });
    } catch (error) {
      debugPrint('No se pudieron leer los contactos SMS SOS: $error');
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _editContact({int? index}) async {
    final current = index == null ? null : _contacts[index];
    final contact = await showDialog<SosSmsContact>(
      context: context,
      builder: (_) => _SosSmsContactDialog(
        contact: current,
        existingContacts: [
          for (var i = 0; i < _contacts.length; i++)
            if (i != index) _contacts[i],
        ],
      ),
    );
    if (contact == null || !mounted) return;

    final updated = List<SosSmsContact>.of(_contacts);
    if (index == null) {
      updated.add(contact);
    } else {
      updated[index] = contact;
    }
    await _saveContacts(updated);
  }

  Future<void> _removeContact(int index) async {
    final contact = _contacts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar contacto SOS'),
        content: Text('¿Eliminar a ${contact.name} de tus contactos SOS?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final updated = List<SosSmsContact>.of(_contacts)..removeAt(index);
    await _saveContacts(updated);
  }

  Future<void> _saveContacts(List<SosSmsContact> contacts) async {
    try {
      await _store.saveContacts(contacts);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loadError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contactos SOS guardados en este dispositivo.'),
        ),
      );
    } catch (error) {
      debugPrint('No se pudieron guardar los contactos SMS SOS: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron guardar los contactos SOS de forma segura.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Contactos SOS por SMS')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _loadError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No se pudieron leer los contactos SOS guardados.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _loadContacts,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Agrega contactos de confianza antes de una emergencia. '
                'Sus números se guardan de forma segura solo en este dispositivo. '
                'La app abrirá el SMS para que revises y confirmes el envío. '
                'Se requiere SIM y cobertura celular; el operador puede cobrar el mensaje.',
              ),
              const SizedBox(height: 16),
              if (_contacts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('Aún no agregas contactos.')),
                )
              else
                ..._contacts.indexed.map(
                  (entry) => ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(entry.$2.name),
                    subtitle: Text(entry.$2.phoneNumber),
                    onTap: () => _editContact(index: entry.$1),
                    trailing: IconButton(
                      tooltip: 'Eliminar contacto ${entry.$2.name}',
                      onPressed: () => _removeContact(entry.$1),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const ValueKey('add-sos-sms-contact'),
                onPressed: () => _editContact(),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Agregar contacto'),
              ),
            ],
          ),
  );
}

class _SosSmsContactDialog extends StatefulWidget {
  const _SosSmsContactDialog({required this.existingContacts, this.contact});

  final List<SosSmsContact> existingContacts;
  final SosSmsContact? contact;

  @override
  State<_SosSmsContactDialog> createState() => _SosSmsContactDialogState();
}

class _SosSmsContactDialogState extends State<_SosSmsContactDialog> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.contact?.name,
  );
  late final _phoneController = TextEditingController(
    text: widget.contact?.phoneNumber,
  );
  bool _duplicateNumber = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final number = SosSmsContact.normalizePhoneNumber(_phoneController.text)!;
    final duplicate = widget.existingContacts.any(
      (contact) =>
          SosSmsContact.normalizePhoneNumber(contact.phoneNumber) == number,
    );
    if (duplicate) {
      setState(() => _duplicateNumber = true);
      return;
    }
    Navigator.pop(
      context,
      SosSmsContact(name: _nameController.text.trim(), phoneNumber: number),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.contact == null ? 'Agregar contacto SOS' : 'Editar contacto',
    ),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: const ValueKey('sos-sms-contact-name'),
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Ingresa un nombre.'
                : null,
          ),
          TextFormField(
            key: const ValueKey('sos-sms-contact-phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono',
              hintText: '+51 987 654 321',
            ),
            validator: (value) =>
                SosSmsContact.normalizePhoneNumber(value ?? '') == null
                ? 'Ingresa un número válido (7 a 15 dígitos).'
                : null,
          ),
          if (_duplicateNumber)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ese número ya está registrado.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _save, child: const Text('Guardar contacto')),
    ],
  );
}
