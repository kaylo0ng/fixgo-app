import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('es'),
  ];

  String get appTitle => Intl.message(
        'FixGo',
        name: 'appTitle',
        locale: localeName,
      );

  String get homeTitle => Intl.message(
        'Servicios del hogar con técnicos confiables',
        name: 'homeTitle',
        locale: localeName,
      );

  String get homeSubtitle => Intl.message(
        'Publica lo que necesitas, recibe ofertas y elige al técnico que mejor se ajuste a tu solicitud.',
        name: 'homeSubtitle',
        locale: localeName,
      );

  String get postRequestButton => Intl.message(
        'Publicar solicitud',
        name: 'postRequestButton',
        locale: localeName,
      );

  String get technicianLoginButton => Intl.message(
        'Ingresar como técnico',
        name: 'technicianLoginButton',
        locale: localeName,
      );

  String get mainCategoriesTitle => Intl.message(
        'Categorías principales',
        name: 'mainCategoriesTitle',
        locale: localeName,
      );

  String get mvpFlowTitle => Intl.message(
        'Flujo del MVP',
        name: 'mvpFlowTitle',
        locale: localeName,
      );

  String get requestPublished => Intl.message(
        'Solicitud publicada',
        name: 'requestPublished',
        locale: localeName,
      );

  String get requestPublishedDescription => Intl.message(
        'El cliente describe el trabajo y su ubicación.',
        name: 'requestPublishedDescription',
        locale: localeName,
      );

  String get offersReceived => Intl.message(
        'Ofertas recibidas',
        name: 'offersReceived',
        locale: localeName,
      );

  String get offersReceivedDescription => Intl.message(
        'Los técnicos proponen precio, tiempo y condiciones.',
        name: 'offersReceivedDescription',
        locale: localeName,
      );

  String get technicianSelected => Intl.message(
        'Técnico seleccionado',
        name: 'technicianSelected',
        locale: localeName,
      );

  String get technicianSelectedDescription => Intl.message(
        'El cliente elige con base en confianza y propuesta.',
        name: 'technicianSelectedDescription',
        locale: localeName,
      );

  String get serviceRated => Intl.message(
        'Servicio calificado',
        name: 'serviceRated',
        locale: localeName,
      );

  String get serviceRatedDescription => Intl.message(
        'Ambas partes califican la experiencia al finalizar.',
        name: 'serviceRatedDescription',
        locale: localeName,
      );
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final String name = locale.languageCode;
    final localeName = Intl.canonicalizedLocale(name);
    return SynchronousFuture<AppLocalizations>(AppLocalizations(localeName));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
