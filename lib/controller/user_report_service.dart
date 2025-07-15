
// User Report Service
import 'dart:developer';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Report reasons for user accounts
  static const List<Map<String, String>> reportReasons = [
    {
      'id': 'fake_profile',
      'title': 'Fake Profile',
      'description': 'This profile appears to be fake or impersonating someone else',
    },
    {
      'id': 'inappropriate_content',
      'title': 'Inappropriate Content',
      'description': 'Profile contains inappropriate or offensive content',
    },
    {
      'id': 'spam',
      'title': 'Spam',
      'description': 'This user is sending spam or unwanted messages',
    },
    {
      'id': 'scam',
      'title': 'Scam/Fraud',
      'description': 'This user is involved in scamming or fraudulent activities',
    },
    {
      'id': 'harassment',
      'title': 'Harassment',
      'description': 'This user is harassing or bullying others',
    },
    {
      'id': 'intellectual_property',
      'title': 'Intellectual Property',
      'description': 'This profile violates intellectual property rights',
    },
    {
      'id': 'minor_safety',
      'title': 'Minor Safety',
      'description': 'Content that may be harmful to minors',
    },
    {
      'id': 'other',
      'title': 'Other',
      'description': 'Other reason not listed above',
    },
  ];

  // Submit user report
  Future<bool> reportUser({
    required String reportedUserId,
    required String reportedUserName,
    required String reportReason,
    required String reportReasonTitle,
    String? additionalComments,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to report');
      }

      // Check if user has already reported this profile
      final existingReport = await _firestore
          .collection('account_reports')
          .where('reporterId', isEqualTo: currentUser.uid)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('reportType', isEqualTo: 'user')
          .limit(1)
          .get();

      if (existingReport.docs.isNotEmpty) {
        throw Exception('You have already reported this user');
      }

      // Get reporter info
      final reporterDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final reporterData = reporterDoc.data() ?? {};
      final reporterName = reporterData['companyName'] ?? 
                          reporterData['name'] ?? 
                          currentUser.displayName ?? 
                          'Unknown User';

      // Create report document
      final reportId = _firestore.collection('account_reports').doc().id;
      
      await _firestore.collection('account_reports').doc(reportId).set({
        'reportId': reportId,
        'reportType': 'user',
        'reporterId': currentUser.uid,
        'reporterName': reporterName,
        'reportedUserId': reportedUserId,
        'reportedUserName': reportedUserName,
        'reportReason': reportReason,
        'reportReasonTitle': reportReasonTitle,
        'additionalComments': additionalComments ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'reviewedBy': null,
        'reviewedAt': null,
        'actionTaken': null,
        'adminNotes': null,
      });

      log('✅ User report submitted successfully: $reportId');
      return true;

    } catch (e) {
      log('❌ Error submitting user report: $e');
      return false;
    }
  }

  // Get report reasons
  static List<Map<String, String>> getReportReasons() {
    return reportReasons;
  }

  // Check if user has already reported this profile
  Future<bool> hasUserReportedProfile(String reportedUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final existingReport = await _firestore
          .collection('account_reports')
          .where('reporterId', isEqualTo: currentUser.uid)
          .where('reportedUserId', isEqualTo: reportedUserId)
          .where('reportType', isEqualTo: 'user')
          .limit(1)
          .get();

      return existingReport.docs.isNotEmpty;

    } catch (e) {
      log('Error checking existing report: $e');
      return false;
    }
  }
}

// User Report Dialog
class UserReportDialog extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const UserReportDialog({
    Key? key,
    required this.reportedUserId,
    required this.reportedUserName,
  }) : super(key: key);

  @override
  State<UserReportDialog> createState() => _UserReportDialogState();
}

class _UserReportDialogState extends State<UserReportDialog> {
  final UserReportService _reportService = UserReportService();
  final TextEditingController _commentsController = TextEditingController();
  
  String? _selectedReason;
  String? _selectedReasonTitle;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.report, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Report ${widget.reportedUserName}',
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting this user?',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Report reasons
                    ...UserReportService.getReportReasons().map((reason) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedReason = reason['id'];
                                _selectedReasonTitle = reason['title'];
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _selectedReason == reason['id'] 
                                      ? Colors.red 
                                      : Colors.grey[300]!,
                                  width: _selectedReason == reason['id'] ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                color: _selectedReason == reason['id'] 
                                    ? Colors.red[50] 
                                    : Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedReason == reason['id'] 
                                        ? Icons.radio_button_checked 
                                        : Icons.radio_button_unchecked,
                                    color: _selectedReason == reason['id'] 
                                        ? Colors.red 
                                        : Colors.grey[400],
                                    size: 20,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reason['title']!,
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          reason['description']!,
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    
                    SizedBox(height: 20),
                    
                    // Additional comments
                    Text(
                      'Additional Comments (Optional)',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _commentsController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: 'Provide any additional details about this report...',
                        hintStyle: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason != null && !_isSubmitting
                          ? _submitReport
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'Submit Report',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_selectedReason == null || _selectedReasonTitle == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _reportService.reportUser(
        reportedUserId: widget.reportedUserId,
        reportedUserName: widget.reportedUserName,
        reportReason: _selectedReason!,
        reportReasonTitle: _selectedReasonTitle!,
        additionalComments: _commentsController.text.trim(),
      );

      if (success) {
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        throw Exception('Failed to submit report');
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
