import 'package:flutter/material.dart';

class _Section {
  const _Section(this.title, this.lines);
  final String title;
  final List<String> lines;
}

const _customerManual = [
  _Section('Accesso e password', [
    'Si entra con email e password. Con "Ricordami" attivo l\'app resta collegata.',
    'Password dimenticata? Tocca il pulsante nella schermata di accesso: ricevi un codice via email, lo scrivi con la nuova password e sei dentro.',
  ]),
  _Section('Scrivere un ordine', [
    'Dalla Home tocca "Scrivi ordine", scrivi cosa ti serve (es. 2 kg mozzarella) e tocca Invia ordine.',
  ]),
  _Section('Ordine con foto', [
    'Tocca "Carica foto ordine": si apre la fotocamera. Puoi anche scegliere una foto dalla galleria e aggiungere una nota.',
    'Le foto degli ordini si cancellano dopo 60 giorni; l\'ordine resta.',
  ]),
  _Section('Ordinare dal listino', [
    'Tocca "Aggiungi ordine dal listino prezzi", poi Aggiungi sui prodotti. Regola le quantità con − e +, o tocca il numero per scriverlo.',
    'Apri il Carrello, aggiungi una nota se serve e tocca Invia ordine. Pesi e importo finale li conferma il magazzino.',
    'Se l\'invio non riesce il carrello resta com\'era: riprova quando c\'è rete.',
  ]),
  _Section('Info e prezzi', [
    'I prezzi non sono mostrati. Nel listino tocca "Per info e prezzi contattaci" per chiamare o scrivere al magazzino.',
  ]),
  _Section('I miei ordini e fatture', [
    'In Ordini vedi ogni ordine con lo stato: Nuovo, Visto (preso in carico) o Annullato.',
    'Riordina rimette nel carrello i prodotti di un ordine fatto dal listino.',
    'Quando arriva una fattura, sull\'ordine compare il pulsante Fattura: toccalo per aprire il PDF.',
  ]),
  _Section('Profilo', [
    'Modifica nome attività, indirizzo e telefono e tocca Salva.',
    '"Elimina il mio account" cancella i tuoi dati personali in modo definitivo; ordini e fatture restano al magazzino senza il tuo nome.',
  ]),
];

const _adminManual = [
  _Section('Ordini', [
    'Tutti gli ordini arrivano in Ordini, con i filtri Tutti, Nuovi, Visti, Annullati.',
    'Apri un ordine per vedere cliente, indirizzo, telefono, prodotti con prezzo, testo o foto e nota.',
    'Segna come visto: il cliente vede che l\'ordine è preso in carico. Annulla: chiede conferma.',
    'Le foto si cancellano dopo 60 giorni: se ne serve una, fai uno screenshot prima.',
  ]),
  _Section('Catalogo', [
    'Il pulsante Prodotto aggiunge un prodotto: nome, categoria, prezzo, unità e Disponibile.',
    'Tocca un prodotto per modificarlo o eliminarlo. Meglio segnarlo non disponibile che eliminarlo.',
    'Il pulsante di importazione in alto carica un file Excel/CSV con colonne nome, categoria, prezzo, unita (kg, etto, pz, lt, ct) e disponibile.',
  ]),
  _Section('Nuovi clienti', [
    'I nuovi iscritti compaiono in cima a Clienti come "Da approvare". Controlla i dati e tocca Approva.',
  ]),
  _Section('Prezzi riservati', [
    'In Clienti tocca il cliente, poi il prodotto: scrivi il prezzo e tocca Salva. "Usa listino" torna al prezzo normale.',
    'I clienti non vedono i prezzi: quello riservato vale negli ordini che ricevi.',
  ]),
  _Section('Fatture', [
    'In Clienti tocca Fattura accanto al cliente, scegli uno o più ordini, scrivi il numero (facoltativo), scegli il PDF e tocca Invia fattura.',
    'La fattura si prepara sempre con il tuo gestionale: l\'app la consegna soltanto.',
  ]),
];

/// Manuale utente dentro l'app, diverso per cliente e titolare.
class ManualScreen extends StatelessWidget {
  const ManualScreen({super.key, required this.isAdmin});
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final sections = isAdmin ? _adminManual : _customerManual;
    return Scaffold(
      appBar: AppBar(title: const Text('Manuale utente')),
      body: ListView(children: [
        for (final s in sections)
          ExpansionTile(
            title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final l in s.lines)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(l, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
      ]),
    );
  }
}
