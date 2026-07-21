import 'package:flutter/material.dart';

import '../../../shared/widgets/back_arrow_icon.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const BackArrowIcon(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        children: const [
          _PolicyTitle('Privacy Policy: Catrin & Abi'),
          _PolicyMeta('Last Updated: May 21, 2026'),
          SizedBox(height: 20),

          _SectionHeader('1. About This Policy'),
          _Body(
            'Welcome to Catrin & Abi! We know that your privacy—and your '
            'child\'s privacy—is very important. This policy explains how we '
            'collect, use, and look after your information when you use our app '
            'at home or at school. We have designed this app with the ICO\'s '
            'Age Appropriate Design Code in mind, meaning we put the safety and '
            'best interests of children first.',
          ),

          _SectionHeader('2. Who Are We?'),
          _Body(
            '[Company Name] is the "data controller" for this app. If you have '
            'any questions or concerns, you can contact our Data Protection '
            'Officer (DPO) at:',
          ),
          _BulletItem('Email: [Privacy Email Address]'),
          _BulletItem('Address: [Company Postal Address]'),

          _SectionHeader('3. What Information Do We Collect?'),
          _Body(
            'We follow the principle of data minimisation. We only collect the '
            'information we absolutely need to provide our service.',
          ),
          _SubHeader('For Children:'),
          _Body(
            'We do not knowingly collect more information than is reasonably '
            'necessary for the app to function (e.g., game progress, avatar '
            'choices). We do not track location or use behavioural profiling.',
          ),
          _SubHeader('For Parents / Guardians / Teachers:'),
          _Body(
            'We may collect contact details (name and email) to manage accounts, '
            'send progress reports, or provide parental/teacher controls.',
          ),

          _SectionHeader('4. How We Use Your Data'),
          _BulletItem(
            'To provide the service: Operating the app, saving game progress, '
            'and enabling educational features.',
          ),
          _BulletItem(
            'For safety: Monitoring for technical issues to ensure the app is secure.',
          ),
          _BulletItem(
            'Communication: We will only contact parents or teachers regarding '
            'account management, policy updates, or service-critical information. '
            'We do not use children\'s data for marketing or advertising purposes.',
          ),

          _SectionHeader('5. Sharing Information'),
          _Body(
            'We do not sell your personal data. We only share information with '
            'third-party service providers (such as cloud hosting) if they are '
            'strictly necessary to run the app. These providers are contractually '
            'obligated to keep your data secure and follow our privacy standards.',
          ),

          _SectionHeader('6. Privacy for Children (Age 5–11)'),
          _Body('We have made sure our app is safe for you.'),
          _BulletItem('No Tracking: We do not track where you are (geolocation is switched off).'),
          _BulletItem(
            'No Nudges: We do not use tricks or "nudge" techniques to make you '
            'spend more time in the app or give us more information.',
          ),
          _BulletItem(
            'High Privacy by Default: Your settings are automatically set to '
            'the highest level of privacy when you start using the app.',
          ),

          _SectionHeader('7. Parental and Teacher Controls'),
          _Body(
            'Parents and teachers have full control over the data. '
            'You have the right to:',
          ),
          _BulletItem('Access: See what information we hold about you or your child.'),
          _BulletItem('Correction: Fix any information that is wrong.'),
          _BulletItem('Erasure: Ask us to delete your child\'s data at any time.'),
          _BulletItem(
            'Withdraw Consent: If we rely on your consent to process data, '
            'you can withdraw it at any time by contacting us at [Privacy Email].',
          ),
          _Body(
            'To exercise these rights, please email us at [Privacy Email Address] '
            'with the subject line "Privacy Request."',
          ),

          _SectionHeader('8. Data Security'),
          _Body(
            'We use industry-standard encryption and security measures to protect '
            'data from unauthorised access, loss, or misuse. We only keep data '
            'for as long as it is needed to provide the service or as required by '
            'law. Once no longer needed, it is securely deleted.',
          ),

          _SectionHeader('9. Changes to This Policy'),
          _Body(
            'If we make any big changes to how we use data, we will notify parents '
            'and teachers via email and update the date at the top of this policy.',
          ),

          SizedBox(height: 28),
          _Divider(),
          SizedBox(height: 16),

          _SubHeader('Guidance for Implementation'),
          _BulletItem(
            'Clear Language: The ICO expects the policy to be accessible. '
            'Consider creating a "Child-Friendly Version" (e.g., a one-page '
            'infographic or video) that explains these points in simple, '
            'age-appropriate language for the 5–11 age group.',
          ),
          _BulletItem(
            'Parental Consent: Since your users are under 13, ensure you have '
            'a robust mechanism to obtain verifiable parental consent before '
            'processing personal data.',
          ),
          _BulletItem(
            'DPIA: Remember that the ICO requires a Data Protection Impact '
            'Assessment for any service likely to be accessed by children to '
            'identify and mitigate risks.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Local text widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PolicyTitle extends StatelessWidget {
  final String text;
  const _PolicyTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A237E),
        ),
      );
}

class _PolicyMeta extends StatelessWidget {
  final String text;
  const _PolicyMeta(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'ComicRelief',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
      );
}

class _SubHeader extends StatelessWidget {
  final String text;
  const _SubHeader(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      );
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade800,
          ),
        ),
      );
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 12, bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF1A237E),
                ),
              ),
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
        color: const Color(0xFF1A237E).withValues(alpha: 0.25),
        thickness: 1,
      );
}
