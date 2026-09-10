import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class EditRiderProfileScreen extends StatefulWidget {
  const EditRiderProfileScreen({super.key});

  @override
  State<EditRiderProfileScreen> createState() => _EditRiderProfileScreenState();
}

class _EditRiderProfileScreenState extends State<EditRiderProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _bloodGroupController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      LuxAudioHapticsService.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isSaving = false);
        showLuxSnack(context, 'Rider profile & emergency medical data synced to Cloud Vault.', variant: LuxSnackVariant.info);
        Navigator.pop(context);
      }
    }
  }

  void _uploadProfilePhoto() {
    LuxAudioHapticsService.mediumImpact();
    showLuxSnack(context, 'Photo avatar updated from device gallery.', variant: LuxSnackVariant.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EDIT RIDER PROFILE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.hyperOrange),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined, color: RoadOSColors.cyberCyan),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Photo Avatar with Edit Badge
                  GestureDetector(
                    onTap: _uploadProfilePhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LuxGradients.hyperOrange,
                            boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Icon(Icons.person, size: 54, color: Colors.white),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RoadOSColors.cyberCyan,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Personal Info Section
                  _buildCardSection(
                    title: 'PERSONAL RIDER INFORMATION',
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _dobController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', prefixIcon: Icon(Icons.cake_outlined)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Emergency & Medical Info Section
                  _buildCardSection(
                    title: 'ICE EMERGENCY & MEDICAL INFO',
                    children: [
                      TextFormField(
                        controller: _bloodGroupController,
                        style: const TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.w900),
                        decoration: const InputDecoration(labelText: 'Blood Group', prefixIcon: Icon(Icons.bloodtype_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emergencyContactController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Emergency ICE Contact', prefixIcon: Icon(Icons.contact_phone_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Residential Address', prefixIcon: Icon(Icons.home_outlined)),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _medicalNotesController,
                        maxLines: 2,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(labelText: 'Medical Notes & Allergies', prefixIcon: Icon(Icons.medical_services_outlined)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  RoadOSButton(
                    label: 'SAVE RIDER PROFILE',
                    icon: Icons.cloud_done_rounded,
                    gradient: LuxGradients.hyperOrange,
                    isLoading: _isSaving,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.textMuted),
        ),
        const SizedBox(height: 8),
        RoadOSCard(
          
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    );
  }
}
