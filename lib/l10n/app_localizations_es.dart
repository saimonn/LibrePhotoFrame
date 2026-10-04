// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get sectionSlideshow => 'Presentación';

  @override
  String get slideDuration => 'Duración de la diapositiva';

  @override
  String get transitionDuration => 'Duración de la transición';

  @override
  String get blurBorders => 'Difuminar los bordes';

  @override
  String get blurBordersSubtitle =>
      'Ampliar la imagen al tamaño de la pantalla';

  @override
  String get pairPhotos => 'Pantalla dividida';

  @override
  String get pairPhotosSubtitle =>
      'Mostrar dos fotos a la vez cuando coinciden con la forma de la pantalla';

  @override
  String get photoOrder => 'Ordenar fotos por…';

  @override
  String get photoOrderRandom => 'Orden aleatorio';

  @override
  String get photoOrderExif => 'Por fecha de captura (EXIF)';

  @override
  String get photoOrderCreation => 'Por fecha de creación del archivo';

  @override
  String get photoOrderModification => 'Por fecha de modificación del archivo';

  @override
  String get unitMinutes => 'min';

  @override
  String get unitSeconds => 's';

  @override
  String get sectionClock => 'Reloj';

  @override
  String get showClock => 'Mostrar el reloj';

  @override
  String get showClockSubtitle => 'Mostrar la hora en la presentación';

  @override
  String get size => 'Tamaño';

  @override
  String get position => 'Posición';

  @override
  String get clockFormat => 'Formato de la hora';

  @override
  String get clockFormatAuto => 'Automático';

  @override
  String get clockFormat12 => '12 horas';

  @override
  String get clockFormat24 => '24 horas';

  @override
  String get sectionPhotoInfo => 'Información de la foto';

  @override
  String get showPhotoInfo => 'Mostrar información de la foto';

  @override
  String get showPhotoInfoSubtitle =>
      'Mostrar la fecha y el lugar en la presentación';

  @override
  String get useScriptFont => 'Fuente manuscrita';

  @override
  String get useScriptFontSubtitle =>
      'Mostrar los metadatos con un estilo manuscrito elegante';

  @override
  String get resolveLocationNames => 'Resolver nombres de lugares';

  @override
  String get resolveLocationNamesSubtitle =>
      'Usar OpenStreetMap para mostrar nombres de lugar en lugar de coordenadas';

  @override
  String get nominatimHint =>
      'Usa Nominatim (OpenStreetMap). No se necesita clave de API.';

  @override
  String get sectionPhotoSource => 'Origen de las fotos';

  @override
  String get watchPhotoFolder => 'Vigilando la carpeta';

  @override
  String get watchPhotoFolderSubtitle =>
      'Detectar automáticamente las fotos nuevas y borradas de la carpeta';

  @override
  String get appFolder => 'Carpeta de la aplicación';

  @override
  String get appFolderSubtitle =>
      'Fotos guardadas en la carpeta de la aplicación';

  @override
  String get appFolderWarning =>
      'Copia las fotos a esta carpeta. Se eliminarán al desinstalar la aplicación.';

  @override
  String get devicePhotos => 'Fotos del dispositivo';

  @override
  String get devicePhotosSubtitle => 'Mostrar las fotos de tu dispositivo';

  @override
  String get localFolder => 'Carpeta local';

  @override
  String get localFolderSubtitle => 'Usar las fotos de una carpeta local';

  @override
  String get nextcloud => 'Nextcloud';

  @override
  String get nextcloudSubtitle =>
      'Sincronizar desde un enlace público de Nextcloud';

  @override
  String get loading => 'Cargando...';

  @override
  String get loadingAlbums => 'Cargando álbumes...';

  @override
  String get tapToLoadAlbums =>
      'Toca para cargar los álbumes de fotos del dispositivo';

  @override
  String get load => 'Cargar';

  @override
  String get photoAlbum => 'Álbum de fotos';

  @override
  String get allPhotos => 'Todas las fotos';

  @override
  String get refreshAlbums => 'Actualizar álbumes';

  @override
  String get change => 'Cambiar';

  @override
  String get reset => 'Restablecer';

  @override
  String get photoPermissionDenied => 'Permiso de fotos denegado';

  @override
  String errorLoadingAlbums(String error) {
    return 'Error al cargar los álbumes: $error';
  }

  @override
  String failedToPickFolder(String error) {
    return 'No se pudo elegir la carpeta: $error';
  }

  @override
  String get selectPhotoFolder => 'Seleccionar la carpeta de fotos';

  @override
  String get nextcloudPublicShareUrl => 'Enlace público de Nextcloud';

  @override
  String get nextcloudUrlHint => 'https://cloud.example.com/s/abc123';

  @override
  String get webdavAuthPublicShare => 'Enlace público';

  @override
  String get webdavAuthLogin => 'Inicio de sesión WebDAV';

  @override
  String get webdavUrlLabel => 'URL de WebDAV';

  @override
  String get webdavUrlHint =>
      'https://cloud.example.com/remote.php/dav/files/user/';

  @override
  String get webdavUsername => 'Nombre de usuario';

  @override
  String get webdavPassword => 'Contraseña';

  @override
  String get webdavAllowInvalidCertificate => 'Aceptar certificado no válido';

  @override
  String get webdavAllowInvalidCertificateWarning =>
      'Inseguro: solo para certificados autofirmados en redes de confianza.';

  @override
  String get testConnection => 'Probar la conexión';

  @override
  String get testing => 'Probando...';

  @override
  String get connectionSuccessful => '¡Conexión correcta!';

  @override
  String get syncAllNextcloudFolders => 'Todas las carpetas';

  @override
  String get syncAllNextcloudFoldersSubtitle =>
      'Sincronizar las imágenes de la raíz del enlace y de cada subcarpeta';

  @override
  String get syncSelectedNextcloudFolders => 'Carpetas seleccionadas';

  @override
  String get syncSelectedNextcloudFoldersSubtitle =>
      'Elegir las carpetas cuyas imágenes directas se deben usar';

  @override
  String get loadNextcloudFolders => 'Cargar carpetas';

  @override
  String get loadingNextcloudFolders => 'Cargando carpetas...';

  @override
  String get nextcloudFolderSelectionHint =>
      'Selecciona la raíz del enlace y las subcarpetas que quieras incluir.';

  @override
  String get nextcloudShareRoot => 'Raíz del enlace';

  @override
  String get nextcloudShareRootSubtitle =>
      'Imágenes directamente en la carpeta raíz compartida';

  @override
  String nextcloudFolderPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotos',
      one: '1 foto',
    );
    return '$_temp0';
  }

  @override
  String nextcloudFoldersLoadError(String error) {
    return 'Error al cargar las carpetas: $error';
  }

  @override
  String get autoSyncInterval => 'Intervalo de sincronización automática';

  @override
  String get disabled => 'Desactivado';

  @override
  String get deleteOrphanedFiles => 'Eliminar archivos huérfanos';

  @override
  String get deleteOrphanedFilesSubtitle =>
      'Eliminar los archivos locales que ya no están en el servidor';

  @override
  String get syncNow => 'Sincronizar ahora';

  @override
  String get syncing => 'Sincronizando...';

  @override
  String get syncCompletedSuccessfully => '¡Sincronización completada!';

  @override
  String get syncCancelled => 'Sincronización cancelada.';

  @override
  String syncError(String error) {
    return 'Error: $error';
  }

  @override
  String get nextcloudErrorInvalidShareLink =>
      'El enlace de Nextcloud ya no es válido.';

  @override
  String get nextcloudErrorShareInaccessible =>
      'El enlace de Nextcloud ya no es accesible.';

  @override
  String get nextcloudErrorConnectionTimeout =>
      'La conexión con Nextcloud ha agotado el tiempo de espera.';

  @override
  String get nextcloudErrorConnectionFailed =>
      'No se pudo conectar con Nextcloud. Comprueba la conexión a internet y el enlace.';

  @override
  String get nextcloudErrorDownloadStalled =>
      'La descarga ha agotado el tiempo de espera tras 15 minutos sin recibir datos.';

  @override
  String get nextcloudErrorInvalidUrlEmpty => 'La URL está vacía.';

  @override
  String get nextcloudErrorInvalidUrlScheme =>
      'Esquema de URL no válido. Usa http o https.';

  @override
  String get nextcloudErrorInvalidUrlNoHost => 'URL no válida. Falta el host.';

  @override
  String nextcloudErrorInvalidUrlFormat(String error) {
    return 'Formato de URL no válido: $error';
  }

  @override
  String nextcloudErrorUnknown(String error) {
    return 'Error de sincronización de Nextcloud: $error';
  }

  @override
  String get neverSynced => 'Nunca sincronizado';

  @override
  String get lastSyncJustNow => 'Última sincronización: ahora mismo';

  @override
  String lastSyncMinutesAgo(int minutes) {
    return 'Última sincronización: hace $minutes min';
  }

  @override
  String lastSyncHoursAgo(int hours) {
    return 'Última sincronización: hace $hours h';
  }

  @override
  String lastSyncDate(String date) {
    return 'Última sincronización: $date';
  }

  @override
  String get sectionDisplaySchedule => 'Horario de pantalla';

  @override
  String get dayNightSchedule => 'Horario día/noche';

  @override
  String get dayNightScheduleSubtitle => 'Apagar la pantalla por la noche';

  @override
  String get dayStartsAt => 'El día empieza a las';

  @override
  String get nightStartsAt => 'La noche empieza a las';

  @override
  String get differentNightTimeOnFridaysAndSaturdays =>
      'Hora nocturna distinta los viernes y sábados';

  @override
  String get differentNightTimeFridaysAndSaturdays =>
      'La noche empieza los viernes y sábados a las';

  @override
  String get nativeScreenOff => 'Apagado nativo de la pantalla';

  @override
  String get nativeScreenOffEnabledSubtitle =>
      'Usar el administrador del dispositivo para apagar la pantalla por completo';

  @override
  String get nativeScreenOffDisabledSubtitle =>
      'Requiere permiso de administrador del dispositivo';

  @override
  String get deviceAdminExplanation =>
      'Se necesita el permiso de administrador del dispositivo para apagar la pantalla por completo. Sin él, la pantalla solo se atenuará.';

  @override
  String get grantDeviceAdmin => 'Conceder administrador del dispositivo';

  @override
  String get deviceAdminEnabled =>
      'Administrador del dispositivo activado: la pantalla se apagará por completo';

  @override
  String get screenLockWarning =>
      'Importante: el bloqueo de pantalla (PIN/patrón/contraseña) debe estar desactivado para que el despertar automático funcione. Ve a Ajustes → Seguridad → Bloqueo de pantalla → Ninguno.';

  @override
  String get deviceAdminActive => 'Administrador del dispositivo activo';

  @override
  String get deviceAdminUninstallWarning =>
      'Para desinstalar esta aplicación, desactiva primero el permiso de administrador del dispositivo en los ajustes de Android.';

  @override
  String get openDeviceAdminSettings =>
      'Abrir los ajustes de administrador del dispositivo';

  @override
  String get sectionAndroid => 'Android';

  @override
  String get startOnBoot => 'Iniciar al arrancar';

  @override
  String get startOnBootSubtitle =>
      'Iniciar la aplicación automáticamente al encender el dispositivo';

  @override
  String get keepAppRunning => 'Mantener la aplicación activa';

  @override
  String get keepAppRunningSubtitle =>
      'Evitar que la aplicación se detenga cuando falte memoria';

  @override
  String get notificationPermissionRequired =>
      'Se necesita el permiso de notificaciones para Mantener la aplicación activa';

  @override
  String get autoUpdateTitle => 'Actualizaciones automáticas';

  @override
  String get autoUpdateSubtitle =>
      'Buscar nuevas versiones en GitHub e instalarlas';

  @override
  String get autoUpdateFdroidNote =>
      'Solo para instalaciones desde GitHub. Si la instalaste desde F-Droid, deja esto desactivado y actualiza desde F-Droid.';

  @override
  String get autoUpdateSilentTitle => 'Instalar sin confirmación';

  @override
  String get autoUpdateSilentSubtitle =>
      'Propietario del dispositivo detectado: las actualizaciones se pueden instalar en segundo plano sin confirmación.';

  @override
  String get autoUpdatePromptNote =>
      'Cuando haya una actualización disponible, se te preguntará antes de instalarla.';

  @override
  String get autoUpdateCheckNow => 'Comprobar ahora';

  @override
  String get autoUpdateUpToDate => 'Estás al día.';

  @override
  String get updateAvailableTitle => 'Actualización disponible';

  @override
  String updateAvailableMessage(String version) {
    return 'La versión $version está disponible. ¿Descargar e instalarla ahora?';
  }

  @override
  String get updateDownloading => 'Descargando…';

  @override
  String get updateSkip => 'Omitir';

  @override
  String get updateDownloadInstall => 'Descargar e instalar';

  @override
  String get keepAliveDialogTitle => 'Mantener la aplicación activa';

  @override
  String get keepAliveWhatDoes => '¿Qué hace esto?';

  @override
  String get keepAliveWhatDoesExplanation =>
      'Esta función mantiene la aplicación del marco de fotos activa de forma continua, incluso cuando al dispositivo le falta memoria.';

  @override
  String get keepAliveWhyNeed => '¿Por qué lo necesitaría?';

  @override
  String get keepAliveWhyNeedExplanation =>
      'En dispositivos antiguos con poca RAM, Android puede detener la aplicación para liberar memoria. Esto lo evita ejecutándola como servicio en primer plano.';

  @override
  String get keepAliveWhatHappens => '¿Qué va a pasar?';

  @override
  String get keepAliveWhatHappensExplanation =>
      '• Aparecerá una pequeña notificación en la barra de estado\n• La aplicación tendrá menos probabilidades de ser detenida por Android\n• En Android 13 o superior, tendrás que conceder el permiso de notificaciones';

  @override
  String get keepAliveDisableAnytime =>
      'Puedes desactivarlo en cualquier momento desde los ajustes.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get enable => 'Activar';

  @override
  String get about => 'Acerca de';

  @override
  String aboutSubtitle(String version) {
    return 'LibrePhotoFrame v$version';
  }

  @override
  String get noPhotosFound => 'No se han encontrado fotos';

  @override
  String get tapCenterToOpenSettings =>
      'Toca el centro de la pantalla para abrir los ajustes';

  @override
  String get screenOrientation => 'Orientación de la pantalla';

  @override
  String get screenOrientationAuto => 'Automática (sensor)';

  @override
  String get screenOrientationPortraitUp => 'Vertical';

  @override
  String get screenOrientationPortraitDown => 'Vertical (invertida)';

  @override
  String get screenOrientationLandscapeLeft => 'Horizontal (izquierda)';

  @override
  String get screenOrientationLandscapeRight => 'Horizontal (derecha)';
}
