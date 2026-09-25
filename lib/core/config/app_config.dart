/// App-wide feature flags that get flipped deliberately at a milestone
/// (e.g. store submission), as opposed to per-environment build config.
class AppConfig {
  const AppConfig._();

  /// When true, only Hwb (school) sign-in is offered on the Profile screen
  /// and any non-Hwb email account is signed out automatically. Leave false
  /// during development so testers can sign in with any email address via
  /// the OTP flow.
  ///
  /// Flip to true once Hwb sign-in has been verified end-to-end, before
  /// submitting to the App Store / Play Store.
  static const bool hwbOnlyLogin = false;

  /// Email domains that count as a valid Hwb account, checked against the
  /// part of the address after '@' (matches the domain itself or any
  /// subdomain, e.g. a local authority's "sirgar.hwbcymru.net").
  static const List<String> hwbEmailDomains = ['hwbcymru.net'];
}
