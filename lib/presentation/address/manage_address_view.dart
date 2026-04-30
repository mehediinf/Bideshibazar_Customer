// lib/presentation/address/manage_address_view.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/address_model.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/services/available_shops_service.dart';
import '../products/products_near_you_view.dart';
import 'manual_address_view.dart';

class ManageAddressView extends StatefulWidget {
  final bool isFromCheckout; // NEW: Flag to check if called from checkout

  const ManageAddressView({
    super.key,
    this.isFromCheckout = false, // Default false for backward compatibility
  });

  @override
  State<ManageAddressView> createState() => _ManageAddressViewState();
}

class _ManageAddressViewState extends State<ManageAddressView> {
  final List<AddressModel> addresses = [];
  int selectedIndex = 0;
  bool isLoadingLocation = false;
  bool isLoading = true;
  bool isCheckingShops = false;

  static const String _storageKey = 'saved_addresses';

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedData = prefs.getString(_storageKey);
      final selectedAddressJson = await SharedPrefsHelper.getSelectedAddress();

      if (savedData != null && savedData.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(savedData);
        addresses.clear();
        addresses.addAll(
          jsonList.map((json) => AddressModel.fromJson(json)).toList(),
        );
      }

      if (selectedAddressJson != null) {
        final autoFetchedAddress = AddressModel.fromJson(selectedAddressJson);

        bool exists = addresses.any((addr) =>
        addr.lat == autoFetchedAddress.lat &&
            addr.lon == autoFetchedAddress.lon);

        if (!exists) {
          addresses.insert(0, autoFetchedAddress);
          selectedIndex = 0;
          await _saveAddresses();
        } else {
          selectedIndex = addresses.indexWhere((addr) =>
          addr.lat == autoFetchedAddress.lat &&
              addr.lon == autoFetchedAddress.lon);
        }
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Error loading addresses: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
      addresses.map((a) => a.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving addresses: $e');
    }
  }

  /// Check available shops and navigate if products exist
  Future<void> _checkAndNavigateToProducts(AddressModel address) async {
    setState(() => isCheckingShops = true);

    try {
      debugPrint('📍 Checking available shops for: ${address.fullAddress}');

      final response = await AvailableShopsService.fetchAvailableShops(
        street: address.road,
        city: address.city,
        postcode: address.postCode,
        lat: address.lat ?? 0.0,
        lon: address.lon ?? 0.0,
      );

      // Show API message in toast
      if (response['message'] != null) {
        _showToast(response['message'].toString());
      }

      // Save seller IDs only when we actually received a non-empty list
      if (response['seller_ids'] != null && response['seller_ids'] is List) {
        final List<dynamic> sellerIdsDynamic = response['seller_ids'];
        final List<int> sellerIds =
        sellerIdsDynamic.map((id) => id as int).toList();
        if (sellerIds.isNotEmpty) {
          await SharedPrefsHelper.saveSellerIds(sellerIds);
          debugPrint('✅ Saved ${sellerIds.length} seller IDs');
        } else {
          debugPrint('⚠️ Empty seller_ids list received; keeping existing cache');
        }
      } else {
        final message = (response['message'] ?? '').toString().toLowerCase();
        final isBotBlocked =
            message.contains('imunify360') ||
            message.contains('bot-protection') ||
            message.contains('access denied');

        if (isBotBlocked) {
          debugPrint(
            '⚠️ Available shops blocked by bot protection; preserving seller cache',
          );
        } else {
          // Save empty list only when the API truly indicates no sellers
          await SharedPrefsHelper.saveSellerIds([]);
          debugPrint('⚠️ No seller_ids found, saved empty list');
        }
      }

      setState(() => isCheckingShops = false);

      // Check if products are available
      if (response['sellers'] != null &&
          (response['sellers'] as List).isNotEmpty) {
        // Navigate to Products Near You
        if (mounted) {
          final sellers = response['sellers'] as List<dynamic>;
          final street = response['street'] ?? '';

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductsNearYouView(
                sellers: sellers.cast<Map<String, dynamic>>(),
                street: street,
              ),
            ),
          );

          // After returning from Products Near You, go back to home
          if (mounted) {
            Navigator.pop(context, address);
          }
        }
      } else {
        // No products available, just return to home
        if (mounted) {
          Navigator.pop(context, address);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking available shops: $e');
      setState(() => isCheckingShops = false);

      debugPrint('⚠️ Preserving seller cache after available shops error');

      // Show error message
      _showToast(AppErrorHelper.toUserMessage(e));

      // Even if error, return the address
      if (mounted) {
        Navigator.pop(context, address);
      }
    }
  }

  /// NEW: Return address directly to checkout
  void _returnAddressToCheckout(AddressModel address) {
    final addressMap = {
      'address': address.fullAddress,
      'city': address.city,
      'postcode': address.postCode,
      'road': address.road,
      'lat': address.lat,
      'lon': address.lon,
    };
    Navigator.pop(context, addressMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isFromCheckout ? "Select Address" : "Manage Address"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0095FF),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _primaryButton(
                    text: "+ Use Current Location",
                    onTap: isLoadingLocation ? null : _fetchCurrentLocation,
                    isLoading: isLoadingLocation,
                  ),
                  const SizedBox(height: 12),
                  _outlinedButton(
                    text: "+ Add different Manual address",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ManualAddressView(),
                        ),
                      );

                      if (result != null && result is AddressModel) {
                        setState(() {
                          addresses.add(result);
                          selectedIndex = addresses.length - 1;
                        });
                        await _saveAddresses();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: addresses.isEmpty
                        ? Center(
                      child: Text(
                        'No addresses added yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    )
                        : ListView.builder(
                      itemCount: addresses.length,
                      itemBuilder: (_, i) => _addressCard(addresses[i], i),
                    ),
                  ),
                ],
              ),
            ),
          if (isCheckingShops)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Checking available shops...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: addresses.isEmpty || isCheckingShops
                ? null
                : () async {
              final selected = addresses[selectedIndex];

              // Save the selected address
              await SharedPrefsHelper.saveSelectedAddress(selected.toJson());

              // NEW: If called from checkout, just return address
              if (widget.isFromCheckout) {
                _returnAddressToCheckout(selected);
              } else {
                // Original behavior: Check for shops and navigate
                await _checkAndNavigateToProducts(selected);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0095FF),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: isCheckingShops
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : Text(
              widget.isFromCheckout ? "SELECT ADDRESS" : "CONFIRM",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        setState(() => isLoadingLocation = false);
        _showLocationServiceDialog();
        return;
      }

      LocationPermission geoPermission = await Geolocator.checkPermission();
      debugPrint('Geolocator permission status: $geoPermission');

      if (geoPermission == LocationPermission.denied) {
        geoPermission = await Geolocator.requestPermission();
        debugPrint('After request - Geolocator permission: $geoPermission');

        if (geoPermission == LocationPermission.whileInUse ||
            geoPermission == LocationPermission.always) {
          await SharedPrefsHelper.setLocationPermissionGranted(true);
        }
      }

      if (geoPermission == LocationPermission.denied) {
        setState(() => isLoadingLocation = false);
        _showToast('Location permission denied');
        return;
      }

      if (geoPermission == LocationPermission.deniedForever) {
        setState(() => isLoadingLocation = false);
        _showPermissionDialog();
        return;
      }

      debugPrint('Fetching current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      debugPrint('Position: ${position.latitude}, ${position.longitude}');

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        debugPrint('Placemark: ${place.toString()}');

        String fullAddress = _formatAddress(place);

        AddressModel model = AddressModel(
          fullAddress: fullAddress,
          road: place.street ?? '',
          house: place.subThoroughfare ?? '',
          room: '',
          postCode: place.postalCode ?? '',
          city: place.locality ?? place.subAdministrativeArea ?? '',
          lat: position.latitude,
          lon: position.longitude,
        );

        bool exists = addresses.any(
                (addr) => addr.lat == model.lat && addr.lon == model.lon);

        if (!exists) {
          setState(() {
            addresses.add(model);
            selectedIndex = addresses.length - 1;
            isLoadingLocation = false;
          });

          await _saveAddresses();
          await SharedPrefsHelper.saveSelectedAddress(model.toJson());
          _showToast('Current location added successfully');
        } else {
          setState(() {
            isLoadingLocation = false;
            selectedIndex = addresses.indexWhere(
                    (addr) => addr.lat == model.lat && addr.lon == model.lon);
          });
          _showToast('This location already exists');
        }
      } else {
        setState(() => isLoadingLocation = false);
        _showToast('Could not determine address from current location');
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');
      setState(() => isLoadingLocation = false);

      if (e.toString().contains('timeout')) {
        _showToast('Location request timed out. Please check your GPS signal.');
      } else if (e.toString().contains('PERMISSION')) {
        _showToast('Location permission denied. Please enable it in settings.');
      } else {
        _showToast(AppErrorHelper.toUserMessage(e));
      }
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text(
          'Location services are disabled on your device. '
              'Please enable them in Settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. '
              'Please enable it from app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Placemark place) {
    List<String> parts = [];

    if (place.subThoroughfare?.isNotEmpty == true) parts.add(place.subThoroughfare!);
    if (place.street?.isNotEmpty == true) parts.add(place.street!);
    if (place.subLocality?.isNotEmpty == true) parts.add(place.subLocality!);
    if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
    if (place.postalCode?.isNotEmpty == true) parts.add(place.postalCode!);
    if (place.country?.isNotEmpty == true) parts.add(place.country!);

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel a, int index) {
    final isSelected = index == selectedIndex;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF0095FF) : Colors.grey.shade300,
          width: 2,
        ),
        color: isSelected ? const Color(0xFF0095FF).withOpacity(0.05) : Colors.white,
      ),
      child: Row(
        children: [
          Radio<int>(
            value: index,
            groupValue: selectedIndex,
            onChanged: (v) => setState(() => selectedIndex = v!),
            activeColor: const Color(0xFF0095FF),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.fullAddress,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Road: ${a.road}, House: ${a.house}, Room: ${a.room}\n"
                      "Post: ${a.postCode}, City: ${a.city}",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                if (a.lat != null && a.lon != null)
                  Text(
                    "Lat: ${a.lat!.toStringAsFixed(6)}, Lon: ${a.lon!.toStringAsFixed(6)}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ManualAddressView(address: a),
                    ),
                  );

                  if (updated != null && updated is AddressModel) {
                    setState(() {
                      addresses[index] = updated;
                    });
                    await _saveAddresses();
                  }
                },
                icon: const Icon(Icons.edit, size: 20),
                color: const Color(0xFF0095FF),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: () async {
                  setState(() {
                    addresses.removeAt(index);
                    if (selectedIndex >= addresses.length &&
                        addresses.isNotEmpty) {
                      selectedIndex = addresses.length - 1;
                    } else if (addresses.isEmpty) {
                      selectedIndex = 0;
                    }
                  });
                  await _saveAddresses();
                  _showToast('Address deleted');
                },
                icon: const Icon(Icons.delete, size: 20),
                color: Colors.red.shade400,
                tooltip: 'Delete',
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0095FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _outlinedButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0095FF),
          side: const BorderSide(color: Color(0xFF0095FF)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
