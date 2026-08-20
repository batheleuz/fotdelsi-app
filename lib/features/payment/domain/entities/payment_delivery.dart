/// Comment la demande de paiement d'un dépôt atteint le payeur.
///
/// Nommé d'après la SITUATION, pas d'après le mécanisme : c'est la présence du
/// client qui décide, et le jour où le canal changera ce nom restera juste.
enum PaymentDelivery {
  /// Le client n'est pas là — il a envoyé quelqu'un déposer son linge. La
  /// demande lui est poussée (notification si l'application est liée, sinon
  /// SMS) et il paie depuis son téléphone.
  notify,

  /// Le client est devant l'agent. Rien ne lui est envoyé : l'agent tourne son
  /// écran et lui montre le QR de paiement, comme pour une vente au comptoir.
  onSite;

  String get apiValue => switch (this) {
    PaymentDelivery.notify => 'NOTIFY',
    PaymentDelivery.onSite => 'ON_SITE',
  };
}
