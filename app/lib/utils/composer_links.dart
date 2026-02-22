Uri? composerUriForPlatform({
  required String platform,
  required String text,
}) {
  final normalized = platform.toLowerCase();
  if (normalized == 'x') {
    return Uri.https('twitter.com', '/intent/tweet', {'text': text});
  }
  if (normalized == 'linkedin') {
    return Uri.https('www.linkedin.com', '/feed/');
  }
  if (normalized == 'reddit') {
    var title = text
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => 'Post idea');
    if (title.length > 120) {
      title = title.substring(0, 120);
    }
    return Uri.https('www.reddit.com', '/submit', {
      'selftext': 'true',
      'title': title,
      'text': text,
    });
  }
  if (normalized == 'facebook') {
    return Uri.https('www.facebook.com', '/');
  }
  if (normalized == 'youtube') {
    return Uri.https('studio.youtube.com', '/');
  }
  return null;
}
