/// Central contact details for the ATAA association.
/// Update these values when the official channels change.
class AssociationContact {
  AssociationContact._();

  static const String phoneDisplay = '+963 11 234 5678';
  static const String phoneDigits = '+963112345678';

  static const String email = 'info@ataa-charity.org';

  static const String instagramUsername = 'ataa.charity';
  static const String facebookPage = 'ataa.charity';
  static const String twitterUsername = 'ataa_charity';
  static const String telegramUsername = 'ataa_charity';

  static const String instagramApp =
      'instagram://user?username=$instagramUsername';
  static const String instagramWeb =
      'https://www.instagram.com/$instagramUsername/';

  static const String facebookWeb =
      'https://www.facebook.com/$facebookPage';
  static const String facebookApp =
      'fb://facewebmodal/f?href=https://www.facebook.com/$facebookPage';

  static const String twitterApp =
      'twitter://user?screen_name=$twitterUsername';
  static const String twitterWeb = 'https://twitter.com/$twitterUsername';

  static const String telegramApp = 'tg://resolve?domain=$telegramUsername';
  static const String telegramWeb = 'https://t.me/$telegramUsername';
}
