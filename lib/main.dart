import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// 1. ABSTRACTION & INTERFACES
// ============================================================================

/// Abstraction: Abstract base class representing any event in the fest.
abstract class FestEvent {
  final String title;
  final String venue;

  FestEvent(this.title, this.venue);

  // Abstract methods enforcing sub-class implementation
  String getEventDetails();
  IconData getIcon();
  List<String> getGalleryImages();

  // Concrete getter
  String get locationInfo => 'Venue: $venue';
}

/// Interface: Contracts for events that issue certificates.
abstract class Certifiable {
  void generateCertificate(String studentName);
  bool get offersCertificate;
}

// ============================================================================
// 2. MIXINS (Reusable Feature Injection)
// ============================================================================

/// Mixin adding sponsorship and budget handling to events.
mixin SponsorshipRequirement {
  double _budget = 0.0; // Encapsulated private field

  double get budget => _budget;

  void addSponsorship(double amount) {
    if (amount > 0) {
      _budget += amount;
    }
  }

  void allocateExpense(double amount) {
    if (amount <= _budget) {
      _budget -= amount;
    }
  }
}

// ============================================================================
// 3. ENCAPSULATION, INHERITANCE & POLYMORPHISM
// ============================================================================

/// Subclass 1: [TechnicalEvent] extends [FestEvent], uses mixin & interface
class TechnicalEvent extends FestEvent
    with SponsorshipRequirement
    implements Certifiable {
  // Encapsulation: Private members
  int _registrationsCount = 0;
  final int _maxCapacity;

  // Static Member: Tracks total fest registrations across all technical events
  static int totalFestRegistrations = 0;

  // Standard Constructor with super-initializer
  TechnicalEvent(super.title, super.venue, this._maxCapacity);

  // Named Constructor
  TechnicalEvent.codingCompetition(String title)
    : _maxCapacity = 50,
      super(title, 'Lab 302');

  // Factory Constructor: Creates specialized preset events
  factory TechnicalEvent.hackathon() {
    return TechnicalEvent('Ai and Machine Learning', 'Main Auditorium', 100);
  }

  // Getters & Setters for Encapsulated Fields
  int get registrationsCount => _registrationsCount;
  bool get hasCapacity => _registrationsCount < _maxCapacity;

  bool registerStudent() {
    if (_registrationsCount < _maxCapacity) {
      _registrationsCount++;
      totalFestRegistrations++;
      return true;
    }
    return false;
  }

  // Polymorphic Implementation of Abstract Methods
  @override
  String getEventDetails() {
    return 'Tech Event | Slots: $_registrationsCount/$_maxCapacity';
  }

  @override
  IconData getIcon() => Icons.code;

  // Interface Implementation
  @override
  bool get offersCertificate => true;

  @override
  void generateCertificate(String studentName) {
    debugPrint('Certificate generated for $studentName in $title');
  }

  @override
  List<String> getGalleryImages() {
    return [
      'assets/images/fest_poster.png',
      'assets/images/hacathon.png',
      'assets/images/song.png',
      'assets/images/orchestor.png',
      // Add more gallery images here
      // 'assets/images/event_image_5.jpg',
    ];
  }
}

/// Subclass 2: [CulturalEvent] demonstrating different Polymorphic behavior
class CulturalEvent extends FestEvent implements Certifiable {
  final String category; // e.g., Dance, Music, Drama
  bool _isStageReady = false;

  CulturalEvent(super.title, super.venue, this.category);

  void prepareStage() {
    _isStageReady = true;
  }

  // Polymorphic Overriding
  @override
  String getEventDetails() {
    final status = _isStageReady ? 'Stage Ready' : 'Rehearsals Ongoing';
    return 'Cultural ($category) | Status: $status';
  }

  @override
  IconData getIcon() => Icons.music_note;

  // Interface Implementation
  @override
  bool get offersCertificate => false; // Cultural events might just give trophies

  @override
  void generateCertificate(String studentName) {
    debugPrint('Participation award generated for $studentName');
  }

  @override
  List<String> getGalleryImages() {
    return [
      'assets/images/fest_poster.png',
      'assets/images/hacathon.png',
      'assets/images/song.png',
      'assets/images/orchestor.png',
      // Add more gallery images here
      // 'assets/images/event_image_5.jpg',
    ];
  }
}

/// Registration model used for voucher generation and local recent record storage.
class RegistrationData {
  final String studentName;
  final String phoneNumber;
  final String collegeName;
  final String emailAddress;
  final String eventTitle;
  final String eventVenue;
  final String eventType;
  final DateTime registeredAt;

  RegistrationData({
    required this.studentName,
    required this.phoneNumber,
    required this.collegeName,
    required this.emailAddress,
    required this.eventTitle,
    required this.eventVenue,
    required this.eventType,
    required this.registeredAt,
  });
}

// ============================================================================
// 4. FLUTTER UI INTEGRATION
// ============================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: 'assets/.env', isOptional: true);
  } catch (_) {
    // Env file is optional in release builds; secrets are passed via
    // --dart-define (SUPABASE_URL / SUPABASE_KEY) when deployed to the web.
  }

  runApp(
    const MaterialApp(
      home: CollegeFestDashboard(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class CollegeFestDashboard extends StatefulWidget {
  const CollegeFestDashboard({super.key});

  @override
  State<CollegeFestDashboard> createState() => _CollegeFestDashboardState();
}

class _CollegeFestDashboardState extends State<CollegeFestDashboard> {
  // Navigation state
  String _currentPage = 'Home';
  final List<String> _navItems = [
    'Home',
    'Events',
    'About',
    'Gallery',
    'Contact',
  ];

  // Gallery animation state
  late PageController _galleryController;
  int _currentGalleryIndex = 0;
  late Timer _galleryAutoPlayTimer;
  static const Duration _autoPlayDuration = Duration(seconds: 4);

  // Compiled-in secrets injected via --dart-define at build time (web release).
  static const String _supabaseUrlFromDefine = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _supabaseKeyFromDefine = String.fromEnvironment(
    'SUPABASE_KEY',
  );

  // Polymorphic List holding base type reference [FestEvent]
  late final List<FestEvent> _festEvents;
  final Map<String, RegistrationData> _latestRegistrations = {};

  @override
  void initState() {
    super.initState();
    _galleryController = PageController();
    _startGalleryAutoPlay();
    // Instantiating concrete subclasses via various constructors
    _festEvents = [
      TechnicalEvent.hackathon(), // Factory Constructor
      TechnicalEvent.codingCompetition('Hacakathon'), // Named Constructor
      TechnicalEvent(
        'Flutter Workshop',
        'Class room 502',
        40,
      ), // Standard Constructor
      CulturalEvent(
        'Kannada Orchestor',
        'College Ground',
        'Music',
      ), // Subclass 2
    ];
  }

  @override
  void dispose() {
    _galleryAutoPlayTimer.cancel();
    _galleryController.dispose();
    super.dispose();
  }

  void _startGalleryAutoPlay() {
    _galleryAutoPlayTimer = Timer.periodic(_autoPlayDuration, (_) {
      if (_galleryController.hasClients) {
        final galleryImages = _festEvents.isNotEmpty
            ? _festEvents[0].getGalleryImages()
            : [];
        _currentGalleryIndex =
            (_currentGalleryIndex + 1) % galleryImages.length;
        _galleryController.animateToPage(
          _currentGalleryIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _nextGalleryImage() {
    if (_galleryController.hasClients) {
      final galleryImages = _festEvents.isNotEmpty
          ? _festEvents[0].getGalleryImages()
          : [];
      _currentGalleryIndex = (_currentGalleryIndex + 1) % galleryImages.length;
      _galleryController.animateToPage(
        _currentGalleryIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _resetGalleryAutoPlay();
    }
  }

  void _prevGalleryImage() {
    if (_galleryController.hasClients) {
      final galleryImages = _festEvents.isNotEmpty
          ? _festEvents[0].getGalleryImages()
          : [];
      _currentGalleryIndex =
          (_currentGalleryIndex - 1 + galleryImages.length) %
          galleryImages.length;
      _galleryController.animateToPage(
        _currentGalleryIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      _resetGalleryAutoPlay();
    }
  }

  void _resetGalleryAutoPlay() {
    _galleryAutoPlayTimer.cancel();
    _startGalleryAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KLE Haveri BCA Fest'),
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
        actions: isMobile
            ? null
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      for (final item in _navItems) _buildNavLink(item),
                    ],
                  ),
                ),
              ],
      ),
      drawer: isMobile
          ? Drawer(
              child: ListView(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 58, 183, 177),
                    ),
                    child: Text(
                      'Navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (final item in _navItems)
                    ListTile(
                      title: Text(item),
                      onTap: () {
                        setState(() {
                          _currentPage = item;
                        });
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(child: _buildPageView()),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildPageView() {
    switch (_currentPage) {
      case 'Events':
        return _buildEventsPage();
      case 'About':
        return _buildAboutPage();
      case 'Gallery':
        return _buildGalleryPage();
      case 'Contact':
        return _buildContactPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildNavLink(String title) {
    final isActive = _currentPage == title;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: () {
          setState(() {
            _currentPage = title;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isActive
              ? Colors.white.withAlpha((0.2 * 255).round())
              : Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final galleryHeight = isMobile ? 180.0 : 240.0;
        final padding = isMobile ? 10.0 : 16.0;
        final spacing = isMobile ? 6.0 : 8.0;
        final fontSize = isMobile ? 11.0 : 12.0;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Event Gallery - Landscape Images (16:9 ratio)
                // Image dimensions guide: Upload images with 16:9 landscape ratio
                // Recommended sizes: 1920x1080px, 1280x720px, or 1024x576px
                Container(
                  height: galleryHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildEventGallery(),
                ),

                SizedBox(height: spacing),

                // Event Info Row (Date, Venue, Participants)
                Container(
                  padding: EdgeInsets.all(padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today,
                          label: 'Aug 15 2026',
                          onTap: null,
                        ),
                      ),
                      Flexible(
                        child: _buildInfoCard(
                          icon: Icons.location_on,
                          label: 'KLE Haveri BCA',
                          onTap: _openLocationUrl,
                        ),
                      ),
                      Flexible(
                        child: _buildInfoCard(
                          icon: Icons.people,
                          label: '${_latestRegistrations.length} Participants',
                          onTap: null,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: spacing),

                // View Events Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _currentPage = 'Events';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 58, 183, 177),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 7 : 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'View Events',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: spacing),

                // Slogan Section
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Text(
                      'KLE INDEPENDENCE DAY\n2026\nDevelop the next generation of freedom—register now to compile our rich heritage and deploy a future of endless possibilities at KLE Haveri.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontStyle: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build individual info card for date, venue, or participants
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Color.fromARGB(255, 58, 183, 177), size: 24),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }

  /// Open location URL in browser
  Future<void> _openLocationUrl() async {
    final Uri locationUrl = Uri.parse(
      'https://maps.google.com/?q=KLE+Haveri+BCA+College',
    );
    if (await canLaunchUrl(locationUrl)) {
      await launchUrl(locationUrl, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildEventsPage() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.deepPurple.shade50,
          child: const Text(
            'Featured Events',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _festEvents.length,
            itemBuilder: (context, index) {
              final event = _festEvents[index];
              return _buildEventCard(event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAboutPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'About KLE Haveri BCA Fest',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'The KLE Haveri BCA College Fest is an annual celebration bringing together students, faculty, and community members to showcase talent, innovation, and cultural diversity. '
                'Our fest features technical competitions, cultural performances, workshops, and networking opportunities.\n\n'
                'Events hosted include:\n'
                '• AI and Machine Learning Hackathon\n'
                '• Coding Competitions\n'
                '• Flutter Development Workshops\n'
                '• Cultural Performances and Orchestral Displays\n\n'
                'Join us in celebrating excellence and creativity!',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Stats',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Events',
                    '${_festEvents.length}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Registrations',
                    '${TechnicalEvent.totalFestRegistrations}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryPage() {
    // Get gallery images from the first event (all events share the same gallery now)
    final galleryImages = _festEvents.isNotEmpty
        ? _festEvents.first.getGalleryImages()
        : [];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 2 : 3;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Gallery',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: galleryImages.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        galleryImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactPage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Contact Us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildContactCard('Email', 'fest@klehaveri.edu.in', Icons.email),
            _buildContactCard('Phone', '+91 9876543210', Icons.phone),
            _buildContactCard(
              'Location',
              'KLE Haveri, Karnataka, India',
              Icons.location_on,
            ),
            const SizedBox(height: 24),
            const Text(
              'Event Coordinators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContactPerson('Dr. John Doe', 'Fest Coordinator'),
            _buildContactPerson('Ms. Jane Smith', 'Cultural Lead'),
            _buildContactPerson('Mr. Ram Kumar', 'Technical Lead'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color.fromARGB(255, 58, 183, 177), size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactPerson(String name, String role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            role,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 58, 183, 177),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // Renders UI polymorphically using base class contract [FestEvent]
  Widget _buildEventCard(FestEvent event) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: InkWell(
        onTap: () => _openEventDetails(event),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color.fromARGB(255, 196, 232, 233),
                  child: Icon(
                    event.getIcon(),
                    color: const Color.fromARGB(255, 58, 148, 183),
                  ), // Polymorphic Icon
                ),
                title: Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${event.locationInfo}\n${event.getEventDetails()}',
                ), // Polymorphic String
                trailing:
                    (event is Certifiable &&
                        (event as Certifiable).offersCertificate)
                    ? ElevatedButton.icon(
                        icon: const Icon(Icons.download, size: 16),
                        label: Text(
                          _latestRegistrations[event.title] != null
                              ? 'Download'
                              : 'Voucher',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            105,
                            211,
                            240,
                          ),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        onPressed: _latestRegistrations[event.title] != null
                            ? () => _downloadVoucher(
                                _latestRegistrations[event.title]!,
                              )
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Register for this event to download your voucher.',
                                    ),
                                  ),
                                );
                              },
                      )
                    : null,
              ),
              const Divider(),
              // Type-specific action triggers
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (event is TechnicalEvent) ...[
                    Text('Budget: Rs${event.budget.toInt()}'), // Mixin property
                    IconButton(
                      icon: const Icon(
                        Icons.attach_money,
                        color: Color.fromARGB(255, 87, 175, 76),
                      ),
                      onPressed: () {
                        setState(() {
                          event.addSponsorship(100.0); // Mixin method
                        });
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Register'),
                      onPressed: () async {
                        await _showRegistrationDialog(event);
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  ],
                  if (event is CulturalEvent) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.mic, size: 16),
                      label: const Text('Lets start the program'),
                      onPressed: () {
                        setState(() {
                          event.prepareStage();
                        });
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEventDetails(FestEvent event) {
    final registration = _latestRegistrations[event.title];
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailPage(
          event: event,
          registration: registration,
          onDownloadVoucher: registration == null ? null : _downloadVoucher,
        ),
      ),
    );
  }

  Future<void> _showRegistrationDialog(TechnicalEvent event) async {
    if (!event.hasCapacity) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration full for this event.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final collegeController = TextEditingController();
    final emailController = TextEditingController();
    var isSubmitting = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Register for Event'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Student Name',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter student name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: collegeController,
                        decoration: const InputDecoration(labelText: 'College'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter college name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter email address';
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() {
                            isSubmitting = true;
                          });

                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);

                          final success = await _submitRegistration(
                            event: event,
                            studentName: nameController.text,
                            phoneNumber: phoneController.text,
                            collegeName: collegeController.text,
                            emailAddress: emailController.text,
                          );

                          if (!mounted) return;
                          setState(() {
                            isSubmitting = false;
                          });

                          if (success) {
                            final registered = event.registerStudent();
                            if (registered) {
                              _latestRegistrations[event.title] =
                                  RegistrationData(
                                    studentName: nameController.text.trim(),
                                    phoneNumber: phoneController.text.trim(),
                                    collegeName: collegeController.text.trim(),
                                    emailAddress: emailController.text.trim(),
                                    eventTitle: event.title,
                                    eventVenue: event.venue,
                                    eventType: event.runtimeType.toString(),
                                    registeredAt: DateTime.now().toUtc(),
                                  );
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Registration successful'),
                                ),
                              );
                            } else {
                              scaffoldMessenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Registration limit reached.'),
                                ),
                              );
                            }
                            navigator.pop();
                            setState(() {});
                          } else {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to submit registration.'),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitRegistration({
    required TechnicalEvent event,
    required String studentName,
    required String phoneNumber,
    required String collegeName,
    required String emailAddress,
  }) async {
    final supabaseUrl = _supabaseUrlFromDefine.isNotEmpty
        ? _supabaseUrlFromDefine
        : dotenv.isInitialized
        ? dotenv.env['SUPABASE_URL']
        : null;
    final supabaseKey = _supabaseKeyFromDefine.isNotEmpty
        ? _supabaseKeyFromDefine
        : dotenv.isInitialized
        ? dotenv.env['SUPABASE_KEY']
        : null;

    if (supabaseUrl == null || supabaseKey == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Supabase credentials are not configured.'),
        ),
      );
      return false;
    }

    final uri = Uri.parse('$supabaseUrl/rest/v1/registrations');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Prefer': 'return=representation',
      },
      body: jsonEncode({
        'student_name': studentName.trim(),
        'phone_number': phoneNumber.trim(),
        'college': collegeName.trim(),
        'email_address': emailAddress.trim(),
        'event_title': event.title,
        'event_venue': event.venue,
        'event_type': event.runtimeType.toString(),
        'registered_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );

    return response.statusCode == 201;
  }

  Widget _buildEventGallery() {
    final galleryImages = _festEvents.isNotEmpty
        ? _festEvents[0].getGalleryImages()
        : [];
    if (galleryImages.isEmpty) {
      return Center(
        child: Text(
          'No images available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _galleryController,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index) {
            setState(() {
              _currentGalleryIndex = index;
            });
            _resetGalleryAutoPlay();
          },
          itemCount: galleryImages.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                galleryImages[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image not found',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Previous button
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _prevGalleryImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.4 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        // Next button
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: GestureDetector(
              onTap: _nextGalleryImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha((0.4 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        // Indicator dots at the bottom
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              galleryImages.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentGalleryIndex == index
                      ? Colors.white
                      : Colors.white.withAlpha((0.5 * 255).round()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadVoucher(RegistrationData registration) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: format,
            build: (context) => _buildVoucherPage(registration),
          ),
        );
        return pdf.save();
      },
    );
  }

  pw.Widget _buildVoucherPage(RegistrationData registration) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'KLE Haveri BCA Fest Ticket',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Voucher Ticket',
            style: pw.TextStyle(fontSize: 18, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.SizedBox(height: 12),
          pw.Text(
            'Student Name: ${registration.studentName}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Email: ${registration.emailAddress}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Phone: ${registration.phoneNumber}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'College: ${registration.collegeName}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Event: ${registration.eventTitle}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Venue: ${registration.eventVenue}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.Text(
            'Event Type: ${registration.eventType}',
            style: pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Registered On: ${registration.registeredAt.toLocal()}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.Spacer(),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            color: PdfColors.blue100,
            child: pw.Text(
              'Show this voucher at the event entrance.',
              style: pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with social media links
  Widget _buildFooter(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: isMobile ? 80 : 70,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: isMobile
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Follow Us',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialIconButton(
                      Icons.camera_alt,
                      'Instagram',
                      'https://www.instagram.com',
                    ),
                    const SizedBox(width: 12),
                    _buildSocialIconButton(
                      Icons.facebook,
                      'Facebook',
                      'https://www.facebook.com',
                    ),
                    const SizedBox(width: 12),
                    _buildSocialIconButton(
                      Icons.play_circle,
                      'YouTube',
                      'https://www.youtube.com',
                    ),
                    const SizedBox(width: 12),
                    _buildSocialIconButton(
                      Icons.language,
                      'Website',
                      'https://www.klehaveri.edu.in',
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Follow Us: ',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(width: 12),
                _buildSocialIconButton(
                  Icons.camera_alt,
                  'Instagram',
                  'https://www.instagram.com',
                ),
                const SizedBox(width: 16),
                _buildSocialIconButton(
                  Icons.facebook,
                  'Facebook',
                  'https://www.facebook.com',
                ),
                const SizedBox(width: 16),
                _buildSocialIconButton(
                  Icons.play_circle,
                  'YouTube',
                  'https://www.youtube.com',
                ),
                const SizedBox(width: 16),
                _buildSocialIconButton(
                  Icons.language,
                  'Website',
                  'https://www.klehaveri.edu.in',
                ),
              ],
            ),
    );
  }

  /// Build individual social media icon button
  Widget _buildSocialIconButton(IconData icon, String label, String url) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () => _openUrl(url),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.08 * 255).round()),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color.fromARGB(255, 58, 183, 177),
            ),
          ),
        ),
      ),
    );
  }

  /// Open URL in browser
  Future<void> _openUrl(String url) async {
    final Uri urlUri = Uri.parse(url);
    if (await canLaunchUrl(urlUri)) {
      await launchUrl(urlUri, mode: LaunchMode.externalApplication);
    }
  }
}

Widget _buildEventDetailGallery(FestEvent event) {
  final galleryImages = event.getGalleryImages();
  if (galleryImages.isEmpty) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Text(
          'No images available',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  return PageView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: galleryImages.length,
    itemBuilder: (context, index) {
      return Image.asset(
        galleryImages[index],
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade300,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image not found',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class EventDetailPage extends StatelessWidget {
  final FestEvent event;
  final RegistrationData? registration;
  final Future<void> Function(RegistrationData registration)? onDownloadVoucher;

  const EventDetailPage({
    super.key,
    required this.event,
    this.registration,
    this.onDownloadVoucher,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.title),
        backgroundColor: const Color.fromARGB(255, 58, 183, 177),
        foregroundColor: const Color.fromARGB(255, 14, 13, 13),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.12 * 255).round()),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _buildEventDetailGallery(event),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.locationInfo,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.getEventDetails(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (event is TechnicalEvent) ...[
                    Text(
                      'Budget: Rs${(event as TechnicalEvent).budget.toInt()}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (event is CulturalEvent) ...[
                    Text(
                      'Category: ${(event as CulturalEvent).category}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'Certificate: ${(event is Certifiable && (event as Certifiable).offersCertificate) ? 'Available' : 'Not available'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (registration != null && onDownloadVoucher != null) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Download Voucher'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          58,
                          183,
                          177,
                        ),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () => onDownloadVoucher!(registration!),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Event Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This page shows details of the selected fest event with a preview image and a summary of what to expect. Use this screen to review the venue, status, and special notes before joining the event.',
                    style: TextStyle(fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
