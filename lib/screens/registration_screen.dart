import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../managers/game_manager.dart';
import '../managers/save_manager.dart';
import '../utils/constants.dart';
import '../utils/palette.dart';
import '../utils/countries.dart';

class RegistrationScreen extends StatefulWidget {
  final GameManager gameManager;
  final VoidCallback onRegistered;

  const RegistrationScreen({
    super.key,
    required this.gameManager,
    required this.onRegistered,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedCountry = 'DO';
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // Siempre forzar 'DO' al abrir la pantalla de registro por primera vez
    _selectedCountry = 'DO';
  }

  String _getFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️';
    int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMsg = 'El nombre de usuario no puede estar vacío');
      return;
    }
    if (name.length > 13) {
      setState(() => _errorMsg = 'El nombre no puede tener más de 13 caracteres');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: name.toLowerCase())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        if (query.docs.first.id != widget.gameManager.authManager.playerId) {
          setState(() {
            _errorMsg = 'El nombre de usuario "$name" ya está en uso. ¡Elige otro!';
            _isLoading = false;
          });
          return;
        }
      }

      await widget.gameManager.authManager.updateProfile(name, _selectedCountry);
      
      if (widget.gameManager.authManager.isLoggedIn) {
        await FirebaseFirestore.instance.collection('users').doc(widget.gameManager.authManager.playerId).set({
          'username': name.toLowerCase(),
          'displayName': name,
          'countryCode': _selectedCountry,
        }, SetOptions(merge: true));
      }

      await widget.gameManager.saveManager.setHasRegistered(true);
      widget.onRegistered();
    } catch (e) {
      setState(() {
        _errorMsg = 'Error al verificar usuario. Revisa tu conexión.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.gameManager.saveManager.currentTheme;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: Palette.menuGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', height: 220)
                        .animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 8),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Elige con cuidado, cazador.\nTu nombre y país serán permanentes.',
                              style: GoogleFonts.fredoka(
                                fontSize: 14,
                                color: Colors.amber.shade100,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameCtrl,
                            maxLength: 13,
                            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'Nombre de Usuario Único',
                              labelStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              counterStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.black26,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            menuMaxHeight: 250,
                            value: _selectedCountry,
                            dropdownColor: const Color(0xFF2C2C2C),
                            style: GoogleFonts.fredoka(color: Colors.white, fontSize: 18),
                            decoration: const InputDecoration(
                              labelText: 'País (Nacionalidad)',
                              labelStyle: TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                              filled: true,
                              fillColor: Colors.black26,
                            ),
                            items: countryCodes.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text('${_getFlag(e.key)} ${e.value}'),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCountry = val);
                            },
                          ),
                          
                          if (_errorMsg != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMsg!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ).animate().shake(),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43E97B),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 8,
                              ),
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : Text('EMPEZAR AVENTURA', style: GoogleFonts.fredoka(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms).scale(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
