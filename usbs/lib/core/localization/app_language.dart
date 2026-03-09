import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

enum AppLanguageCode { en, hi, mr }

class AppLanguageController extends ChangeNotifier {
  AppLanguageCode _language = AppLanguageCode.en;
  final Map<String, String> _runtimeTranslations = <String, String>{};
  final Set<String> _pendingRuntimeTranslations = <String>{};

  AppLanguageCode get language => _language;
  bool get hasPendingRuntimeTranslations => _pendingRuntimeTranslations.isNotEmpty;

  void setLanguage(AppLanguageCode code) {
    if (_language == code) return;
    _language = code;
    notifyListeners();
  }

  String? getRuntimeTranslation(AppLanguageCode code, String sourceText) {
    return _runtimeTranslations[_cacheKey(code, sourceText)];
  }

  bool isRuntimeTranslationPending(AppLanguageCode code, String sourceText) {
    return _pendingRuntimeTranslations.contains(_cacheKey(code, sourceText.trim()));
  }

  void queueRuntimeTranslation(AppLanguageCode code, String sourceText) {
    if (code == AppLanguageCode.en) return;

    final text = sourceText.trim();
    if (text.isEmpty) return;
    if (_shouldSkipRuntimeTranslation(text)) return;

    final key = _cacheKey(code, text);
    if (_runtimeTranslations.containsKey(key) ||
        _pendingRuntimeTranslations.contains(key)) {
      return;
    }

    _pendingRuntimeTranslations.add(key);
    _translateAndCache(code, text);
  }

  Future<void> _translateAndCache(
    AppLanguageCode code,
    String sourceText,
  ) async {
    final key = _cacheKey(code, sourceText);
    try {
      final translated = await _translateUsingGoogleRuntime(
        sourceText,
        _langTag(code),
      );

      if (translated != null && translated.trim().isNotEmpty) {
        _runtimeTranslations[key] = translated.trim();
        notifyListeners();
      }
    } catch (_) {
      // Keep original text when network translation fails.
    } finally {
      _pendingRuntimeTranslations.remove(key);
    }
  }

  Future<String?> _translateUsingGoogleRuntime(
    String sourceText,
    String targetLang,
  ) async {
    final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
      'client': 'gtx',
      'sl': 'auto',
      'tl': targetLang,
      'dt': 't',
      'q': sourceText,
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List || decoded.isEmpty || decoded.first is! List) {
        return null;
      }

      final parts = <String>[];
      for (final segment in (decoded.first as List)) {
        if (segment is List && segment.isNotEmpty && segment.first is String) {
          parts.add(segment.first as String);
        }
      }

      if (parts.isEmpty) return null;
      return parts.join();
    } finally {
      client.close(force: true);
    }
  }

  String _cacheKey(AppLanguageCode code, String text) {
    return '${code.name}|$text';
  }

  String _langTag(AppLanguageCode code) {
    switch (code) {
      case AppLanguageCode.hi:
        return 'hi';
      case AppLanguageCode.mr:
        return 'mr';
      case AppLanguageCode.en:
        return 'en';
    }
  }

  bool _shouldSkipRuntimeTranslation(String value) {
    final numericOrSymbolOnly = RegExp(r'^[\d\s\W_]+$');
    if (numericOrSymbolOnly.hasMatch(value)) return true;
    if (value.length > 1500) return true;
    return false;
  }
}

class AppLanguageScope extends InheritedNotifier<AppLanguageController> {
  static final AppLanguageController _fallbackController =
      AppLanguageController();
  const AppLanguageScope({
    super.key,
    required super.child,
    required AppLanguageController controller,
  }) : super(notifier: controller);

  static AppLanguageController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppLanguageScope>();
    if (scope?.notifier == null) {
      return _fallbackController;
    }
    return scope!.notifier!;
  }
}

class AppI18n {
  static String tr(BuildContext context, String key) {
    final lang = AppLanguageScope.of(context).language;
    return _translations[lang]?[key] ??
        _translations[AppLanguageCode.en]?[key] ??
        key;
  }

  static String tx(BuildContext context, String englishText) {
    final controller = AppLanguageScope.of(context);
    final lang = controller.language;
    if (lang == AppLanguageCode.en) return englishText;
    final phrase = _phraseTranslations[lang]?[englishText];
    if (phrase != null) return phrase;

    final runtimeValue = controller.getRuntimeTranslation(lang, englishText);
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }

    controller.queueRuntimeTranslation(lang, englishText);
    return englishText;
  }

  static bool isTranslatingText(BuildContext context, String englishText) {
    final controller = AppLanguageScope.of(context);
    final lang = controller.language;
    if (lang == AppLanguageCode.en) return false;
    if (_phraseTranslations[lang]?[englishText] != null) return false;
    return controller.isRuntimeTranslationPending(lang, englishText);
  }

  static const Map<AppLanguageCode, Map<String, String>> _translations = {
    AppLanguageCode.en: {
      'app_name': 'USBS',
      'ngo_name': 'Unnati Sanvardhan Bahuuddeshiya Sanstha',
      'ngo_tagline': 'Legal • Medical • Education',
      'supporting_communities': 'Supporting communities with care',
      'legal_services': 'Legal Services',
      'medical_services': 'Medical Services',
      'education_services': 'Education Services',
      'Our Services': 'Our Services',
      'Submit legal support queries': 'Submit legal support queries',
      'Ask medical guidance questions': 'Ask medical guidance questions',
      'Get academic and admission help': 'Get academic and admission help',
      'Respond to assigned cases': 'Respond to assigned cases',
      'Track platform operations': 'Track platform operations',
      'Guest User': 'Guest User',
      'answer_queries': 'Answer Queries',
      'superadmin_dashboard': 'Superadmin Dashboard',
      'my_queries': 'My Queries',
      'category': 'Category',
      'status': 'Status',
      'all': 'All',
      'legal': 'Legal',
      'medical': 'Medical',
      'education': 'Education',
      'answered': 'Answered',
      'unanswered': 'Unanswered',
      'in_progress': 'In Progress',
      'no_queries': 'No queries found for selected filters',
      'please_login_queries': 'Please login to view your queries',
      'profile': 'Profile',
      'about': 'About',
      'photo_gallery': 'Photo Gallery',
      'assign_queries': 'Assign Queries',
      'manage_users': 'Manage Users',
      'superadmin_title': 'Superadmin Dashboard',
      'query_status_overview': 'Query Status Overview',
      'total': 'Total',
      'query_limit': 'Query limit',
      'update': 'Update',
      'track_all_queries': 'Track All Queries',
      'manage_users_roles': 'Manage Users & Roles',
      'admin_performance': 'Admin Performance',
      'no_admin_data': 'No admin data',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'marathi': 'Marathi',
      'no_description': 'No description',
      'logout': 'Logout',
      'welcome_user': 'Welcome, {name}',
      'support_question': 'How can we support you today?',
      'support_services': 'Support Services',
      'workspace': 'Workspace',
      'contact_details': 'Contact Details',
      'email_label': 'Email',
      'phone_label': 'Phone',
      'note_label': 'Note',
      'edit_contact_details': 'Edit Contact Details',
      'translating_content': 'Translating content...',
    },
    AppLanguageCode.hi: {
      'app_name': 'यूएसबीएस',
      'ngo_name': 'उन्नति संवर्धन बहुउद्देशीय संस्था',
      'ngo_tagline': 'कानूनी • चिकित्सा • शिक्षा',
      'supporting_communities': 'समुदायों को संवेदनशील सहयोग',
      'legal_services': 'कानूनी सेवाएं',
      'medical_services': 'चिकित्सा सेवाएं',
      'education_services': 'शैक्षणिक सेवाएं',
      'Our Services': 'हमारी सेवाएं',
      'Submit legal support queries': 'कानूनी सहायता के लिए प्रश्न भेजें',
      'Ask medical guidance questions': 'चिकित्सा मार्गदर्शन से जुड़े प्रश्न पूछें',
      'Get academic and admission help': 'पढ़ाई और प्रवेश संबंधी सहायता पाएं',
      'Respond to assigned cases': 'आवंटित मामलों का उत्तर दें',
      'Track platform operations': 'प्लेटफ़ॉर्म संचालन ट्रैक करें',
      'Guest User': 'अतिथि उपयोगकर्ता',
      'answer_queries': 'प्रश्नों का उत्तर',
      'superadmin_dashboard': 'सुपरएडमिन डैशबोर्ड',
      'my_queries': 'मेरे प्रश्न',
      'category': 'श्रेणी',
      'status': 'स्थिति',
      'all': 'सभी',
      'legal': 'कानूनी',
      'medical': 'चिकित्सा',
      'education': 'शिक्षा',
      'answered': 'उत्तरित',
      'unanswered': 'अनुत्तरित',
      'in_progress': 'प्रगति में',
      'no_queries': 'चयनित फ़िल्टर के लिए कोई प्रश्न नहीं मिला',
      'please_login_queries': 'अपने प्रश्न देखने के लिए लॉगिन करें',
      'profile': 'प्रोफ़ाइल',
      'about': 'हमारे बारे में',
      'photo_gallery': 'फोटो गैलरी',
      'assign_queries': 'प्रश्न आवंटित करें',
      'manage_users': 'उपयोगकर्ता प्रबंधन',
      'superadmin_title': 'सुपरएडमिन डैशबोर्ड',
      'query_status_overview': 'प्रश्न स्थिति अवलोकन',
      'total': 'कुल',
      'query_limit': 'प्रश्न सीमा',
      'update': 'अपडेट',
      'track_all_queries': 'सभी प्रश्न ट्रैक करें',
      'manage_users_roles': 'उपयोगकर्ता और भूमिकाएं',
      'admin_performance': 'एडमिन प्रदर्शन',
      'no_admin_data': 'एडमिन डेटा उपलब्ध नहीं',
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'no_description': 'कोई विवरण नहीं',
      'logout': 'लॉगआउट',
      'welcome_user': 'स्वागत है, {name}',
      'support_question': 'आज हम आपकी कैसे सहायता कर सकते हैं?',
      'support_services': 'सहायता सेवाएं',
      'workspace': 'कार्य क्षेत्र',
      'contact_details': 'संपर्क विवरण',
      'email_label': 'ईमेल',
      'phone_label': 'फोन',
      'note_label': 'नोट',
      'edit_contact_details': 'संपर्क विवरण संपादित करें',
      'translating_content': 'सामग्री का अनुवाद हो रहा है...',
    },
    AppLanguageCode.mr: {
      'app_name': 'यूएसबीएस',
      'ngo_name': 'उन्नती संवर्धन बहुउद्देशीय संस्था',
      'ngo_tagline': 'कायदेशीर • वैद्यकीय • शिक्षण',
      'supporting_communities': 'समुदायांना संवेदनशील मदत',
      'legal_services': 'कायदेशीर सेवा',
      'medical_services': 'वैद्यकीय सेवा',
      'education_services': 'शैक्षणिक सेवा',
      'Our Services': 'आमच्या सेवा',
      'Submit legal support queries': 'कायदेशीर मदतीसाठी प्रश्न पाठवा',
      'Ask medical guidance questions': 'वैद्यकीय मार्गदर्शनासाठी प्रश्न विचारा',
      'Get academic and admission help': 'शिक्षण व प्रवेशासाठी मदत मिळवा',
      'Respond to assigned cases': 'नेमून दिलेल्या प्रकरणांना उत्तर द्या',
      'Track platform operations': 'प्लॅटफॉर्मचे संचालन ट्रॅक करा',
      'Guest User': 'अतिथी वापरकर्ता',
      'answer_queries': 'प्रश्नांना उत्तर द्या',
      'superadmin_dashboard': 'सुपरअॅडमिन डॅशबोर्ड',
      'my_queries': 'माझे प्रश्न',
      'category': 'वर्ग',
      'status': 'स्थिती',
      'all': 'सर्व',
      'legal': 'कायदेशीर',
      'medical': 'वैद्यकीय',
      'education': 'शिक्षण',
      'answered': 'उत्तर दिलेले',
      'unanswered': 'अनुत्तरित',
      'in_progress': 'प्रगतीत',
      'no_queries': 'निवडलेल्या फिल्टरसाठी प्रश्न आढळले नाहीत',
      'please_login_queries': 'तुमचे प्रश्न पाहण्यासाठी लॉगिन करा',
      'profile': 'प्रोफाइल',
      'about': 'आमच्याबद्दल',
      'photo_gallery': 'फोटो गॅलरी',
      'assign_queries': 'प्रश्न वाटप',
      'manage_users': 'वापरकर्ता व्यवस्थापन',
      'superadmin_title': 'सुपरअॅडमिन डॅशबोर्ड',
      'query_status_overview': 'प्रश्न स्थिती आढावा',
      'total': 'एकूण',
      'query_limit': 'प्रश्न मर्यादा',
      'update': 'अपडेट',
      'track_all_queries': 'सर्व प्रश्न ट्रॅक करा',
      'manage_users_roles': 'वापरकर्ते व भूमिका',
      'admin_performance': 'अॅडमिन कामगिरी',
      'no_admin_data': 'अॅडमिन डेटा उपलब्ध नाही',
      'language': 'भाषा',
      'english': 'इंग्रजी',
      'hindi': 'हिंदी',
      'marathi': 'मराठी',
      'no_description': 'विवरण नाही',
      'logout': 'लॉगआउट',
      'welcome_user': 'स्वागत आहे, {name}',
      'support_question': 'आज आम्ही तुम्हाला कशी मदत करू शकतो?',
      'support_services': 'सहाय्य सेवा',
      'workspace': 'कार्य विभाग',
      'contact_details': 'संपर्क तपशील',
      'email_label': 'ईमेल',
      'phone_label': 'फोन',
      'note_label': 'टीप',
      'edit_contact_details': 'संपर्क तपशील संपादित करा',
      'translating_content': 'मजकूर अनुवादित केला जात आहे...',
    },
  };

  static const Map<AppLanguageCode, Map<String, String>> _phraseTranslations = {
    AppLanguageCode.hi: {
      'Logout': 'लॉगआउट',
      'Are you sure you want to logout?':
          'क्या आप सच में लॉगआउट करना चाहते हैं?',
      'Cancel': 'रद्द करें',
      'Login Required': 'लॉगिन आवश्यक',
      'Please log in to access this feature.':
          'इस सुविधा का उपयोग करने के लिए लॉगिन करें।',
      'Login': 'लॉगिन',
      'Photo Gallery': 'फोटो गैलरी',
      'No photos available yet': 'अभी कोई फोटो उपलब्ध नहीं है',
      'Notifications': 'सूचनाएं',
      'No notifications': 'कोई सूचना नहीं',
      'Manage Users': 'उपयोगकर्ता प्रबंधन',
      'No users found': 'कोई उपयोगकर्ता नहीं मिला',
      'Role': 'भूमिका',
      'Expertise': 'विशेषज्ञता',
      'Delete user': 'उपयोगकर्ता हटाएं',
      'User deleted': 'उपयोगकर्ता हटाया गया',
      'Assign Queries': 'प्रश्न आवंटित करें',
      'Auto-Assign': 'स्वतः आवंटन',
      'No unassigned queries': 'कोई अनिर्धारित प्रश्न नहीं',
      'No eligible admin in this category':
          'इस श्रेणी में कोई योग्य एडमिन नहीं',
      'Assign admin': 'एडमिन चुनें',
      'Query assigned successfully': 'प्रश्न सफलतापूर्वक आवंटित',
      'All Queries': 'सभी प्रश्न',
      'Search by client/admin name': 'क्लाइंट/एडमिन नाम से खोजें',
      'Sort/Filter by status': 'स्थिति अनुसार फ़िल्टर',
      'No queries found': 'कोई प्रश्न नहीं मिला',
      'No matching queries': 'कोई मिलान प्रश्न नहीं',
      'Assigned': 'आवंटित',
      'View only (not assigned)': 'केवल देखें (आवंटित नहीं)',
      'Query deleted': 'प्रश्न हटाया गया',
      'Query Chat': 'प्रश्न चैट',
      'Invalid query data': 'अमान्य प्रश्न डेटा',
      'Query not found': 'प्रश्न नहीं मिला',
      'Query Description': 'प्रश्न विवरण',
      'Conversation': 'वार्तालाप',
      'No messages yet': 'अभी कोई संदेश नहीं',
      'Reply...': 'उत्तर लिखें...',
      'Only assigned admin can reply': 'केवल आवंटित एडमिन उत्तर दे सकता है',
      'Legal Support': 'कानूनी सहायता',
      'Medical Support': 'चिकित्सा सहायता',
      'Education Support': 'शिक्षा सहायता',
      'Submit Legal Query': 'कानूनी प्रश्न भेजें',
      'Submit Medical Query': 'चिकित्सा प्रश्न भेजें',
      'Submit Education Query': 'शैक्षणिक प्रश्न भेजें',
      'My Legal Queries': 'मेरे कानूनी प्रश्न',
      'My Medical Queries': 'मेरे चिकित्सा प्रश्न',
      'My Education Queries': 'मेरे शैक्षणिक प्रश्न',
      'No legal queries submitted yet': 'अभी कोई कानूनी प्रश्न नहीं',
      'No medical queries submitted yet': 'अभी कोई चिकित्सा प्रश्न नहीं',
      'No education queries submitted yet': 'अभी कोई शैक्षणिक प्रश्न नहीं',
      'My Profile': 'मेरी प्रोफाइल',
      'Save Profile': 'प्रोफाइल सेव करें',
      'Edit Profile': 'प्रोफाइल संपादित करें',
      'Change Login Password': 'लॉगिन पासवर्ड बदलें',
      'Profile updated': 'प्रोफाइल अपडेट हो गई',
      'Password reset email sent': 'पासवर्ड रीसेट ईमेल भेजा गया',
      'About Us': 'हमारे बारे में',
      'Email': 'ईमेल',
      'Password': 'पासवर्ड',
      'Login with Email': 'ईमेल से लॉगिन',
      'Login with Google': 'गूगल से लॉगिन',
      'Reset Password': 'पासवर्ड रीसेट',
      'Continue as Guest': 'गेस्ट के रूप में जारी रखें',
      'Enter your email first': 'पहले अपना ईमेल दर्ज करें',
      'Unable to load notifications.': 'सूचनाएं लोड नहीं हो सकीं।',
      'Unable to load dashboard.': 'डैशबोर्ड लोड नहीं हो सका।',
      'All Queries (Superadmin)': 'सभी प्रश्न (सुपरएडमिन)',
      'Unassigned': 'अनिर्धारित',
      'Client': 'क्लाइंट',
      'Assigned To': 'आवंटित',
      'Category': 'श्रेणी',
      'Status': 'स्थिति',
      'Patient Name': 'रोगी का नाम',
      'Student Name': 'विद्यार्थी का नाम',
      'Class': 'कक्षा',
      'Topic': 'विषय',
      'Name': 'नाम',
      'Location': 'स्थान',
      'Case Type': 'केस प्रकार',
      'Legal Issue': 'कानूनी समस्या',
      'Medical Concern': 'चिकित्सा समस्या',
      'Query': 'प्रश्न',
      'Waiting for admin reply...': 'एडमिन के उत्तर की प्रतीक्षा...',
      'Write a reply...': 'उत्तर लिखें...',
      'Upload Document': 'दस्तावेज़ अपलोड करें',
      'Document upload coming soon': 'दस्तावेज़ अपलोड जल्द उपलब्ध होगा',
      'Urgency': 'तत्कालता',
      'Age': 'आयु',
      'Legal Query Details': 'कानूनी प्रश्न विवरण',
      'Medical Query Details': 'चिकित्सा प्रश्न विवरण',
      'Education Query Details': 'शैक्षणिक प्रश्न विवरण',
      'Legal Assistance': 'कानूनी सहायता',
      'Medical Assistance': 'चिकित्सा सहायता',
      'Education Guidance': 'शैक्षणिक मार्गदर्शन',
      'You can ask about:': 'आप इन विषयों पर पूछ सकते हैं:',
      'Case Details': 'मामले का विवरण',
      'Case Holder Name': 'मामला धारक का नाम',
      'City / Location': 'शहर / स्थान',
      'Legal Category': 'कानूनी श्रेणी',
      'Required': 'आवश्यक',
      'General': 'सामान्य',
      'Family': 'परिवार',
      'Property': 'संपत्ति',
      'Labour': 'श्रम',
      'Explain your legal issue': 'अपनी कानूनी समस्या बताएं',
      'Submission failed': 'सबमिशन असफल',
      'Please login to submit a legal query':
          'कानूनी प्रश्न भेजने के लिए लॉगिन करें',
      'Legal query submitted successfully':
          'कानूनी प्रश्न सफलतापूर्वक भेजा गया',
      'Patient Information': 'रोगी जानकारी',
      'Patient Name (optional)': 'रोगी का नाम (वैकल्पिक)',
      'Age (optional)': 'आयु (वैकल्पिक)',
      'Urgency Level': 'तत्कालता स्तर',
      'Low': 'कम',
      'Normal': 'सामान्य',
      'High': 'उच्च',
      'Describe the medical concern': 'चिकित्सा समस्या का विवरण दें',
      'Please login to submit a medical query':
          'चिकित्सा प्रश्न भेजने के लिए लॉगिन करें',
      'Medical query submitted successfully':
          'चिकित्सा प्रश्न सफलतापूर्वक भेजा गया',
      'Student Details': 'विद्यार्थी विवरण',
      'Student Name (optional)': 'विद्यार्थी का नाम (वैकल्पिक)',
      'Current Class / Course': 'वर्तमान कक्षा / पाठ्यक्रम',
      'General Guidance': 'सामान्य मार्गदर्शन',
      'Scholarships': 'छात्रवृत्ति',
      'Admissions': 'प्रवेश',
      'Career Advice': 'कैरियर सलाह',
      'Describe your education query': 'अपने शिक्षा प्रश्न का विवरण दें',
      'Please login to submit an education query':
          'शैक्षणिक प्रश्न भेजने के लिए लॉगिन करें',
      'Education query submitted successfully':
          'शैक्षणिक प्रश्न सफलतापूर्वक भेजा गया',
      'Full Name': 'पूरा नाम',
      'Phone Number': 'फोन नंबर',
      'City': 'शहर',
      'State': 'राज्य',
      'Not provided': 'उपलब्ध नहीं',
      'Escalate to Superadmin': 'सुपरएडमिन को एस्केलेट करें',
      'Escalation reason (optional)': 'एस्केलेशन कारण (वैकल्पिक)',
      'Escalated to superadmin': 'सुपरएडमिन को एस्केलेट किया गया',
      'Escalate': 'एस्केलेट',
      'Mark as Satisfied': 'संतुष्ट के रूप में चिह्नित करें',
      'Marked as satisfied': 'संतुष्ट के रूप में चिह्नित किया गया',
      'Search by name or email': 'नाम या ईमेल से खोजें',
    },
    AppLanguageCode.mr: {
      'Logout': 'लॉगआउट',
      'Are you sure you want to logout?':
          'तुम्हाला खरोखर लॉगआउट करायचे आहे का?',
      'Cancel': 'रद्द करा',
      'Login Required': 'लॉगिन आवश्यक',
      'Please log in to access this feature.':
          'ही सुविधा वापरण्यासाठी लॉगिन करा.',
      'Login': 'लॉगिन',
      'Photo Gallery': 'फोटो गॅलरी',
      'No photos available yet': 'अजून फोटो उपलब्ध नाहीत',
      'Notifications': 'सूचना',
      'No notifications': 'कोणत्याही सूचना नाहीत',
      'Manage Users': 'वापरकर्ता व्यवस्थापन',
      'No users found': 'कोणताही वापरकर्ता आढळला नाही',
      'Role': 'भूमिका',
      'Expertise': 'तज्ज्ञता',
      'Delete user': 'वापरकर्ता हटवा',
      'User deleted': 'वापरकर्ता हटवला',
      'Assign Queries': 'प्रश्न वाटप',
      'Auto-Assign': 'स्वयं-वाटप',
      'No unassigned queries': 'कोणतेही न वाटप केलेले प्रश्न नाहीत',
      'No eligible admin in this category': 'या वर्गात योग्य अॅडमिन नाही',
      'Assign admin': 'अॅडमिन निवडा',
      'Query assigned successfully': 'प्रश्न यशस्वीरित्या वाटप झाला',
      'All Queries': 'सर्व प्रश्न',
      'Search by client/admin name': 'क्लायंट/अॅडमिन नावाने शोधा',
      'Sort/Filter by status': 'स्थितीनुसार फिल्टर',
      'No queries found': 'कोणतेही प्रश्न आढळले नाहीत',
      'No matching queries': 'जुळणारे प्रश्न नाहीत',
      'Assigned': 'वाटप',
      'View only (not assigned)': 'फक्त पाहू शकता (वाटप नाही)',
      'Query deleted': 'प्रश्न हटवला',
      'Query Chat': 'प्रश्न चॅट',
      'Invalid query data': 'अवैध प्रश्न डेटा',
      'Query not found': 'प्रश्न सापडला नाही',
      'Query Description': 'प्रश्न वर्णन',
      'Conversation': 'संवाद',
      'No messages yet': 'अजून संदेश नाहीत',
      'Reply...': 'उत्तर लिहा...',
      'Only assigned admin can reply': 'फक्त वाटप केलेला अॅडमिन उत्तर देऊ शकतो',
      'Legal Support': 'कायदेशीर सहाय्य',
      'Medical Support': 'वैद्यकीय सहाय्य',
      'Education Support': 'शैक्षणिक सहाय्य',
      'Submit Legal Query': 'कायदेशीर प्रश्न पाठवा',
      'Submit Medical Query': 'वैद्यकीय प्रश्न पाठवा',
      'Submit Education Query': 'शैक्षणिक प्रश्न पाठवा',
      'My Legal Queries': 'माझे कायदेशीर प्रश्न',
      'My Medical Queries': 'माझे वैद्यकीय प्रश्न',
      'My Education Queries': 'माझे शैक्षणिक प्रश्न',
      'No legal queries submitted yet': 'अजून कायदेशीर प्रश्न नाहीत',
      'No medical queries submitted yet': 'अजून वैद्यकीय प्रश्न नाहीत',
      'No education queries submitted yet': 'अजून शैक्षणिक प्रश्न नाहीत',
      'My Profile': 'माझे प्रोफाइल',
      'Save Profile': 'प्रोफाइल जतन करा',
      'Edit Profile': 'प्रोफाइल संपादित करा',
      'Change Login Password': 'लॉगिन पासवर्ड बदला',
      'Profile updated': 'प्रोफाइल अपडेट झाली',
      'Password reset email sent': 'पासवर्ड रीसेट ईमेल पाठवला',
      'About Us': 'आमच्याबद्दल',
      'Email': 'ईमेल',
      'Password': 'पासवर्ड',
      'Login with Email': 'ईमेलने लॉगिन',
      'Login with Google': 'गूगलने लॉगिन',
      'Reset Password': 'पासवर्ड रीसेट',
      'Continue as Guest': 'गेस्ट म्हणून सुरू ठेवा',
      'Enter your email first': 'आधी ईमेल टाका',
      'Unable to load notifications.': 'सूचना लोड करता आल्या नाहीत.',
      'Unable to load dashboard.': 'डॅशबोर्ड लोड करता आला नाही.',
      'All Queries (Superadmin)': 'सर्व प्रश्न (सुपरअॅडमिन)',
      'Unassigned': 'न वाटप केलेले',
      'Client': 'क्लायंट',
      'Assigned To': 'वाटप',
      'Category': 'वर्ग',
      'Status': 'स्थिती',
      'Patient Name': 'रुग्णाचे नाव',
      'Student Name': 'विद्यार्थ्याचे नाव',
      'Class': 'इयत्ता',
      'Topic': 'विषय',
      'Name': 'नाव',
      'Location': 'ठिकाण',
      'Case Type': 'प्रकरण प्रकार',
      'Legal Issue': 'कायदेशीर समस्या',
      'Medical Concern': 'वैद्यकीय समस्या',
      'Query': 'प्रश्न',
      'Waiting for admin reply...': 'अॅडमिनच्या उत्तराची प्रतीक्षा...',
      'Write a reply...': 'उत्तर लिहा...',
      'Upload Document': 'दस्तऐवज अपलोड करा',
      'Document upload coming soon': 'दस्तऐवज अपलोड लवकरच उपलब्ध होईल',
      'Urgency': 'तातडी',
      'Age': 'वय',
      'Legal Query Details': 'कायदेशीर प्रश्न तपशील',
      'Medical Query Details': 'वैद्यकीय प्रश्न तपशील',
      'Education Query Details': 'शैक्षणिक प्रश्न तपशील',
      'Legal Assistance': 'कायदेशीर मदत',
      'Medical Assistance': 'वैद्यकीय मदत',
      'Education Guidance': 'शैक्षणिक मार्गदर्शन',
      'You can ask about:': 'तुम्ही याबाबत विचारू शकता:',
      'Case Details': 'प्रकरण तपशील',
      'Case Holder Name': 'प्रकरणधारक नाव',
      'City / Location': 'शहर / ठिकाण',
      'Legal Category': 'कायदेशीर वर्ग',
      'Required': 'आवश्यक',
      'General': 'सामान्य',
      'Family': 'कुटुंब',
      'Property': 'मालमत्ता',
      'Labour': 'श्रम',
      'Explain your legal issue': 'तुमची कायदेशीर समस्या सांगा',
      'Submission failed': 'सबमिशन अयशस्वी',
      'Please login to submit a legal query':
          'कायदेशीर प्रश्न पाठवण्यासाठी लॉगिन करा',
      'Legal query submitted successfully':
          'कायदेशीर प्रश्न यशस्वीरित्या पाठवला',
      'Patient Information': 'रुग्ण माहिती',
      'Patient Name (optional)': 'रुग्णाचे नाव (ऐच्छिक)',
      'Age (optional)': 'वय (ऐच्छिक)',
      'Urgency Level': 'तातडी पातळी',
      'Low': 'कमी',
      'Normal': 'सामान्य',
      'High': 'उच्च',
      'Describe the medical concern': 'वैद्यकीय समस्येचे वर्णन करा',
      'Please login to submit a medical query':
          'वैद्यकीय प्रश्न पाठवण्यासाठी लॉगिन करा',
      'Medical query submitted successfully':
          'वैद्यकीय प्रश्न यशस्वीरित्या पाठवला',
      'Student Details': 'विद्यार्थी तपशील',
      'Student Name (optional)': 'विद्यार्थ्याचे नाव (ऐच्छिक)',
      'Current Class / Course': 'सध्याची इयत्ता / अभ्यासक्रम',
      'General Guidance': 'सामान्य मार्गदर्शन',
      'Scholarships': 'शिष्यवृत्ती',
      'Admissions': 'प्रवेश',
      'Career Advice': 'करिअर सल्ला',
      'Describe your education query': 'तुमच्या शिक्षण प्रश्नाचे वर्णन करा',
      'Please login to submit an education query':
          'शैक्षणिक प्रश्न पाठवण्यासाठी लॉगिन करा',
      'Education query submitted successfully':
          'शैक्षणिक प्रश्न यशस्वीरित्या पाठवला',
      'Full Name': 'पूर्ण नाव',
      'Phone Number': 'फोन नंबर',
      'City': 'शहर',
      'State': 'राज्य',
      'Not provided': 'उपलब्ध नाही',
      'Escalate to Superadmin': 'सुपरअॅडमिनकडे एस्कलेट करा',
      'Escalation reason (optional)': 'एस्कलेशन कारण (ऐच्छिक)',
      'Escalated to superadmin': 'सुपरअॅडमिनकडे एस्कलेट केले',
      'Escalate': 'एस्कलेट',
      'Mark as Satisfied': 'समाधानी म्हणून चिन्हांकित करा',
      'Marked as satisfied': 'समाधानी म्हणून चिन्हांकित केले',
      'Search by name or email': 'नाव किंवा ईमेलने शोधा',
    },
  };
}

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = AppLanguageScope.of(context);
    return PopupMenuButton<AppLanguageCode>(
      tooltip: AppI18n.tr(context, 'language'),
      icon: const Icon(Icons.translate_rounded),
      onSelected: languageController.setLanguage,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: AppLanguageCode.en,
          child: Text(AppI18n.tr(context, 'english')),
        ),
        PopupMenuItem(
          value: AppLanguageCode.hi,
          child: Text(AppI18n.tr(context, 'hindi')),
        ),
        PopupMenuItem(
          value: AppLanguageCode.mr,
          child: Text(AppI18n.tr(context, 'marathi')),
        ),
      ],
    );
  }
}
