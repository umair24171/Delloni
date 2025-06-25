import 'dart:developer';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Help & Contact Service
class HelpContactService {
  static final HelpContactService _instance = HelpContactService._internal();
  factory HelpContactService() => _instance;
  HelpContactService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Submit contact form
  Future<Map<String, dynamic>> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
    String? phoneNumber,
    String? category,
  }) async {
    try {
      final user = _auth.currentUser;
      
      String contactId = _firestore.collection('contact_submissions').doc().id;
      
      await _firestore.collection('contact_submissions').doc(contactId).set({
        'contactId': contactId,
        'userId': user?.uid,
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber?.trim(),
        'subject': subject.trim(),
        'message': message.trim(),
        'category': category ?? 'general',
        'status': 'pending',
        'priority': _getPriority(category),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'adminResponse': null,
        'responseDate': null,
      });

      // Send notification to admins
      await _notifyAdmins(contactId, subject, category);

      return {
        'success': true,
        'message': 'Your message has been submitted successfully. We\'ll get back to you soon!',
        'contactId': contactId,
      };
    } catch (e) {
      log('Error submitting contact form: $e');
      return {
        'success': false,
        'message': 'Failed to submit your message. Please try again.',
      };
    }
  }

  // Submit bug report
  Future<Map<String, dynamic>> submitBugReport({
    required String title,
    required String description,
    required String stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? deviceInfo,
    String? appVersion,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'Please login to submit bug reports',
        };
      }

      String bugId = _firestore.collection('bug_reports').doc().id;
      
      await _firestore.collection('bug_reports').doc(bugId).set({
        'bugId': bugId,
        'userId': user.uid,
        'userEmail': user.email,
        'title': title.trim(),
        'description': description.trim(),
        'stepsToReproduce': stepsToReproduce.trim(),
        'expectedBehavior': expectedBehavior?.trim(),
        'actualBehavior': actualBehavior?.trim(),
        'deviceInfo': deviceInfo ?? 'Not provided',
        'appVersion': appVersion ?? '1.0.0',
        'attachments': attachments ?? [],
        'status': 'open',
        'priority': 'medium',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'assignedTo': null,
        'resolvedAt': null,
        'adminNotes': [],
      });

      return {
        'success': true,
        'message': 'Bug report submitted successfully. Thank you for helping us improve!',
        'bugId': bugId,
      };
    } catch (e) {
      log('Error submitting bug report: $e');
      return {
        'success': false,
        'message': 'Failed to submit bug report. Please try again.',
      };
    }
  }

  // Get FAQ items
  Future<List<FAQItem>> getFAQs() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('faqs')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => FAQItem.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error getting FAQs: $e');
      return [];
    }
  }

  // Get help categories
  Future<List<HelpCategory>> getHelpCategories() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('help_categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => HelpCategory.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error getting help categories: $e');
      return [];
    }
  }

  // Get help articles by category
  Future<List<HelpArticle>> getHelpArticles(String categoryId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('help_articles')
          .where('categoryId', isEqualTo: categoryId)
          .where('isPublished', isEqualTo: true)
          .orderBy('order')
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => HelpArticle.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      log('Error getting help articles: $e');
      return [];
    }
  }

  // Search help articles
  Future<List<HelpArticle>> searchHelpArticles(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('help_articles')
          .where('isPublished', isEqualTo: true)
          .get();

      List<HelpArticle> articles = snapshot.docs
          .map((doc) => HelpArticle.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by search query
      return articles.where((article) {
        String searchText = '${article.title} ${article.content}'.toLowerCase();
        return searchText.contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      log('Error searching help articles: $e');
      return [];
    }
  }

  // Get user's contact submissions
  Stream<List<ContactSubmission>> getUserContactSubmissions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('contact_submissions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ContactSubmission.fromFirestore(doc.data()))
            .toList());
  }

  // Helper methods
  String _getPriority(String? category) {
    switch (category?.toLowerCase()) {
      case 'bug':
      case 'security':
        return 'high';
      case 'account':
      case 'payment':
        return 'medium';
      default:
        return 'low';
    }
  }

  Future<void> _notifyAdmins(String contactId, String subject, String? category) async {
    try {
      // Add notification for admins
      await _firestore.collection('admin_notifications').add({
        'type': 'new_contact',
        'contactId': contactId,
        'subject': subject,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      log('Error notifying admins: $e');
    }
  }
}

// Terms & Conditions Service
class TermsConditionsService {
  static final TermsConditionsService _instance = TermsConditionsService._internal();
  factory TermsConditionsService() => _instance;
  TermsConditionsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current terms and conditions
  Future<TermsDocument?> getCurrentTerms() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('terms_conditions')
          .where('isActive', isEqualTo: true)
          .orderBy('version', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TermsDocument.fromFirestore(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      log('Error getting terms and conditions: $e');
      return null;
    }
  }

  // Get privacy policy
  Future<TermsDocument?> getCurrentPrivacyPolicy() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('privacy_policy')
          .where('isActive', isEqualTo: true)
          .orderBy('version', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return TermsDocument.fromFirestore(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      log('Error getting privacy policy: $e');
      return null;
    }
  }

  // Record user acceptance of terms
  Future<bool> recordTermsAcceptance(String termsId, String version) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _firestore.collection('terms_acceptances').add({
        'userId': user.uid,
        'termsId': termsId,
        'version': version,
        'acceptedAt': FieldValue.serverTimestamp(),
        'ipAddress': 'N/A', // Would need additional setup to capture IP
        'userAgent': 'Mobile App',
      });

      return true;
    } catch (e) {
      log('Error recording terms acceptance: $e');
      return false;
    }
  }

  // Check if user has accepted current terms
  Future<bool> hasUserAcceptedCurrentTerms() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      TermsDocument? currentTerms = await getCurrentTerms();
      if (currentTerms == null) return true; // No terms to accept

      QuerySnapshot snapshot = await _firestore
          .collection('terms_acceptances')
          .where('userId', isEqualTo: user.uid)
          .where('version', isEqualTo: currentTerms.version)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      log('Error checking terms acceptance: $e');
      return false;
    }
  }
}

// Data Models
class FAQItem {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;
  final bool isActive;
  final DateTime createdAt;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
    required this.isActive,
    required this.createdAt,
  });

  factory FAQItem.fromFirestore(Map<String, dynamic> data) {
    return FAQItem(
      id: data['id'] ?? '',
      question: data['question'] ?? '',
      answer: data['answer'] ?? '',
      category: data['category'] ?? 'general',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class HelpCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int order;
  final bool isActive;

  HelpCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.order,
    required this.isActive,
  });

  factory HelpCategory.fromFirestore(Map<String, dynamic> data) {
    return HelpCategory(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? 'help',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }
}

class HelpArticle {
  final String id;
  final String categoryId;
  final String title;
  final String content;
  final List<String> tags;
  final int order;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  HelpArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.tags,
    required this.order,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HelpArticle.fromFirestore(Map<String, dynamic> data) {
    return HelpArticle(
      id: data['id'] ?? '',
      categoryId: data['categoryId'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      order: data['order'] ?? 0,
      isPublished: data['isPublished'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ContactSubmission {
  final String contactId;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String category;
  final String status;
  final DateTime createdAt;
  final String? adminResponse;
  final DateTime? responseDate;

  ContactSubmission({
    required this.contactId,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.category,
    required this.status,
    required this.createdAt,
    this.adminResponse,
    this.responseDate,
  });

  factory ContactSubmission.fromFirestore(Map<String, dynamic> data) {
    return ContactSubmission(
      contactId: data['contactId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? '',
      category: data['category'] ?? 'general',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminResponse: data['adminResponse'],
      responseDate: (data['responseDate'] as Timestamp?)?.toDate(),
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Unknown';
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class TermsDocument {
  final String id;
  final String title;
  final String content;
  final String version;
  final bool isActive;
  final DateTime createdAt;
  final DateTime effectiveDate;

  TermsDocument({
    required this.id,
    required this.title,
    required this.content,
    required this.version,
    required this.isActive,
    required this.createdAt,
    required this.effectiveDate,
  });

  factory TermsDocument.fromFirestore(Map<String, dynamic> data) {
    return TermsDocument(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      version: data['version'] ?? '1.0',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      effectiveDate: (data['effectiveDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}