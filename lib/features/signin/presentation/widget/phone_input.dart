import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhoneInput extends StatefulWidget {
  final String initialCountryCode; // e.g. 'NG'
  const PhoneInput({super.key, this.initialCountryCode = 'NG'});

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  Country? _selectedCountry;
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode:
          true, 
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flag = _selectedCountry?.flagEmoji ?? '🇳🇬'; 
    final dialCode = _selectedCountry?.phoneCode ?? '234';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _openCountryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // circular flag
                ClipOval(
                  child: Container(
                    color: Colors.white.withOpacity(0.08),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    child: Text(
                      flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // dial code
                Text(
                  '+$dialCode',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white70,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(width: 1, height: 36, color: Colors.white12),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Mobile Number',
                hintStyle: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
                counterText:
                    '', 
              ),
              onChanged: (value) {
                // debugPrint('+${dialCode}${value}');
              },
            ),
          ),
        ],
      ),
    );
  }
}
