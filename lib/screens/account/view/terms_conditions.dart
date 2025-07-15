
import 'package:arabicmarketplace/utills/AppLocalizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class TermsConditionsPage extends StatefulWidget {
  final bool requireAcceptance;
  final VoidCallback? onAccepted;

  const TermsConditionsPage({
    Key? key,
    this.requireAcceptance = false,
    this.onAccepted,
  }) : super(key: key);

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage> with TickerProviderStateMixin {
  late TabController _tabController;

  bool hasAcceptedTerms = false;
  bool isAccepting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: context.locale.languageCode == 'ar'
              ? GoogleFonts.cairo(fontSize: 14, color: Colors.white)
              : GoogleFonts.poppins(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _acceptTerms() async {
    setState(() => isAccepting = true);

    try {
      // Simulate acceptance process
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        hasAcceptedTerms = true;
        isAccepting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.locale.languageCode == 'ar' ? 'تم قبول الشروط بنجاح' : 'Terms accepted successfully',
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(fontSize: 14, color: Colors.white)
                : GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0D5E2A),
        ),
      );

      if (widget.onAccepted != null) {
        widget.onAccepted!();
      }

      if (widget.requireAcceptance) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => isAccepting = false);
      _showErrorSnackBar(context.locale.languageCode == 'ar' ? 'فشل في قبول الشروط' : 'Failed to accept terms');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: widget.requireAcceptance
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onBackground, size: 20),
              ),
        title: Text(
          context.locale.languageCode == 'ar' ? 'ديّلوني - الوثائق القانونية' : 'Deeloni - Legal Documents',
          style: context.locale.languageCode == 'ar'
              ? GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                )
              : GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelStyle: context.locale.languageCode == 'ar'
              ? GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w600)
              : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: context.locale.languageCode == 'ar'
              ? GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w400)
              : GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400),
          tabs: [
            Tab(text: context.locale.languageCode == 'ar' ? 'الشروط والأحكام' : 'Terms & Conditions'),
            Tab(text: context.locale.languageCode == 'ar' ? 'سياسة الخصوصية' : 'Privacy Policy'),
          ],
        ),
      ),
      body: Directionality(
        textDirection: context.locale.languageCode == 'ar' ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTermsTab(),
                  _buildPrivacyTab(),
                ],
              ),
            ),
            if (widget.requireAcceptance && !hasAcceptedTerms)
              _buildAcceptanceSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildDocumentHeader(
            title: context.locale.languageCode == 'ar' ? 'ديّلوني - الشروط والأحكام' : 'Deeloni - Terms & Conditions',
            effectiveDate: context.locale.languageCode == 'ar'
                ? 'تاريخ السريان: 01 يوليو 2025'
                : 'Effective Date: July 01, 2025',
          ),
          const SizedBox(height: 24),
          // Content
          _buildTermsContent(),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildDocumentHeader(
            title: context.locale.languageCode == 'ar' ? 'ديّلوني - سياسة الخصوصية' : 'Deeloni - Privacy Policy',
            effectiveDate: context.locale.languageCode == 'ar'
                ? 'تاريخ السريان: 01 يوليو 2025'
                : 'Effective Date: July 01, 2025',
          ),
          const SizedBox(height: 24),
          // Content
          _buildPrivacyContent(),
        ],
      ),
    );
  }

  Widget _buildDocumentHeader({required String title, required String effectiveDate}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5E2A), Color(0xFF1A7037)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )
                : GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            effectiveDate,
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  )
                : GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الأهلية' : 'Eligibility',
          content: context.locale.languageCode == 'ar'
              ? 'باستخدامك لمنصة ديّلوني، فإنك تؤكد أنك مسموح لك قانونيًا باستخدام المنصات الإلكترونية في بلدك.'
              : 'By using Deeloni, you confirm that you are legally allowed to use online platforms in your country.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الحساب والتسجيل' : 'Account & Registration',
          content: context.locale.languageCode == 'ar'
              ? 'قد يُطلب منك إنشاء حساب لنشر الإعلانات أو التفاعل مع المستخدمين الآخرين. أنت توافق على تقديم معلومات دقيقة والحفاظ على أمان معلومات الدخول الخاصة بك.'
              : 'To post ads or interact with other users, you may be required to create an account. You agree to provide accurate information and keep your login details secure.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'المحتوى المنشور من قبل المستخدم' : 'User-Posted Content',
          content: context.locale.languageCode == 'ar'
              ? 'أنت مسؤول وحدك عن المحتوى الذي تنشره، بما في ذلك دقته وقانونيته وملاءمته. نحتفظ بالحق في إزالة أي محتوى ينتهك قواعدنا أو قوانين الجمهورية العربية السورية.'
              : 'You are solely responsible for the content you post. This includes the accuracy, legality, and appropriateness of your listings. We reserve the right to remove any content that violates our rules or Syrian law.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الإعلانات المحظورة' : 'Prohibited Listings',
          content: context.locale.languageCode == 'ar'
              ? 'لا يجوز لك نشر محتوى أو إعلانات تروج لسلع أو خدمات غير قانونية، أو تنتهك القوانين السورية، أو تحتوي على خطاب كراهية أو تحرّش أو معلومات مضللة.'
              : 'You may not post content or listings that promote illegal goods or services, violate Syrian laws, or include hate speech, harassment, or misleading information.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الرسوم' : 'Fees',
          content: context.locale.languageCode == 'ar'
              ? 'قد تتطلب بعض الميزات أو الفئات دفع رسوم. سيتم عرض أي رسوم بوضوح، وهي غير قابلة للاسترداد بمجرد نشر الإعلان.'
              : 'Some features or categories may require payment. Any fees will be clearly displayed and are non-refundable once the ad goes live.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'إخلاء المسؤولية' : 'Disclaimer',
          content: context.locale.languageCode == 'ar'
              ? 'ديّلوني هو منصة للإعلانات فقط. لا نشارك في أي معاملات، ولا نتحقق من المستخدمين أو من صحة الإعلانات. استخدم الموقع بحذر وحكمة.'
              : 'Deeloni is a listing platform. We do not take part in any transaction, nor do we verify users or the accuracy of listings. Use caution and common sense when interacting with others.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'تحديد المسؤولية' : 'Limitation of Liability',
          content: context.locale.languageCode == 'ar'
              ? 'نحن غير مسؤولين عن أي خسائر أو أضرار ناتجة عن استخدامك لديّلوني. استخدامك للمنصة يكون على مسؤوليتك الخاصة.'
              : 'We are not responsible for any loss or damage resulting from your use of Deeloni. You use the platform at your own risk.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الإنهاء' : 'Termination',
          content: context.locale.languageCode == 'ar'
              ? 'نحتفظ بالحق في تعليق أو حذف الحسابات التي تنتهك هذه الشروط أو سياسات المحتوى لدينا.'
              : 'We reserve the right to suspend or delete accounts that violate these terms or our content guidelines.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'التعديلات' : 'Changes to Terms',
          content: context.locale.languageCode == 'ar'
              ? 'قد يتم تحديث هذه الشروط. استمرار استخدامك لديّلوني بعد التحديثات يُعتبر موافقة منك على التعديلات.'
              : 'These Terms may be updated. Continued use of Deeloni after updates constitutes your acceptance of the changes.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'القانون المعمول به' : 'Governing Law',
          content: context.locale.languageCode == 'ar'
              ? 'تخضع هذه الشروط لقوانين الجمهورية العربية السورية.'
              : 'These Terms are governed by the laws of the Syrian Arab Republic.',
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'المعلومات التي نجمعها' : 'Information We Collect',
          content: context.locale.languageCode == 'ar'
              ? 'قد نجمع اسمك، بريدك الإلكتروني، رقم هاتفك، موقعك، عنوان IP، معلومات المتصفح/الجهاز، ومحتوى الإعلانات.'
              : 'We may collect your name, email address, phone number, location, IP address, browser/device info, and ad content.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'كيفية استخدام المعلومات' : 'How We Use It',
          content: context.locale.languageCode == 'ar'
              ? 'لإدارة حسابك، عرض الإعلانات، التواصل معك، وتحسين أداء وأمان المنصة.'
              : 'To manage your account, display ads, communicate with you, and improve platform functionality.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'مشاركة المعلومات' : 'Sharing Your Info',
          content: context.locale.languageCode == 'ar'
              ? 'لا نبيع بياناتك. قد نشاركها مع السلطات القانونية أو مزودي الخدمات.'
              : 'We do not sell your data. We may share it with legal authorities or service providers.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'ملفات تعريف الارتباط' : 'Cookies',
          content: context.locale.languageCode == 'ar'
              ? 'نستخدم ملفات تعريف الارتباط لتحسين تجربتك. يمكنك تعطيلها من إعدادات المتصفح.'
              : 'We use cookies to enhance your experience, remember your preferences, and analyze usage data. You can manage or disable cookies at any time through your browser settings.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'أمان البيانات' : 'Data Security',
          content: context.locale.languageCode == 'ar'
              ? 'نتخذ التدابير اللازمة لحماية بياناتك، ولكن لا يمكننا ضمان الحماية الكاملة. استخدم المنصة على مسؤوليتك.'
              : 'We take reasonable technical and organizational measures to protect your data. However, no system is 100% secure. You use Deeloni at your own risk.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'حقوقك' : 'Your Rights',
          content: context.locale.languageCode == 'ar'
              ? 'يحق لك الوصول إلى معلوماتك الشخصية أو تحديثها أو حذفها. تواصل معنا على contact@deeloni.com.'
              : 'You may access, update, or delete your personal information. Contact us at contact@deeloni.com.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'الأطفال' : 'Children',
          content: context.locale.languageCode == 'ar'
              ? 'ديّلوني غير مخصصة للأطفال دون الحد الأدنى القانوني للعمر في بلدك. نحن لا نجمع أي بيانات شخصية من القُصّر.'
              : 'Deeloni is not intended for children under the legal minimum age in your country. We do not knowingly collect personal data from minors.',
        ),
        _buildSection(
          title: context.locale.languageCode == 'ar' ? 'التحديثات' : 'Updates',
          content: context.locale.languageCode == 'ar'
              ? 'قد نقوم بتحديث هذه السياسة. سيتم نشر التعديلات مع تاريخ سريان جديد.'
              : 'We may update this policy and will post changes with an updated effective date.',
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D5E2A),
                  )
                : GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0D5E2A),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[800],
                  )
                : GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.grey[800],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.locale.languageCode == 'ar' ? 'الاتفاق القانوني مطلوب' : 'Legal Agreement Required',
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  )
                : GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            context.locale.languageCode == 'ar'
                ? 'يرجى قبول الشروط والأحكام وسياسة الخصوصية للمتابعة.'
                : 'Please accept the Terms & Conditions and Privacy Policy to proceed.',
            style: context.locale.languageCode == 'ar'
                ? GoogleFonts.cairo(
                    fontSize: 14,
                    color: Colors.grey[700],
                  )
                : GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isAccepting ? null : _acceptTerms,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D5E2A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      context.locale.languageCode == 'ar' ? 'قبول الشروط والخصوصية' : 'Accept Terms & Privacy',
                      style: context.locale.languageCode == 'ar'
                          ? GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            )
                          : GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}