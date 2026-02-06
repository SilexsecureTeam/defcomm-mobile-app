import 'package:flutter/material.dart';
import 'package:flutter_app_lock/flutter_app_lock.dart';
import 'package:google_fonts/google_fonts.dart';

enum LockScreenState { initial, pinEntry, success }

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  LockScreenState _currentState = LockScreenState.initial;
  String _pin = "";
  bool _hasError = false;

  final String _correctPin = "1234"; // hardcoded for now

  final Color _bgDark = const Color(0xFF050F02); 
  final Color _bgLight = const Color(0xFF1B3B0A); 
  final Color _primaryGreen = const Color(0xFF8BB82D);

  void _onKeyPressed(String value) {
    if (_currentState != LockScreenState.pinEntry) return;

    setState(() {
      if (value == 'back') {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
          _hasError = false;
        }
      } else {
        if (_pin.length < 4) {
          _pin += value;
          _hasError = false;
        }
      }
    });

    if (_pin.length == 4) {
      _validatePin();
    }
  }

  void _validatePin() async {
    if (_pin == _correctPin) {
      setState(() {
        _currentState = LockScreenState.success;
      });

      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        AppLock.of(context)!.didUnlock();
      }
    } else {
      // Show Error
      setState(() {
        _hasError = true;
        _pin = ""; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgLight.withOpacity(0.4), _bgDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Logo (Top Right)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Icon(Icons.security, color: Colors.white, size: 40), 
                  // SvgPicture.asset('assets/logo.svg', color: Colors.white, width: 40),
                ),
              ),
              
              const Spacer(),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildBody(),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentState) {
      case LockScreenState.initial:
        return _buildInitialView();
      case LockScreenState.pinEntry:
        return _buildPinEntryView();
      case LockScreenState.success:
        return _buildSuccessView();
    }
  }

  Widget _buildInitialView() {
    return Column(
      key: const ValueKey('initial'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Locked Out",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF5A5A), 
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Due to inactivity, your\ndevice was locked for your\nprotection",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 250,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              setState(() {
                _currentState = LockScreenState.pinEntry;
              });
            },
            child: Text(
              "Get back in",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildPinEntryView() {
    return Column(
      key: const ValueKey('pinEntry'),
      children: [
        Text(
          "Locked Out",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF5A5A),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          "Use PIN to unlock your\ndevice",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 40),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            bool isFilled = index < _pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                color: isFilled ? Colors.white : Colors.transparent,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 20),
        if (_hasError)
          Text(
            "Wrong code, please try again",
            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14),
          )
        else
          Text(
            "Send code again  00:20",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),

        const SizedBox(height: 30),
        _buildNumpad(),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Welcome Back",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _primaryGreen,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "you can now resume your\nnormal activities",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[300],
          ),
        ),
        const SizedBox(height: 60),
        SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_primaryGreen),
            strokeWidth: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildNumpad() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          const SizedBox(height: 16),
          _buildRow(['4', '5', '6']),
          const SizedBox(height: 16),
          _buildRow(['7', '8', '9']),
          const SizedBox(height: 16),
          _buildRow(['custom', '0', 'back']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        if (key == 'custom') {
          return const SizedBox(width: 80, child: Center(child: Text("+ * #", style: TextStyle(color: Colors.white, fontSize: 18))));
        }
        if (key == 'back') {
          return InkWell(
             onTap: () => _onKeyPressed('back'),
             borderRadius: BorderRadius.circular(10),
             child: const SizedBox(
               width: 80, 
               height: 60, 
               child: Icon(Icons.backspace_outlined, color: Colors.white),
             ),
          );
        }
        
        // Number Key
        return InkWell(
          onTap: () => _onKeyPressed(key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 80, 
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  key,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_getLetters(key).isNotEmpty)
                Text(
                  _getLetters(key),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
  
  String _getLetters(String key) {
    switch(key) {
      case '2': return 'ABC';
      case '3': return 'DEF';
      case '4': return 'GHI';
      case '5': return 'JKL';
      case '6': return 'MNO';
      case '7': return 'PQRS';
      case '8': return 'TUV';
      case '9': return 'WXYZ';
      default: return '';
    }
  }
}



