import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/ai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AIService _aiService = AIService();
  File? _selectedImage;
  Map<String, dynamic>? _prediction;
  String? _description;
  bool _isLoading = false;
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() {
      _isLoading = true;
    });
    await _aiService.loadModel();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _prediction = null;
        _description = null;
        _isLoading = true;
      });

      final result = await _aiService.predictImage(_selectedImage!);
      String? desc;
      if (result != null) {
        final label = result['label']?.toString().trim() ?? '';
        desc = _aiService.getDescription(label);
      }

      setState(() {
        _prediction = result;
        _description = desc;
        _isLoading = false;
      });

      _animationController.forward();

      // Auto scroll to result after animation completes
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_scrollController.hasClients && mounted) {
          final maxScroll = _scrollController.position.maxScrollExtent;
          final currentScroll = _scrollController.position.pixels;
          final targetScroll = maxScroll * 0.7; // Scroll to 70% instead of full

          if (targetScroll > currentScroll) {
            _scrollController.animateTo(
              targetScroll,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        }
      });
    }
  }

  void _resetToInitialState() {
    setState(() {
      _selectedImage = null;
      _prediction = null;
      _description = null;
      _isLoading = false;
    });

    // Reset animation controllers
    _animationController.reset();

    // Scroll back to top
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    // Show a subtle feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reset to start'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  AppBar _buildAppBar(TextTheme textTheme) {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: const Color(0xFF4CAF50),
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 32,
              height: 32,
              errorBuilder:
                  (context, error, stackTrace) => const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Nutrition Scanner',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Identify fruits & vegetables',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Tombol Reset
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => _resetToInitialState(),
            tooltip: 'Reset to start',
          ),
        ),
        // Tombol Tips
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(
              Icons.lightbulb_outline_rounded,
              color: Colors.white,
            ),
            onPressed: () => _showTipsDialog(textTheme),
            tooltip: 'Tips for best results',
          ),
        ),
      ],
    );
  }

  Widget _buildImageContainer(Size size) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 32.0,
      ), // Ubah dari 16.0 ke 32.0
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color:
                      _selectedImage != null
                          ? Colors.white.withOpacity(0.5)
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: size.height * 0.36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white,
                  gradient:
                      _selectedImage == null
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white, const Color(0xFFE8F5E9)],
                          )
                          : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child:
                      _selectedImage != null
                          ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Hero(
                                tag: 'selectedImage',
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Add a subtle gradient overlay for better contrast
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.1),
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                              if (_prediction != null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: ClipRRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              Colors.black.withOpacity(0.7),
                                              Colors.black.withOpacity(0.5),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _prediction!['displayLabel'] ??
                                                    'Identified',
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                      shadows: [
                                                        Shadow(
                                                          color: Colors.black
                                                              .withOpacity(0.5),
                                                          blurRadius: 5,
                                                        ),
                                                      ],
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                          : Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Stack(
                              children: [
                                // Decorative dots pattern
                                Positioned(
                                  top: 20,
                                  right: 30,
                                  child: Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 20,
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                // Content
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF4CAF50,
                                              ).withOpacity(0.2),
                                              blurRadius: 20,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: ShaderMask(
                                          shaderCallback:
                                              (bounds) => const LinearGradient(
                                                colors: [
                                                  Color(0xFF66BB6A),
                                                  Color(0xFF2E7D32),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ).createShader(bounds),
                                          child: const Icon(
                                            Icons.camera_enhance_rounded,
                                            color: Colors.white,
                                            size: 48,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        'Take a photo or select from gallery',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: const Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 36.0,
                                        ),
                                        child: Text(
                                          'Make sure the item is clearly visible',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            letterSpacing: 0.2,
                                          ),
                                          textAlign: TextAlign.center,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(TextTheme textTheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                color: Colors.white.withOpacity(0.9),
                strokeWidth: 6,
                backgroundColor: Colors.white.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing...',
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    } else if (_prediction != null && _description != null) {
      return _buildResultCard(textTheme);
    } else if (_selectedImage != null) {
      return _buildErrorCard(textTheme);
    }
    return const SizedBox.shrink();
  }

  Widget _buildResultCard(TextTheme textTheme) {
    final isNotFruitOrVegetable =
        _prediction!['displayLabel']?.toString().toLowerCase().contains(
          'not fruit or vegetable',
        ) ??
        false;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isNotFruitOrVegetable) ...[
                            // Icon tanda seru di sebelah kiri tulisan
                            Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.error_rounded,
                                color: Colors.red[700],
                                size: 24,
                              ),
                            ),
                            // Tulisan "Not Identified"
                            Text(
                              'Not Identified',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                                fontSize: 24,
                              ),
                            ),
                          ] else ...[
                            // Untuk case berhasil diidentifikasi (tanpa icon)
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Identified as ${_prediction!['displayLabel'] ?? 'Unknown'}',
                                    style: textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2E7D32),
                                      fontSize: 24,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Confidence percentage in header
                                  if (_prediction!['confidence'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getConfidenceColor(
                                            _prediction!['confidence'],
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: _getConfidenceColor(
                                              _prediction!['confidence'],
                                            ).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.analytics_outlined,
                                              size: 16,
                                              color: _getConfidenceColor(
                                                _prediction!['confidence'],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${(_prediction!['confidence'] * 100).toStringAsFixed(1)}% • ${_getConfidenceText(_prediction!['confidence'])}',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: _getConfidenceColor(
                                                      _prediction!['confidence'],
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isNotFruitOrVegetable) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.orange[800],
                                      size: 36,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'Please try again with a clear image of a fruit or vegetable.',
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: Colors.orange[800],
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildIntegratedActionButtons(textTheme),
                            const SizedBox(height: 32),
                          ] else ...[
                            // Nutrition information card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFE8F5E9),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header with icon
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.eco_rounded,
                                          color: Color(0xFF4CAF50),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          'Nutritional Information',
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF2E7D32),
                                                fontSize: 16,
                                                letterSpacing: 0.3,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  // Nutritional content
                                  Text(
                                    _description!
                                        .replaceAll(RegExp(r'\s+'), ' ')
                                        .replaceAll(
                                          RegExp(r'\.([A-Z])'),
                                          '. \$1',
                                        )
                                        .trim(),
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[800],
                                      height: 1.7,
                                      fontSize: 15,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              height: 1,
                              color: const Color(0xFFE8F5E9),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            const SizedBox(height: 16),
                            _buildIntegratedActionButtons(textTheme),
                            const SizedBox(height: 32),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorCard(TextTheme textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red[700],
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Unable to Identify',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn\'t identify this item. Please try again with a clear image of a fruit or vegetable.',
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.grey[700],
                height: 1.5,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildIntegratedActionButtons(textTheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedActionButtons(TextTheme textTheme) {
    return Row(
      children: [
        Expanded(
          child: _buildCompactButton(
            label: 'Camera',
            icon: Icons.camera_alt_rounded,
            onTap: _isLoading ? null : () => _pickImage(ImageSource.camera),
            textTheme: textTheme,
            primary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildCompactButton(
            label: 'Gallery',
            icon: Icons.photo_library_rounded,
            onTap: _isLoading ? null : () => _pickImage(ImageSource.gallery),
            textTheme: textTheme,
            primary: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required TextTheme textTheme,
    required bool primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFF4CAF50) : const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          boxShadow:
              primary
                  ? [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
          border: Border.all(
            color:
                primary
                    ? Colors.transparent
                    : const Color(0xFF4CAF50).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: primary ? Colors.white : const Color(0xFF4CAF50),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: primary ? Colors.white : const Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required TextTheme textTheme,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4CAF50),
        padding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 24,
        ), // Ubah dari 16 ke 20
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black26,
        minimumSize: const Size(double.infinity, 56), // Tambahkan minimum size
      ),
      icon: Icon(icon, size: 24), // Perbesar icon sedikit
      label: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4CAF50),
          letterSpacing: 0.3,
          fontSize: 16, // Perbesar text sedikit
        ),
      ),
    );
  }

  void _showTipsDialog(TextTheme textTheme) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.lightbulb, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tips for Best Results',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTipItem('Use good lighting', Icons.wb_sunny_outlined),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Center the fruit/vegetable in frame',
                  Icons.crop_free,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Choose a clean background',
                  Icons.panorama_outlined,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Take close-up shots for better accuracy',
                  Icons.zoom_in,
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF4CAF50),
                ),
                label: Text(
                  'Got it!',
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          ),
    );
  }

  Widget _buildTipItem(String tip, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4CAF50)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get confidence color based on percentage
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return const Color(0xFF4CAF50); // Green for high confidence
    } else if (confidence >= 0.6) {
      return const Color(0xFFFF9800); // Orange for medium confidence
    } else {
      return const Color(0xFFF44336); // Red for low confidence
    }
  }

  // Helper method to get confidence text
  String _getConfidenceText(double confidence) {
    if (confidence >= 0.8) {
      return 'High Confidence';
    } else if (confidence >= 0.6) {
      return 'Medium Confidence';
    } else {
      return 'Low Confidence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: Scaffold(
        backgroundColor: const Color(0xFF4CAF50),
        appBar: _buildAppBar(textTheme),
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            overscroll: false,
            physics: const ClampingScrollPhysics(),
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - kToolbarHeight - 70,
              ),
              child: Column(
                children: [
                  // Decorative background pattern
                  Stack(
                    children: [
                      // Multiple decorative circles for more visual interest
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 80,
                        right: 40,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 60,
                        left: -50,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 150,
                        left: 30,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      // Additional floating elements
                      Positioned(
                        top: 40,
                        left: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 120,
                        left: 80,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 200,
                        right: 60,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                      ),

                      // Main content
                      Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.fromLTRB(0, 24, 0, 20),
                        child: Column(
                          children: [
                            _buildImageContainer(size),
                            const SizedBox(height: 24),
                            if (_selectedImage == null && !_isLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildActionButton(
                                        label: 'Camera',
                                        icon: Icons.camera_alt_rounded,
                                        onTap:
                                            () =>
                                                _pickImage(ImageSource.camera),
                                        textTheme: textTheme,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildActionButton(
                                        label: 'Gallery',
                                        icon: Icons.photo_library_rounded,
                                        onTap:
                                            () =>
                                                _pickImage(ImageSource.gallery),
                                        textTheme: textTheme,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading ||
                      _prediction != null ||
                      _selectedImage != null)
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF4CAF50),
                      child: _buildContent(textTheme),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
