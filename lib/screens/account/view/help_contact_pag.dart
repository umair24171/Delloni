import 'package:arabicmarketplace/screens/account/controller/help_contact_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

// Fixed Help & Contact Page
class HelpContactPage extends StatefulWidget {
  const HelpContactPage({Key? key}) : super(key: key);

  @override
  State<HelpContactPage> createState() => _HelpContactPageState();
}

class _HelpContactPageState extends State<HelpContactPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final HelpContactService _helpService = HelpContactService();
  
  List<FAQItem> faqs = [];
  List<HelpCategory> helpCategories = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        _helpService.getFAQs(),
        _helpService.getHelpCategories(),
      ]);
      
      setState(() {
        faqs = results[0] as List<FAQItem>;
        helpCategories = results[1] as List<HelpCategory>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar('Failed to load help data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
            Tab(text: 'FAQ'),
            Tab(text: 'Help Center'),
            Tab(text: 'Contact Us'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D5E2A)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFAQTab(),
                _buildHelpCenterTab(),
                _buildContactTab(),
                _buildMyTicketsTab(),
              ],
            ),
    );
  }

  Widget _buildFAQTab() {
    if (faqs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.quiz_outlined,
        title: 'No FAQs Available',
        subtitle: 'Frequently asked questions will appear here',
      );
    }

    // Filter FAQs based on search query
    List<FAQItem> filteredFAQs = faqs.where((faq) {
      if (searchQuery.isEmpty) return true;
      return faq.question.toLowerCase().contains(searchQuery.toLowerCase()) ||
             faq.answer.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    Map<String, List<FAQItem>> groupedFAQs = {};
    for (var faq in filteredFAQs) {
      if (!groupedFAQs.containsKey(faq.category)) {
        groupedFAQs[faq.category] = [];
      }
      groupedFAQs[faq.category]!.add(faq);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search FAQs...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // FAQ Categories
          if (groupedFAQs.isEmpty)
            _buildEmptyState(
              icon: Icons.search_off,
              title: 'No Results Found',
              subtitle: 'Try adjusting your search terms',
            )
          else
            ...groupedFAQs.entries.map((entry) => _buildFAQCategory(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildFAQCategory(String category, List<FAQItem> categoryFAQs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D5E2A),
          ),
        ),
        const SizedBox(height: 12),
        ...categoryFAQs.map((faq) => _buildFAQItem(faq)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        iconColor: const Color(0xFF0D5E2A),
        collapsedIconColor: Colors.grey[600],
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              faq.answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCenterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (helpCategories.isNotEmpty) 
            ...helpCategories.map((category) => _buildHelpCategoryCard(category))
          else
            _buildEmptyState(
              icon: Icons.help_center_outlined,
              title: 'Help Center Coming Soon',
              subtitle: 'Detailed help articles will be available here',
            ),
          const SizedBox(height: 20),
          _buildQuickActions(),
        ],
      ),
    );
  }

  Widget _buildHelpCategoryCard(HelpCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToHelpArticles(category),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D5E2A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconData(category.icon),
                  color: const Color(0xFF0D5E2A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
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
        children: [
          Text(
            'Still Need Help?',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact our support team for personalized assistance',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Live Chat',
                  onTap: () => _tabController.animateTo(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  onTap: () => _launchEmail(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact methods
          _buildContactMethods(),
          const SizedBox(height: 24),
          
          // Contact form
          _buildContactForm(),
        ],
      ),
    );
  }

  Widget _buildContactMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Get in Touch',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: _buildContactMethodCard(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'support@delloni.com',
                onTap: () => _launchEmail(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactMethodCard(
                icon: Icons.phone_outlined,
                title: 'Phone',
                subtitle: '+1 (555) 123-4567',
                onTap: () => _launchPhone(),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildContactMethodCard(
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () => _showChatDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactMethodCard(
                icon: Icons.bug_report_outlined,
                title: 'Report Bug',
                subtitle: 'Technical Issues',
                onTap: () => _showBugReportDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactMethodCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF0D5E2A), size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return ContactFormWidget(
      onSuccess: () {
        _tabController.animateTo(3);
        _showSuccessSnackBar('Message sent successfully!');
      },
      onError: (message) => _showErrorSnackBar(message),
    );
  }

  Widget _buildMyTicketsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'Login Required',
        subtitle: 'Please login to view your support tickets',
        action: ElevatedButton(
          onPressed: () {
            // Navigate to login
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D5E2A),
          ),
          child: Text(
            'Login',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      );
    }

    return StreamBuilder<List<ContactSubmission>>(
      stream: _helpService.getUserContactSubmissions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0D5E2A)));
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.error_outline,
            title: 'Error Loading Tickets',
            subtitle: 'Please try again later',
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Icons.support_agent_outlined,
            title: 'No Support Tickets',
            subtitle: 'Your support requests will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final ticket = snapshot.data![index];
            return _buildTicketCard(ticket);
          },
        );
      },
    );
  }

  Widget _buildTicketCard(ContactSubmission ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ticket.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ticket.statusDisplay,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ticket.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket.message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.category_outlined, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                ticket.category.toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(ticket.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          if (ticket.adminResponse != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Support Response:',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ticket.adminResponse!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'account':
        return Icons.account_circle_outlined;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'technical':
        return Icons.build_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToHelpArticles(HelpCategory category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HelpArticlesPage(category: category),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Live Chat',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Live chat feature is coming soon! For now, please use the contact form or email us directly.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(color: const Color(0xFF0D5E2A)),
            ),
          ),
        ],
      ),
    );
  }

  void _showBugReportDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BugReportPage()),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@delloni.com',
      query: 'subject=Support Request',
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch email client');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+15551234567');
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    } catch (e) {
      _showErrorSnackBar('Could not launch phone dialer');
    }
  }
}

// Separate Contact Form Widget
class ContactFormWidget extends StatefulWidget {
  final VoidCallback onSuccess;
  final Function(String) onError;

  const ContactFormWidget({
    Key? key,
    required this.onSuccess,
    required this.onError,
  }) : super(key: key);

  @override
  State<ContactFormWidget> createState() => _ContactFormWidgetState();
}

class _ContactFormWidgetState extends State<ContactFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'general';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send us a Message',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            // Name field
            _buildFormField(
              controller: _nameController,
              label: 'Full Name',
              hint: 'Enter your full name',
              validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
            ),
            
            const SizedBox(height: 16),
            
            // Email field
            _buildFormField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value?.isEmpty == true) return 'Email is required';
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Category dropdown
            Text(
              'Category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                  items: const [
                    DropdownMenuItem(value: 'general', child: Text('General Inquiry')),
                    DropdownMenuItem(value: 'account', child: Text('Account Issues')),
                    DropdownMenuItem(value: 'technical', child: Text('Technical Support')),
                    DropdownMenuItem(value: 'billing', child: Text('Billing & Payments')),
                    DropdownMenuItem(value: 'feedback', child: Text('Feedback & Suggestions')),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Subject field
            _buildFormField(
              controller: _subjectController,
              label: 'Subject',
              hint: 'Brief description of your inquiry',
              validator: (value) => value?.isEmpty == true ? 'Subject is required' : null,
            ),
            
            const SizedBox(height: 16),
            
            // Message field
            _buildFormField(
              controller: _messageController,
              label: 'Message',
              hint: 'Describe your issue or question in detail...',
              maxLines: 5,
              validator: (value) => value?.isEmpty == true ? 'Message is required' : null,
            ),
            
            const SizedBox(height: 24),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D5E2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Send Message',
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
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D5E2A)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await HelpContactService().submitContactForm(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
      );

      if (result['success']) {
        _clearForm();
        widget.onSuccess();
      } else {
        widget.onError(result['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      widget.onError('Failed to send message. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _subjectController.clear();
    _messageController.clear();
    setState(() => _selectedCategory = 'general');
  }
}

// Help Articles Page
class HelpArticlesPage extends StatefulWidget {
  final HelpCategory category;

  const HelpArticlesPage({Key? key, required this.category}) : super(key: key);

  @override
  State<HelpArticlesPage> createState() => _HelpArticlesPageState();
}

class _HelpArticlesPageState extends State<HelpArticlesPage> {
  List<HelpArticle> articles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() => isLoading = true);
    try {
      articles = await HelpContactService().getHelpArticles(widget.category.id);
    } catch (e) {
      // Handle error
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.category.name,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D5E2A)))
          : articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No Articles Available',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Articles for this category will appear here',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _openArticle(article),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                article.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.content,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _openArticle(HelpArticle article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }
}

// Article Detail Page
class ArticleDetailPage extends StatelessWidget {
  final HelpArticle article;

  const ArticleDetailPage({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Help Article',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              article.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              article.content,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bug Report Page
class BugReportPage extends StatefulWidget {
  const BugReportPage({Key? key}) : super(key: key);

  @override
  State<BugReportPage> createState() => _BugReportPageState();
}

class _BugReportPageState extends State<BugReportPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Report Bug',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help us improve by reporting bugs',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              _buildFormField(
                controller: _titleController,
                label: 'Bug Title',
                hint: 'Brief description of the bug',
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              _buildFormField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Detailed description of the bug',
                maxLines: 4,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              
              const SizedBox(height: 16),
              
              _buildFormField(
                controller: _stepsController,
                label: 'Steps to Reproduce',
                hint: '1. Go to...\n2. Click on...\n3. Notice that...',
                maxLines: 4,
                validator: (value) => value?.isEmpty == true ? 'Steps are required' : null,
              ),
              
              const SizedBox(height: 16),
              
              _buildFormField(
                controller: _expectedController,
                label: 'Expected Behavior',
                hint: 'What should happen?',
                maxLines: 3,
              ),
              
              const SizedBox(height: 16),
              
              _buildFormField(
                controller: _actualController,
                label: 'Actual Behavior',
                hint: 'What actually happened?',
                maxLines: 3,
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitBugReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D5E2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Submit Bug Report',
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
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0D5E2A)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _submitBugReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final result = await HelpContactService().submitBugReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        stepsToReproduce: _stepsController.text.trim(),
        expectedBehavior: _expectedController.text.isNotEmpty ? _expectedController.text.trim() : null,
        actualBehavior: _actualController.text.isNotEmpty ? _actualController.text.trim() : null,
      );

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showErrorSnackBar(result['message'] ?? 'Failed to submit bug report');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit bug report. Please try again.');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: Text(
          'Bug Report Submitted!',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Thank you for helping us improve. We\'ll investigate this issue.',
          style: GoogleFonts.poppins(fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFF0D5E2A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}