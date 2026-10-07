// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Réglage du système';

  @override
  String get sectionSlideshow => 'Diaporama';

  @override
  String get slideDuration => 'Durée des diapositives';

  @override
  String get transitionDuration => 'Durée de transition';

  @override
  String get blurBorders => 'Flouter les bords';

  @override
  String get blurBordersSubtitle => 'Étendre l\'image à la taille de l\'écran';

  @override
  String get pairPhotos => 'Écran divisé';

  @override
  String get pairPhotosSubtitle =>
      'Afficher deux photos à la fois quand elles correspondent au format de l\'écran';

  @override
  String get photoOrder => 'Trier les photos par…';

  @override
  String get photoOrderRandom => 'Ordre aléatoire';

  @override
  String get photoOrderExif => 'Par date de prise de vue (EXIF)';

  @override
  String get photoOrderCreation => 'Par date de création du fichier';

  @override
  String get photoOrderModification => 'Par date de modification du fichier';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitSeconds => 's';

  @override
  String get sectionClock => 'Horloge';

  @override
  String get showClock => 'Afficher l\'horloge';

  @override
  String get showClockSubtitle => 'Afficher l\'heure sur le diaporama';

  @override
  String get size => 'Taille';

  @override
  String get position => 'Position';

  @override
  String get clockFormat => 'Format de l\'heure';

  @override
  String get clockFormatAuto => 'Automatique';

  @override
  String get clockFormat12 => '12 heures';

  @override
  String get clockFormat24 => '24 heures';

  @override
  String get sectionPhotoInfo => 'Informations photo';

  @override
  String get showPhotoInfo => 'Afficher les informations photo';

  @override
  String get showPhotoInfoSubtitle =>
      'Afficher la date et le lieu sur le diaporama';

  @override
  String get useScriptFont => 'Police manuscrite';

  @override
  String get useScriptFontSubtitle =>
      'Afficher les métadonnées dans un style manuscrit élégant';

  @override
  String get resolveLocationNames => 'Résoudre les noms de lieux';

  @override
  String get resolveLocationNamesSubtitle =>
      'Utiliser OpenStreetMap pour afficher les noms de lieux au lieu des coordonnées';

  @override
  String get nominatimHint =>
      'Utilise Nominatim (OpenStreetMap). Aucune clé d\'API requise.';

  @override
  String get sectionPhotoSource => 'Source des photos';

  @override
  String get watchPhotoFolder => 'Surveiller le dossier';

  @override
  String get watchPhotoFolderSubtitle =>
      'Détecter automatiquement les photos ajoutées et supprimées du dossier';

  @override
  String get pollInterval => 'Intervalle d\'analyse';

  @override
  String get pollIntervalSubtitle =>
      'Fréquence de relecture de la source de photos pour détecter les changements';

  @override
  String get appFolder => 'Dossier de l\'application';

  @override
  String get appFolderSubtitle =>
      'Photos stockées dans le dossier de l\'application';

  @override
  String get appFolderWarning =>
      'Copiez les photos dans ce dossier. Elles seront supprimées lors de la désinstallation de l\'application.';

  @override
  String get devicePhotos => 'Photos de l\'appareil';

  @override
  String get devicePhotosSubtitle => 'Afficher les photos de votre appareil';

  @override
  String get localFolder => 'Dossier local';

  @override
  String get localFolderSubtitle => 'Utiliser les photos d\'un dossier local';

  @override
  String get nextcloud => 'Nextcloud';

  @override
  String get nextcloudSubtitle =>
      'Synchroniser depuis un lien de partage public Nextcloud';

  @override
  String get loading => 'Chargement...';

  @override
  String get loadingAlbums => 'Chargement des albums...';

  @override
  String get tapToLoadAlbums =>
      'Touchez pour charger les albums photo de l\'appareil';

  @override
  String get load => 'Charger';

  @override
  String get photoAlbum => 'Album photo';

  @override
  String get allPhotos => 'Toutes les photos';

  @override
  String get refreshAlbums => 'Actualiser les albums';

  @override
  String get change => 'Modifier';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get photoPermissionDenied => 'Autorisation photo refusée';

  @override
  String errorLoadingAlbums(String error) {
    return 'Erreur de chargement des albums : $error';
  }

  @override
  String failedToPickFolder(String error) {
    return 'Échec de la sélection du dossier : $error';
  }

  @override
  String get selectPhotoFolder => 'Sélectionner le dossier photo';

  @override
  String get nextcloudPublicShareUrl => 'Lien de partage public Nextcloud';

  @override
  String get nextcloudUrlHint => 'https://cloud.example.com/s/abc123';

  @override
  String get webdavAuthPublicShare => 'Partage public';

  @override
  String get webdavAuthLogin => 'Connexion WebDAV';

  @override
  String get webdavUrlLabel => 'URL WebDAV';

  @override
  String get webdavUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/user/';

  @override
  String get webdavUsername => 'Nom d\'utilisateur';

  @override
  String get webdavPassword => 'Mot de passe';

  @override
  String get webdavAllowInvalidCertificate => 'Accepter un certificat invalide';

  @override
  String get webdavAllowInvalidCertificateWarning =>
      'Non sécurisé : uniquement pour les certificats auto-signés sur des réseaux de confiance.';

  @override
  String get testConnection => 'Tester la connexion';

  @override
  String get testing => 'Test en cours...';

  @override
  String get connectionSuccessful => 'Connexion réussie !';

  @override
  String get syncAllNextcloudFolders => 'Tous les dossiers';

  @override
  String get syncAllNextcloudFoldersSubtitle =>
      'Synchroniser les images de la racine du partage et de chaque sous-dossier';

  @override
  String get syncSelectedNextcloudFolders => 'Dossiers sélectionnés';

  @override
  String get syncSelectedNextcloudFoldersSubtitle =>
      'Choisir les dossiers dont les images directes doivent être utilisées';

  @override
  String get loadNextcloudFolders => 'Charger les dossiers';

  @override
  String get loadingNextcloudFolders => 'Chargement des dossiers...';

  @override
  String get nextcloudFolderSelectionHint =>
      'Sélectionnez la racine du partage et les sous-dossiers à inclure.';

  @override
  String get nextcloudShareRoot => 'Racine du partage';

  @override
  String get nextcloudShareRootSubtitle =>
      'Images directement dans le dossier racine partagé';

  @override
  String nextcloudFolderPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String nextcloudFoldersLoadError(String error) {
    return 'Erreur de chargement des dossiers : $error';
  }

  @override
  String get autoSyncInterval => 'Intervalle de synchronisation';

  @override
  String get disabled => 'Désactivé';

  @override
  String get deleteOrphanedFiles => 'Supprimer les fichiers orphelins';

  @override
  String get deleteOrphanedFilesSubtitle =>
      'Supprimer les fichiers locaux qui ne sont plus sur le serveur';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncing => 'Synchronisation...';

  @override
  String get syncCompletedSuccessfully => 'Synchronisation terminée !';

  @override
  String get syncCancelled => 'Synchronisation annulée.';

  @override
  String syncError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get nextcloudErrorInvalidShareLink =>
      'Le lien de partage Nextcloud n\'est plus valide.';

  @override
  String get nextcloudErrorShareInaccessible =>
      'Le partage Nextcloud n\'est plus accessible.';

  @override
  String get nextcloudErrorConnectionTimeout =>
      'La connexion à Nextcloud a expiré.';

  @override
  String get nextcloudErrorConnectionFailed =>
      'Impossible de se connecter à Nextcloud. Vérifiez la connexion Internet et le lien de partage.';

  @override
  String get nextcloudErrorDownloadStalled =>
      'Le téléchargement a expiré après 15 minutes sans recevoir de données.';

  @override
  String get nextcloudErrorInvalidUrlEmpty => 'L\'URL est vide.';

  @override
  String get nextcloudErrorInvalidUrlScheme =>
      'Schéma d\'URL invalide. Utilisez http ou https.';

  @override
  String get nextcloudErrorInvalidUrlNoHost =>
      'URL invalide. L\'hôte est manquant.';

  @override
  String nextcloudErrorInvalidUrlFormat(String error) {
    return 'Format d\'URL invalide : $error';
  }

  @override
  String nextcloudErrorUnknown(String error) {
    return 'Échec de la synchronisation Nextcloud : $error';
  }

  @override
  String get neverSynced => 'Jamais synchronisé';

  @override
  String get lastSyncJustNow => 'Dernière synchronisation : à l\'instant';

  @override
  String lastSyncMinutesAgo(int minutes) {
    return 'Dernière synchronisation : il y a $minutes min';
  }

  @override
  String lastSyncHoursAgo(int hours) {
    return 'Dernière synchronisation : il y a $hours h';
  }

  @override
  String lastSyncDate(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get sectionDisplaySchedule => 'Horaire d\'affichage';

  @override
  String get dayNightSchedule => 'Horaire jour/nuit';

  @override
  String get dayNightScheduleSubtitle => 'Éteindre l\'écran la nuit';

  @override
  String get dayStartsAt => 'Le jour commence à';

  @override
  String get nightStartsAt => 'La nuit commence à';

  @override
  String get differentNightTimeOnFridaysAndSaturdays =>
      'Heure de nuit différente le vendredi et le samedi';

  @override
  String get differentNightTimeFridaysAndSaturdays =>
      'La nuit commence le vendredi et le samedi à';

  @override
  String get nativeScreenOff => 'Extinction native de l\'écran';

  @override
  String get nativeScreenOffEnabledSubtitle =>
      'Utiliser le profil d\'administrateur de l\'appareil pour éteindre complètement l\'écran';

  @override
  String get nativeScreenOffDisabledSubtitle =>
      'Nécessite l\'autorisation d\'administrateur d\'appareil';

  @override
  String get deviceAdminExplanation =>
      'L\'autorisation d\'administrateur d\'appareil est nécessaire pour éteindre complètement l\'écran. Sans elle, l\'écran sera seulement atténué.';

  @override
  String get grantDeviceAdmin => 'Accorder l\'administrateur d\'appareil';

  @override
  String get deviceAdminEnabled =>
      'Administrateur d\'appareil activé - l\'écran s\'éteindra complètement';

  @override
  String get screenLockWarning =>
      'Important : le verrouillage de l\'écran (code PIN / schéma / mot de passe) doit être désactivé pour que le réveil automatique fonctionne. Allez dans Paramètres → Sécurité → Verrouillage de l\'écran → Aucun.';

  @override
  String get deviceAdminActive => 'Administrateur d\'appareil actif';

  @override
  String get deviceAdminUninstallWarning =>
      'Pour désinstaller cette application, vous devez d\'abord désactiver l\'autorisation d\'administrateur d\'appareil dans les paramètres Android.';

  @override
  String get openDeviceAdminSettings =>
      'Ouvrir les paramètres d\'administrateur d\'appareil';

  @override
  String get sectionAndroid => 'Android';

  @override
  String get startOnBoot => 'Démarrer au démarrage';

  @override
  String get startOnBootSubtitle =>
      'Démarrer automatiquement l\'application au démarrage de l\'appareil';

  @override
  String get keepAppRunning => 'Garder l\'application active';

  @override
  String get keepAppRunningSubtitle =>
      'Empêcher l\'arrêt de l\'application en cas de manque de mémoire';

  @override
  String get notificationPermissionRequired =>
      'L\'autorisation de notification est requise pour Garder l\'application active';

  @override
  String get autoUpdateTitle => 'Mises à jour automatiques';

  @override
  String get autoUpdateSubtitle =>
      'Vérifier GitHub pour de nouvelles versions et les installer';

  @override
  String get autoUpdateFdroidNote =>
      'Réservé aux installations depuis GitHub. Si vous avez installé via F-Droid, laissez cette option désactivée et mettez à jour via F-Droid.';

  @override
  String get autoUpdateSilentTitle => 'Installer sans confirmation';

  @override
  String get autoUpdateSilentSubtitle =>
      'Propriétaire de l\'appareil détecté : les mises à jour peuvent être installées silencieusement en arrière-plan.';

  @override
  String get autoUpdatePromptNote =>
      'Lorsqu\'une mise à jour est disponible, elle vous sera proposée avant l\'installation.';

  @override
  String get autoUpdateCheckNow => 'Vérifier maintenant';

  @override
  String get autoUpdateUpToDate => 'Vous êtes à jour.';

  @override
  String get updateAvailableTitle => 'Mise à jour disponible';

  @override
  String updateAvailableMessage(String version) {
    return 'La version $version est disponible. La télécharger et l\'installer maintenant ?';
  }

  @override
  String get updateDownloading => 'Téléchargement…';

  @override
  String get updateSkip => 'Ignorer';

  @override
  String get updateDownloadInstall => 'Télécharger et installer';

  @override
  String get keepAliveDialogTitle => 'Garder l\'application active';

  @override
  String get keepAliveWhatDoes => 'Que fait cette option ?';

  @override
  String get keepAliveWhatDoesExplanation =>
      'Cette option garde l\'application de cadre photo active en continu, même lorsque l\'appareil manque de mémoire.';

  @override
  String get keepAliveWhyNeed => 'Pourquoi en aurais-je besoin ?';

  @override
  String get keepAliveWhyNeedExplanation =>
      'Sur les appareils anciens à mémoire limitée, Android peut arrêter l\'application pour libérer de la mémoire. Cette option l\'empêche en la faisant tourner comme service de premier plan.';

  @override
  String get keepAliveWhatHappens => 'Que va-t-il se passer ?';

  @override
  String get keepAliveWhatHappensExplanation =>
      '• Une petite notification apparaîtra dans la barre d\'état\n• L\'application aura moins de chances d\'être arrêtée par Android\n• Sur Android 13+, vous devrez accorder l\'autorisation de notification';

  @override
  String get keepAliveDisableAnytime =>
      'Vous pouvez la désactiver à tout moment depuis les paramètres.';

  @override
  String get cancel => 'Annuler';

  @override
  String get enable => 'Activer';

  @override
  String get about => 'À propos';

  @override
  String aboutSubtitle(String version) {
    return 'LibrePhotoFrame v$version';
  }

  @override
  String get noPhotosFound => 'Aucune photo trouvée';

  @override
  String get tapCenterToOpenSettings =>
      'Touchez le centre de l\'écran pour ouvrir les paramètres';

  @override
  String get screenOrientation => 'Orientation de l\'écran';

  @override
  String get screenOrientationAuto => 'Automatique (capteur)';

  @override
  String get screenOrientationPortraitUp => 'Portrait';

  @override
  String get screenOrientationPortraitDown => 'Portrait (à l\'envers)';

  @override
  String get screenOrientationLandscapeLeft => 'Paysage (gauche)';

  @override
  String get screenOrientationLandscapeRight => 'Paysage (droite)';
}
