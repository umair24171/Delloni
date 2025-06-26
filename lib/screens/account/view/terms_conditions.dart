
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _acceptTerms() async {
    setState(() => isAccepting = true);
    
    try {
      // Simulate acceptance process
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        hasAcceptedTerms = true;
        isAccepting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terms and Privacy Policy accepted successfully'),
          backgroundColor: Color(0xFF0D5E2A),
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
      _showErrorSnackBar('Failed to accept terms. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.requireAcceptance
            ? null
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
              ),
        title: Text(
          'Legal Documents',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0D5E2A),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFF0D5E2A),
          labelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Terms & Conditions'),
            Tab(text: 'Privacy Policy'),
          ],
        ),
      ),
      body: Column(
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
            title: 'Deeloni - Terms & Conditions',
            effectiveDate: 'App publish Date',
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
            title: 'Deeloni - Privacy Policy',
            effectiveDate: 'App publish Date',
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
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Effective Date: $effectiveDate',
            style: GoogleFonts.poppins(
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
          title: '1. Eligibility',
          content: 'By using Deeloni, you confirm that you are legally allowed to use online platforms in your country.',
        ),
        
        _buildSection(
          title: '2. Account & Registration',
          content: 'To post ads or interact with other users, you may be required to create an account. You agree to provide accurate information and keep your login details secure.',
        ),
        
        _buildSection(
          title: '3. User-Posted Content',
          content: 'You are solely responsible for the content you post. This includes the accuracy, legality, and appropriateness of your listings. We reserve the right to remove any content that violates our rules or Syrian law.',
        ),
        
        _buildSection(
          title: '4. Prohibited Listings',
          content: 'You may not post content or listings that promote illegal goods or services, violate Syrian laws, or include hate speech, harassment, or misleading information.',
        ),

        _buildSection(
          title: '5. Fees',
          content: 'Some features or categories may require payment. Any fees will be clearly displayed and are non-refundable once the ad goes live.',
        ),

        _buildSection(
          title: '6. Disclaimer',
          content: 'Deeloni is a listing platform. We do not take part in any transaction, nor do we verify users or the accuracy of listings. Use caution and common sense when interacting with others.',
        ),

        _buildSection(
          title: '7. Limitation of Liability',
          content: 'We are not responsible for any loss or damage resulting from your use of Deeloni. You use the platform at your own risk.',
        ),

        _buildSection(
          title: '8. Termination',
          content: 'We reserve the right to suspend or delete accounts that violate these terms or our content guidelines.',
        ),

        _buildSection(
          title: '9. Changes to Terms',
          content: 'These Terms may be updated. Continued use of Deeloni after updates constitutes your acceptance of the changes.',
        ),

        _buildSection(
          title: '10. Governing Law',
          content: 'These Terms are governed by the laws of the Syrian Arab Republic.',
        ),
      ],
    );
  }

  Widget _buildPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(
          title: '1. Information We Collect',
          content: 'We may collect your name, email address, phone number, location, IP address, browser/device info, and ad content.',
        ),

        _buildSection(
          title: '2. How We Use It',
          content: 'To manage your account, display ads, communicate with you, and improve platform functionality.',
        ),

        _buildSection(
          title: '3. Sharing Your Info',
          content: 'We do not sell your data. We may share it with legal authorities or service providers.',
        ),

        _buildSection(
          title: '4. Cookies',
          content: 'We use cookies to enhance your experience, remember your preferences, and analyze usage data. You can manage or disable cookies at any time through your browser settings.',
        ),

        _buildSection(
          title: '5. Data Security',
          content: 'We take reasonable technical and organizational measures to protect your data. However, no system is 100% secure. You use Deeloni at your own risk.',
        ),

        _buildSection(
          title: '6. Your Rights',
          content: 'You may access, update, or delete your personal information. Contact us at contact@deeloni.com.',
        ),

        _buildSection(
          title: '7. Children',
          content: 'Deeloni is not intended for children under the legal minimum age in your country. We do not knowingly collect personal data from minors.',
        ),

        _buildSection(
          title: '8. Updates',
          content: 'We may update this policy and will post changes with an updated effective date.',
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D5E2A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
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
            'Legal Agreement Required',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To continue using Deeloni, you must accept our Terms & Conditions and Privacy Policy.',
            style: GoogleFonts.poppins(
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
                      'Accept Terms & Privacy Policy',
                      style: GoogleFonts.poppins(
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