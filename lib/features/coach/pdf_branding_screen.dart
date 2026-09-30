import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../services/pdf/pdf_author.dart';
import '../help/help_button.dart';

/// Údaje trenéra na PDF: podpis, kontakty a logo.
class PdfBrandingScreen extends StatefulWidget {
  const PdfBrandingScreen({super.key});

  @override
  State<PdfBrandingScreen> createState() => _PdfBrandingScreenState();
}

class _PdfBrandingScreenState extends State<PdfBrandingScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _instagram = TextEditingController();
  final _web = TextEditingController();
  Uint8List? _logo;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await PdfAuthor.loadSaved();
    final b = await PdfAuthor.loadBrand();
    if (!mounted) return;
    setState(() {
      _name.text = name;
      _phone.text = b.phone;
      _email.text = b.email;
      _instagram.text = b.instagram;
      _web.text = b.web;
      _logo = b.logo;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _instagram.dispose();
    _web.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    const group = XTypeGroup(
      label: 'Obrázek (PNG, JPG)',
      extensions: ['png', 'jpg', 'jpeg'],
    );
    try {
      final file = await openFile(acceptedTypeGroups: const [group]);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > PdfAuthor.maxLogoBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logo je moc velké (max. 1,5 MB). Zmenši ho nebo ulož '
              'jako PNG v menším rozlišení.',
            ),
          ),
        );
        return;
      }
      setState(() => _logo = bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logo se nepodařilo načíst: $e')),
      );
    }
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zkontroluj prosím e-mail.')),
      );
      return;
    }
    setState(() => _busy = true);
    await PdfAuthor.save(_name.text);
    await PdfAuthor.saveBrand(
      phone: _phone.text,
      email: email,
      instagram: _instagram.text.trim().replaceAll(' ', ''),
      web: _web.text,
    );
    await PdfAuthor.saveLogo(_logo);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uloženo. Údaje se objeví na všech nových PDF.'),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget field(
      TextEditingController c,
      String label, {
      String? hint,
      IconData? icon,
      TextInputType? type,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: c,
            keyboardType: type,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: icon == null ? null : Icon(icon),
              border: const OutlineInputBorder(),
            ),
          ),
        );

    final preview = PdfBrand(
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      instagram: _instagram.text.trim(),
      web: _web.text.trim(),
      logo: _logo,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Údaje na dokumentech'),
        actions: const [HelpButton(topic: 'pdf')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Tyto údaje se tisknou na jídelníčky, tréninkové plány '
                      'a souhrny klientů – logo a kontakt nahoře na stránce, '
                      'podpis a kontakt na konci dokumentu.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    field(
                      _name,
                      'Vypracoval/a (jméno a zaměření)',
                      hint: 'Martina Šmejkalová – osobní trenérka',
                      icon: Icons.draw_outlined,
                    ),
                    field(
                      _phone,
                      'Telefon',
                      hint: '777 123 456',
                      icon: Icons.phone_outlined,
                      type: TextInputType.phone,
                    ),
                    field(
                      _email,
                      'E-mail',
                      hint: 'jmeno@email.cz',
                      icon: Icons.mail_outline,
                      type: TextInputType.emailAddress,
                    ),
                    field(
                      _instagram,
                      'Instagram',
                      hint: '@uzivatelske_jmeno',
                      icon: Icons.camera_alt_outlined,
                    ),
                    field(
                      _web,
                      'Web (nepovinné)',
                      hint: 'www.mujweb.cz',
                      icon: Icons.language,
                      type: TextInputType.url,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Logo',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 140,
                          height: 70,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: _logo == null
                              ? Text(
                                  'bez loga',
                                  style: TextStyle(color: Colors.grey.shade600),
                                )
                              : Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.memory(_logo!,
                                      fit: BoxFit.contain),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: _pickLogo,
                                icon: const Icon(Icons.image_outlined),
                                label: Text(_logo == null
                                    ? 'Vybrat logo'
                                    : 'Změnit logo'),
                              ),
                              if (_logo != null)
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _logo = null),
                                  child: const Text('Odebrat'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PNG nebo JPG, ideálně na průhledném nebo bílém pozadí.',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Náhled hlavičky',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          if (_logo != null)
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 34,
                                maxWidth: 130,
                              ),
                              child: Image.memory(_logo!, fit: BoxFit.contain),
                            ),
                          const Spacer(),
                          Flexible(
                            flex: 3,
                            child: Text(
                              preview.hasContacts
                                  ? preview.contactLine
                                  : 'Kontakty nevyplněny',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF5B6470),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _busy ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Uložit'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
