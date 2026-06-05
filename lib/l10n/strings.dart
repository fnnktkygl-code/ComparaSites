/// App localised strings.
/// Usage: AppStrings.of(context).search
library;

import 'package:flutter/material.dart';

class AppStrings {
  final String search;
  final String history;
  final String searchAndScan;
  final String scanning;
  final String pasteUrl;
  final String viaUrl;
  final String reference;
  final String stop;
  final String rescan;
  final String results;
  final String bestOffer;
  final String buyIn;
  final String saveVsFrance;
  final String scanProgress;
  final String noHistory;
  final String myScans;
  final String clearHistory;
  final String clearConfirm;
  final String yes;
  final String no;
  final String close;
  final String aboutTitle;
  final String aboutBody;
  final String aboutBrands;
  final String aboutWebNote;
  final String compareEurope;
  final String notScanned;
  final String settings;
  final String appearance;
  final String systemTheme;
  final String lightTheme;
  final String darkTheme;
  final String language;
  final String seenOn;
  final String pricesFound;
  final String scanningCountry;
  final String errorPrefix;

  const AppStrings({
    required this.search,
    required this.history,
    required this.searchAndScan,
    required this.scanning,
    required this.pasteUrl,
    required this.viaUrl,
    required this.reference,
    required this.stop,
    required this.rescan,
    required this.results,
    required this.bestOffer,
    required this.buyIn,
    required this.saveVsFrance,
    required this.scanProgress,
    required this.noHistory,
    required this.myScans,
    required this.clearHistory,
    required this.clearConfirm,
    required this.yes,
    required this.no,
    required this.close,
    required this.aboutTitle,
    required this.aboutBody,
    required this.aboutBrands,
    required this.aboutWebNote,
    required this.compareEurope,
    required this.notScanned,
    required this.settings,
    required this.appearance,
    required this.systemTheme,
    required this.lightTheme,
    required this.darkTheme,
    required this.language,
    required this.seenOn,
    required this.pricesFound,
    required this.scanningCountry,
    required this.errorPrefix,
  });

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return _strings[locale] ?? _strings['fr']!;
  }

  static final Map<String, AppStrings> _strings = {
    'fr': const AppStrings(
      search: 'Recherche',
      history: 'Historique',
      searchAndScan: 'Rechercher & Scanner',
      scanning: 'Scan en cours…',
      pasteUrl: 'Collez le lien ici…',
      viaUrl: 'Via URL',
      reference: 'Référence',
      stop: 'Stop',
      rescan: 'Rescanner',
      results: 'Résultats pour',
      bestOffer: 'Meilleure offre trouvée !',
      buyIn: 'Achetez en',
      saveVsFrance: '% par rapport à la France !',
      scanProgress: 'Progression du scan…',
      noHistory: 'Aucun historique',
      myScans: 'Mes Scans',
      clearHistory: 'Effacer l\'historique',
      clearConfirm: 'Effacer l\'historique ?',
      yes: 'Oui',
      no: 'Non',
      close: 'Fermer',
      aboutTitle: 'À propos de ComparaSites',
      aboutBody: 'ComparaSites vous permet de comparer les prix des produits à travers différents pays européens pour obtenir le meilleur prix.',
      aboutBrands: 'Recherche supportée pour :\n• Decathlon, Zara, JD Sports, Amazon, IKEA et Sephora.',
      aboutWebNote: 'En raison des restrictions de sécurité CORS des navigateurs, la recherche directe peut être bloquée. Nous recommandons l\'application native pour 100% de fiabilité.',
      compareEurope: 'Comparez les prix en Europe',
      notScanned: 'Non scanné',
      settings: 'Paramètres',
      appearance: 'Apparence',
      systemTheme: 'Système',
      lightTheme: 'Clair',
      darkTheme: 'Sombre',
      language: 'Langue',
      seenOn: 'Vu le',
      pricesFound: 'prix trouvés',
      scanningCountry: 'Scan :',
      errorPrefix: 'Erreur',
    ),
    'en': const AppStrings(
      search: 'Search',
      history: 'History',
      searchAndScan: 'Search & Scan',
      scanning: 'Scanning…',
      pasteUrl: 'Paste link here…',
      viaUrl: 'Via URL',
      reference: 'Reference',
      stop: 'Stop',
      rescan: 'Rescan',
      results: 'Results for',
      bestOffer: 'Best deal found!',
      buyIn: 'Buy in',
      saveVsFrance: '% cheaper than France!',
      scanProgress: 'Scan progress…',
      noHistory: 'No history yet',
      myScans: 'My Scans',
      clearHistory: 'Clear history',
      clearConfirm: 'Clear all history?',
      yes: 'Yes',
      no: 'No',
      close: 'Close',
      aboutTitle: 'About ComparaSites',
      aboutBody: 'ComparaSites lets you compare product prices across different European countries to find the best deal.',
      aboutBrands: 'Supported stores:\n• Decathlon, Zara, JD Sports, Amazon, IKEA and Sephora.',
      aboutWebNote: 'Due to browser CORS security restrictions, direct searches may be blocked for some stores. We recommend the native app for 100% reliability.',
      compareEurope: 'Compare prices across Europe',
      notScanned: 'Not scanned',
      settings: 'Settings',
      appearance: 'Appearance',
      systemTheme: 'System',
      lightTheme: 'Light',
      darkTheme: 'Dark',
      language: 'Language',
      seenOn: 'Seen on',
      pricesFound: 'prices found',
      scanningCountry: 'Scanning:',
      errorPrefix: 'Error',
    ),
    'es': const AppStrings(
      search: 'Búsqueda',
      history: 'Historial',
      searchAndScan: 'Buscar & Escanear',
      scanning: 'Escaneando…',
      pasteUrl: 'Pega el enlace aquí…',
      viaUrl: 'Via URL',
      reference: 'Referencia',
      stop: 'Parar',
      rescan: 'Reescanear',
      results: 'Resultados de',
      bestOffer: '¡Mejor oferta encontrada!',
      buyIn: 'Compra en',
      saveVsFrance: '% más barato que en Francia!',
      scanProgress: 'Progreso del escaneo…',
      noHistory: 'Sin historial',
      myScans: 'Mis Escaneos',
      clearHistory: 'Borrar historial',
      clearConfirm: '¿Borrar el historial?',
      yes: 'Sí',
      no: 'No',
      close: 'Cerrar',
      aboutTitle: 'Sobre ComparaSites',
      aboutBody: 'ComparaSites te permite comparar precios en diferentes países europeos para obtener el mejor precio.',
      aboutBrands: 'Tiendas compatibles:\n• Decathlon, Zara, JD Sports, Amazon, IKEA y Sephora.',
      aboutWebNote: 'Debido a las restricciones CORS del navegador, las búsquedas directas pueden estar bloqueadas. Recomendamos la app nativa para máxima fiabilidad.',
      compareEurope: 'Compara precios en Europa',
      notScanned: 'No escaneado',
      settings: 'Ajustes',
      appearance: 'Apariencia',
      systemTheme: 'Sistema',
      lightTheme: 'Claro',
      darkTheme: 'Oscuro',
      language: 'Idioma',
      seenOn: 'Visto el',
      pricesFound: 'precios encontrados',
      scanningCountry: 'Escaneando:',
      errorPrefix: 'Error',
    ),
  };
}
