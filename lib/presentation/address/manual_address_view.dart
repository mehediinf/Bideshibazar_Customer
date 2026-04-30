// lib/presentation/address/manual_address_view.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import '../../data/models/address_model.dart';

class ManualAddressView extends StatefulWidget {
  final AddressModel? address;

  const ManualAddressView({super.key, this.address});

  @override
  State<ManualAddressView> createState() => _ManualAddressViewState();
}

class _ManualAddressViewState extends State<ManualAddressView> {
  final fullCtrl = TextEditingController();
  final roadCtrl = TextEditingController();
  final houseCtrl = TextEditingController();
  final roomCtrl = TextEditingController();
  final postCtrl = TextEditingController();
  final cityCtrl = TextEditingController();

  double? _latitude;
  double? _longitude;

  bool get isEdit => widget.address != null;

  // Google Maps API Key
  static const String _googleApiKey = "AIzaSyDIvBiG8pVMxAYpC05x0saNux_1GZEwP-A";

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      final a = widget.address!;
      fullCtrl.text = a.fullAddress;
      roadCtrl.text = a.road;
      houseCtrl.text = a.house;
      roomCtrl.text = a.room;
      postCtrl.text = a.postCode;
      cityCtrl.text = a.city;
      _latitude = a.lat;
      _longitude = a.lon;
    }
  }

  Future<List<PlaceSuggestion>> _getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&key=$_googleApiKey'
            '&components=country:at', // Austria (AT country code)
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => PlaceSuggestion(
            description: p['description'],
            placeId: p['place_id'],
          ))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }

    return [];
  }

  Future<void> _onPlaceSelected(PlaceSuggestion suggestion) async {
    try {
      // Get place details
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=${suggestion.placeId}'
            '&key=$_googleApiKey'
            '&fields=geometry,address_components',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];

          _latitude = location['lat'];
          _longitude = location['lng'];

          // Parse address components
          final addressComponents = result['address_components'] as List;

          String road = '';
          String houseNumber = '';
          String postalCode = '';
          String city = '';

          for (var component in addressComponents) {
            final types = component['types'] as List;

            if (types.contains('route')) {
              road = component['long_name'];
            } else if (types.contains('street_number')) {
              houseNumber = component['long_name'];
            } else if (types.contains('postal_code')) {
              postalCode = component['long_name'];
            } else if (types.contains('locality')) {
              city = component['long_name'];
            } else if (city.isEmpty && types.contains('administrative_area_level_1')) {
              city = component['long_name'];
            }
          }

          setState(() {
            fullCtrl.text = suggestion.description;
            roadCtrl.text = road;
            houseCtrl.text = houseNumber;
            postCtrl.text = postalCode;
            cityCtrl.text = city;
          });
        }
      }
    } catch (e) {
      _showToast('Error getting location details: ${e.toString()}');
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? "Edit Address" : "Manual Address",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Address Search Field with TypeAhead
              TypeAheadField<PlaceSuggestion>(
                controller: fullCtrl,
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: "Full Address",
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: fullCtrl.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          fullCtrl.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xff3F51B5)),
                      ),
                    ),
                  );
                },
                suggestionsCallback: (search) => _getPlaceSuggestions(search),
                itemBuilder: (context, suggestion) {
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(
                      suggestion.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                },
                onSelected: (suggestion) {
                  fullCtrl.text = suggestion.description;
                  _onPlaceSelected(suggestion);
                },
                emptyBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No addresses found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                loadingBuilder: (context) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorBuilder: (context, error) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(child: _textField(controller: roadCtrl, hint: "Road")),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(controller: houseCtrl, hint: "House")),
                  const SizedBox(width: 8),
                  Expanded(child: _textField(controller: roomCtrl, hint: "Room")),
                ],
              ),

              const SizedBox(height: 12),
              _textField(controller: postCtrl, hint: "Post Code"),

              const SizedBox(height: 12),
              _textField(controller: cityCtrl, hint: "City"),

              if (_latitude != null && _longitude != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_latitude!.toStringAsFixed(6)}, Lon: ${_longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3F51B5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEdit ? "UPDATE" : "ADD ADDRESS",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAddress() {
    // Validation
    if (fullCtrl.text.trim().isEmpty) {
      _showToast('Please enter full address');
      return;
    }
    if (postCtrl.text.trim().isEmpty) {
      _showToast('Please enter post code');
      return;
    }
    if (cityCtrl.text.trim().isEmpty) {
      _showToast('Please enter city');
      return;
    }

    final updated = AddressModel(
      fullAddress: fullCtrl.text.trim(),
      road: roadCtrl.text.trim(),
      house: houseCtrl.text.trim(),
      room: roomCtrl.text.trim(),
      postCode: postCtrl.text.trim(),
      city: cityCtrl.text.trim(),
      lat: _latitude,
      lon: _longitude,
    );

    Navigator.pop(context, updated);
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff3F51B5)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    fullCtrl.dispose();
    roadCtrl.dispose();
    houseCtrl.dispose();
    roomCtrl.dispose();
    postCtrl.dispose();
    cityCtrl.dispose();
    super.dispose();
  }
}

// Model class for place suggestions
class PlaceSuggestion {
  final String description;
  final String placeId;

  PlaceSuggestion({
    required this.description,
    required this.placeId,
  });
}