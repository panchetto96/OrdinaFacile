import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Step {
  const _Step(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

const _customerSteps = [
  _Step(Icons.waving_hand, 'Benvenuto in OrdinaFacile', 'Da qui ordini al magazzino Dofrelli in pochi tocchi. Ti mostriamo come funziona in un minuto.'),
  _Step(Icons.edit_note, 'Scrivi ordine', 'Scrivi quello che ti serve come in un messaggio, per esempio "2 kg mozzarella", e tocca Invia ordine.'),
  _Step(Icons.photo_camera, 'Carica foto ordine', 'Hai l\'ordine su un foglio? Fotografalo, o sceglilo dalla galleria, e invialo così com\'è.'),
  _Step(Icons.add_shopping_cart, 'Aggiungi dal listino', 'Tocca Aggiungi sui prodotti, regola le quantità con − e +, poi vai al carrello e tocca Invia ordine.'),
  _Step(Icons.support_agent, 'Info e prezzi', 'I prezzi non sono nel listino: tocca "Per info e prezzi contattaci" per chiamare o scrivere al magazzino.'),
  _Step(Icons.receipt_long, 'I tuoi ordini', 'In Ordini vedi lo stato di ogni ordine, puoi rifarlo con Riordina e aprire le fatture.'),
  _Step(Icons.help_outline, 'Serve aiuto?', 'In Profilo trovi "Rivedi tutorial" e il Manuale utente, sempre a portata di mano.'),
];

const _adminSteps = [
  _Step(Icons.waving_hand, 'Benvenuto, titolare', 'Da qui ricevi gli ordini dei clienti e gestisci listino, clienti e fatture.'),
  _Step(Icons.inbox, 'Ordini', 'Tutti gli ordini arrivano qui, con i filtri Nuovi, Visti e Annullati. Apri un ordine e tocca Segna come visto o Annulla.'),
  _Step(Icons.inventory_2, 'Catalogo', 'Aggiungi e modifica i prodotti, segna quelli esauriti, o importa tutto il listino da un file Excel.'),
  _Step(Icons.how_to_reg, 'Nuovi clienti', 'Chi si registra compare in Clienti come "Da approvare": tocca Approva e potrà vedere il listino e ordinare.'),
  _Step(Icons.sell, 'Prezzi riservati', 'In Clienti apri un cliente, tocca un prodotto e scrivi il suo prezzo. "Usa listino" torna al prezzo normale.'),
  _Step(Icons.picture_as_pdf, 'Fatture', 'Tocca Fattura accanto al cliente, scegli gli ordini e allega il PDF del tuo gestionale.'),
  _Step(Icons.help_outline, 'Serve aiuto?', 'In Profilo trovi "Rivedi tutorial" e il Manuale utente.'),
];

/// Tutorial a pagine, diverso per cliente e titolare.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, required this.isAdmin});
  final bool isAdmin;

  /// Lo mostra la prima volta che quel ruolo entra su questo telefono.
  static Future<void> showIfFirstTime(BuildContext context, {required bool isAdmin}) async {
    final key = 'tutorial_seen_${isAdmin ? 'admin' : 'customer'}';
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => TutorialScreen(isAdmin: isAdmin)));
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pages = PageController();
  int _index = 0;

  List<_Step> get _steps => widget.isAdmin ? _adminSteps : _customerSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = _index == _steps.length - 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [if (!last) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Salta'))],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              children: [
                for (final s in _steps)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(s.icon, size: 96, color: theme.colorScheme.primary),
                      const SizedBox(height: 32),
                      Text(s.title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Text(s.text, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
                    ]),
                  ),
              ],
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _steps.length; i++)
              Container(
                width: i == _index ? 20 : 8,
                height: 8,
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: i == _index ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: () => last
                    ? Navigator.pop(context)
                    : _pages.nextPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(last ? 'Inizia' : 'Avanti', style: const TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
