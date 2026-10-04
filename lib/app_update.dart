import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

/// Per ora la CI non pubblica version.json (Matteo distribuisce l'APK a mano):
/// finché il file non esiste il controllo non mostra nulla.
final versionUrl = Uri.parse('$supabaseUrl/storage/v1/object/public/app/version.json');

class AppVersion {
  AppVersion({required this.build, required this.name, required this.url});

  final int build;
  final String name;
  final Uri url;

  factory AppVersion.fromJson(Map<String, dynamic> m) => AppVersion(
        build: (m['build'] as num).toInt(),
        name: m['name'] as String? ?? '',
        url: Uri.parse(m['url'] as String),
      );
}

/// Versione più recente se è più nuova di quella installata ([installedBuild]), altrimenti null.
AppVersion? newerVersion(String versionJson, int installedBuild) {
  final latest = AppVersion.fromJson(jsonDecode(versionJson) as Map<String, dynamic>);
  return latest.build > installedBuild ? latest : null;
}

/// All'avvio controlla se è uscita una versione nuova e propone di scaricarla.
/// Senza rete, o se il controllo fallisce, non mostra nulla.
class UpdateChecker extends StatefulWidget {
  const UpdateChecker({super.key, required this.child});
  final Widget child;

  @override
  State<UpdateChecker> createState() => _UpdateCheckerState();
}

class _UpdateCheckerState extends State<UpdateChecker> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final res = await http.get(versionUrl).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final update = newerVersion(res.body, int.tryParse(info.buildNumber) ?? 0);
      if (update == null || !mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.system_update),
          title: const Text('Nuova versione disponibile'),
          content: Text(
            'È disponibile OrdinaFacile ${update.name}.\n\n'
            'Tocca Aggiorna: il file viene scaricato, poi aprilo e conferma l\'installazione. '
            'Account e carrello restano.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Più tardi')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(update.url, mode: LaunchMode.externalApplication);
              },
              child: const Text('Aggiorna'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Il controllo aggiornamenti non deve mai bloccare l'app.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
