import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';
import '../../helpers/database_helper.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      image: 'assets/images/onboarding_1.svg',
      title: 'Belajar Bersama Teman',
      description: 'Bergabunglah dengan komunitas belajar yang seru dan interaktif. Temukan teman sekelas dan belajar bersama!',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_2.svg',
      title: 'Pembelajaran Online',
      description: 'Akses materi pembelajaran kapan saja, di mana saja. Belajar jadi lebih fleksibel dan menyenangkan!',
    ),
    OnboardingData(
      image: 'assets/images/onboarding_3.svg',
      title: 'Raih Prestasi Terbaik',
      description: 'Kembangkan potensi diri dan raih prestasi akademik yang membanggakan bersama Seangkatan.id!',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _navigateToLogin(),
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Page view
                SizedBox(
                  height: screenHeight * 0.65, // Responsive height
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _onboardingData.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration - responsive size
                            SizedBox(
                              height: screenHeight * 0.3,
                              width: screenWidth * 0.7,
                              child: SvgPicture.asset(
                                _onboardingData[index].image,
                                fit: BoxFit.contain,
                              ),
                            ),
                            
                            SizedBox(height: screenHeight * 0.03),
                            
                            // Title - responsive font size
                            Text(
                              _onboardingData[index].title,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.065,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            SizedBox(height: screenHeight * 0.02),
                            
                            // Description - responsive font size
                            Text(
                              _onboardingData[index].description,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey[600],
                                height: 1.6,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Page indicators and navigation
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    children: [
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _onboardingData.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF4F46E5)
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Navigation button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage == _onboardingData.length - 1) {
                              _navigateToLogin();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1
                                ? 'Mulai Sekarang'
                                : 'Lanjutkan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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
        ),
      ),
    );
  }

  void _navigateToLogin() async {
    // Mark welcome as seen before navigating
    final dbHelper = DatabaseHelper();
    await dbHelper.setWelcomeSeen();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }
}

class OnboardingData {
  final String image;
  final String title;
  final String description;

  OnboardingData({
    required this.image,
    required this.title,
    required this.description,
  });
}