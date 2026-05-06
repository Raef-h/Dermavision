import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/classifier_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _scanAnim;
  bool _isProcessing = false;
  String? _selectedImagePath;
  String _statusMessage = 'Select an image to begin analysis';

  @override
  void initState() {
    super.initState();
    _scanAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scanAnim.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isProcessing) return;

    // Request permissions
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _showSnack('Camera permission required');
        return;
      }
    } else {
      final status = await Permission.photos.request();
      if (!status.isGranted && !await Permission.storage.isGranted) {
        // On older Android, try storage
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          _showSnack('Gallery permission required');
          return;
        }
      }
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (picked == null || !mounted) return;

      setState(() {
        _selectedImagePath = picked.path;
        _statusMessage = 'Image selected — tap Analyze';
      });
    } catch (e) {
      _showSnack('Could not pick image: $e');
    }
  }

  Future<void> _analyzeImage() async {
    if (_selectedImagePath == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Running analysis…';
    });

    try {
      final result = await ClassifierService.classify(_selectedImagePath!);

      if (!mounted) return;

      await Navigator.pushNamed(
        context,
        '/result',
        arguments: ResultScreenArgs(
          imagePath: _selectedImagePath!,
          result: result,
        ),
      );

      // Reset state on return
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Select an image to begin analysis';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Analysis failed. Try again.';
      });
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMainContent()),
              _buildBottomActions(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DERMAVISION',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 4,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'Skin Analysis',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Offline badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppTheme.success, blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'OFFLINE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.success,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Scan zone
          Expanded(child: _buildScanZone()),
          const SizedBox(height: 20),
          // Status message
          _buildStatusCard(),
        ],
      ),
    );
  }

  Widget _buildScanZone() {
    return GestureDetector(
          onTap: _selectedImagePath == null ? () => _showPickSheet() : null,
          child: AnimatedBuilder(
            animation: _scanAnim,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.accent.withValues(
                      alpha: 0.3 + 0.2 * _scanAnim.value,
                    ),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentGlow,
                      Colors.transparent,
                      AppTheme.accentGlow.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(27),
                  child: _selectedImagePath != null
                      ? _buildSelectedImage()
                      : _buildEmptyState(),
                ),
              );
            },
          ),
        )
        .animate()
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }

  Widget _buildSelectedImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
        // Gradient overlay
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.5)],
            ),
          ),
        ),
        // Change image button
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: _showPickSheet,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.glass,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: AppTheme.surfaceAlt.withValues(alpha: 0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated scan icon
          AnimatedBuilder(
            animation: _scanAnim,
            builder: (_, __) {
              return Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accent.withValues(
                      alpha: 0.4 + 0.2 * _scanAnim.value,
                    ),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withValues(
                        alpha: 0.15 * _scanAnim.value,
                      ),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.document_scanner_rounded,
                  size: 42,
                  color: AppTheme.accent.withValues(
                    alpha: 0.7 + 0.3 * _scanAnim.value,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Tap to select image',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Camera or Gallery',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: AppTheme.glassCard(radius: 16),
      child: Row(
        children: [
          if (_isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.accent,
              ),
            )
          else
            Icon(
              _selectedImagePath != null
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              size: 16,
              color: _selectedImagePath != null
                  ? AppTheme.success
                  : AppTheme.accent,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms);
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Analyze button (only shown when image selected)
          if (_selectedImagePath != null)
            SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _analyzeImage,
                    style:
                        (Theme.of(context).elevatedButtonTheme.style ??
                                const ButtonStyle())
                            .copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                _isProcessing
                                    ? AppTheme.accent.withValues(alpha: 0.5)
                                    : AppTheme.accent,
                              ),
                              overlayColor: WidgetStateProperty.all(
                                Colors.white.withValues(alpha: 0.1),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                    child: _isProcessing
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Analyzing…',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.analytics_rounded, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Analyze Image',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.15, curve: Curves.easeOut),

          if (_selectedImagePath != null) const SizedBox(height: 12),

          // Camera / Gallery row
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () => _pickImage(ImageSource.camera),
                  disabled: _isProcessing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () => _pickImage(ImageSource.gallery),
                  disabled: _isProcessing,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
        ],
      ),
    );
  }

  void _showPickSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickSheet(
        onCamera: () {
          Navigator.pop(context);
          _pickImage(ImageSource.camera);
        },
        onGallery: () {
          Navigator.pop(context);
          _pickImage(ImageSource.gallery);
        },
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: disabled
              ? AppTheme.surfaceAlt.withValues(alpha: 0.5)
              : AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: disabled ? AppTheme.textMuted : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: disabled ? AppTheme.textMuted : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _PickSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Source',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          _SheetOption(
            icon: Icons.camera_alt_rounded,
            title: 'Camera',
            subtitle: 'Take a new photo',
            onTap: onCamera,
          ),
          const SizedBox(height: 12),
          _SheetOption(
            icon: Icons.photo_library_rounded,
            title: 'Gallery',
            subtitle: 'Choose from existing photos',
            onTap: onGallery,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentGlow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
