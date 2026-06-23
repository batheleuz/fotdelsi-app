/// Formatage relatif en français à partir de l'heure locale du téléphone.
/// Ex. « à l'instant », « il y a 12 min », « il y a 3 h », « il y a 2 j ».
String relativeTimeFr(DateTime from, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(from);
  if (diff.inSeconds < 60) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return 'il y a ${diff.inDays} j';
}
