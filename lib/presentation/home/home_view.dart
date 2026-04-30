// lib/presentation/home/home_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_viewmodel.dart';
import '../offers/offers_view.dart';
import '../offers/offers_viewmodel.dart';
import '../products/product_list_view.dart';
import '../products/product_list_viewmodel.dart';
import '../products/products_near_you_view.dart';
import '../widgets/category_tabs_widget.dart';
import '../widgets/category_card_widget.dart';
import '../widgets/product_card_widget.dart';
import '../navigationdrawer/navigation_drawer.dart';
import '../address/manage_address_view.dart';
import '../../data/models/address_model.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../products/product_detail_view.dart';
import '../notifications/notifications_screen.dart';
import '../../core/utils/session_manager.dart';
import '../../core/network/api_constants.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/blog_post_service.dart';
import '../help/help_view.dart';
import '../blog_post/blog_post_page.dart';

class HomeView extends StatefulWidget {
  final Function(int)? onSwitchTab;

  const HomeView({super.key, this.onSwitchTab});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with WidgetsBindingObserver {
  final List<String> categoryNames = const [
    "Grocery",
    "Fashion",
    "Air Tickets",
  ];
  final List<Color> bgColors = const [
    Colors.white,
    Color(0xFFFFD9E8),
    Color(0xFFCCECFF),
  ];

  bool _isCheckingPermission = false;
  bool _hasCheckedProducts = false;

  final SessionManager _sessionManager = SessionManager();
  final String _baseUrl = ApiConstants.baseUrl;

  // Add notification count state
  int _unreadNotificationCount = 0;
  int _unreadBlogPostCount = 0;
  late NotificationService _notificationService;
  final BlogPostService _blogPostService = BlogPostService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applySystemUiStyle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapHome();
    });
  }

  Future<void> _bootstrapHome() async {
    await _loadSavedAddress();
    await _initializeNotificationService();

    await Future.wait([
      _initializeApp(),
      _loadNotificationCount(),
      _loadUnreadBlogPostCount(),
    ]);
  }

  void _applySystemUiStyle() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  // Initialize notification service
  Future<void> _initializeNotificationService() async {
    final token = await _sessionManager.getToken();
    _notificationService = NotificationService(baseUrl: _baseUrl, token: token);
  }

  // Load unread notification count
  Future<void> _loadNotificationCount() async {
    try {
      final token = await _sessionManager.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('No auth token, skipping notification count');
        return;
      }

      final result = await _notificationService.getNotifications();
      final unreadCount = result['unread_count'] as int;

      if (mounted) {
        setState(() {
          _unreadNotificationCount = unreadCount;
        });
      }

      debugPrint('Unread notification count: $unreadCount');
    } catch (e) {
      debugPrint('Error loading notification count: $e');
    }
  }

  Future<void> _loadUnreadBlogPostCount() async {
    try {
      final response = await _blogPostService.fetchBlogPosts();
      final posts = response.posts;

      if (posts.isEmpty) {
        if (mounted) {
          setState(() {
            _unreadBlogPostCount = 0;
          });
        }
        return;
      }

      final latestPostId = posts.first.id;
      final seenPostId = await SharedPrefsHelper.getSeenBlogPostId();

      if (seenPostId == null) {
        await SharedPrefsHelper.saveSeenBlogPostId(latestPostId);
        if (mounted) {
          setState(() {
            _unreadBlogPostCount = 0;
          });
        }
        return;
      }

      final unreadCount = posts.where((post) => post.id > seenPostId).length;

      if (mounted) {
        setState(() {
          _unreadBlogPostCount = unreadCount;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread blog post count: $e');
    }
  }

  Future<void> _openBlogPostsPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const BlogPostPage()),
    );

    if (result == true) {
      await _loadUnreadBlogPostCount();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _loadSavedAddress();
      _checkAndRequestLocationPermission();
      _checkAndShowAvailableProducts();
      _loadNotificationCount();
      _loadUnreadBlogPostCount();
    }
  }

  // Load saved address from SharedPrefs and set it in ViewModel
  Future<void> _loadSavedAddress() async {
    try {
      final savedAddress = await SharedPrefsHelper.getSelectedAddress();

      if (savedAddress != null && mounted) {
        final vm = context.read<HomeViewModel>();
        final addressModel = AddressModel.fromJson(savedAddress);
        vm.applySavedAddress(addressModel);

        debugPrint(
          'Address loaded from SharedPrefs: ${addressModel.fullAddress}',
        );
      } else {
        debugPrint('No saved address found in SharedPrefs');
      }
    } catch (e) {
      debugPrint('Error loading saved address: $e');
    }
  }

  // Initialize app - check location and products
  Future<void> _initializeApp() async {
    await _checkAndRequestLocationPermission();
    await _checkAndShowAvailableProducts();
  }

  // Check if we should show available products
  Future<void> _checkAndShowAvailableProducts() async {
    if (_hasCheckedProducts) return;

    try {
      final vm = context.read<HomeViewModel>();

      // Check if address exists
      if (vm.selectedAddress == null) {
        debugPrint('No address selected yet');
        return;
      }

      // Check if seller IDs already exist
      final hasSellerIds = await SharedPrefsHelper.hasSellerIds();

      if (!hasSellerIds) {
        debugPrint('Fetching available shops...');
        final response = await vm.fetchAvailableShops();

        if (response != null) {
          // Show API message in toast
          if (response['message'] != null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(response['message'].toString()),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }

          // Check and show products if available
          if (vm.hasAvailableProducts()) {
            _hasCheckedProducts = true;
            _showProductsNearYou(response);
          }
        }
      } else {
        debugPrint('Seller IDs already exist, skipping auto-check');
      }
    } catch (e) {
      debugPrint('Error checking available products: $e');

      // Show error toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show Products Near You page
  void _showProductsNearYou(Map<String, dynamic> data) {
    if (!mounted) return;

    final sellers = data['sellers'] as List<dynamic>;
    final street = data['street'] ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductsNearYouView(
          sellers: sellers.cast<Map<String, dynamic>>(),
          street: street,
        ),
      ),
    );
  }

  Future<void> _checkAndRequestLocationPermission() async {
    if (_isCheckingPermission) return;

    try {
      _isCheckingPermission = true;

      final savedAddress = await SharedPrefsHelper.getSelectedAddress();
      if (savedAddress != null) {
        debugPrint('Already have saved address, skipping auto-fetch');
        _isCheckingPermission = false;
        return;
      }

      final isGranted = await SharedPrefsHelper.isLocationPermissionGranted();
      if (isGranted) {
        debugPrint('Permission already granted, fetching location...');
        await _fetchAndSaveLocation();
        _isCheckingPermission = false;
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location service is disabled');
        _isCheckingPermission = false;
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        debugPrint('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        await SharedPrefsHelper.setLocationPermissionAsked(true);
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        await SharedPrefsHelper.setLocationPermissionGranted(true);
        await _fetchAndSaveLocation();
      } else if (permission == LocationPermission.deniedForever) {
        await SharedPrefsHelper.setLocationPermissionGranted(false);
        debugPrint('Location permission permanently denied');
        _showPermissionPermanentlyDeniedDialog();
      } else {
        await SharedPrefsHelper.setLocationPermissionGranted(false);
        debugPrint('Location permission denied');
      }

      _isCheckingPermission = false;
    } catch (e) {
      debugPrint('Error checking location permission: $e');
      _isCheckingPermission = false;
    }
  }

  Future<void> _fetchAndSaveLocation() async {
    try {
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

        await SharedPrefsHelper.saveSelectedAddress(model.toJson());

        if (mounted) {
          final vm = context.read<HomeViewModel>();
          await vm.updateSelectedAddress(model);

          // After setting address, check for available products
          await _checkAndShowAvailableProducts();
        }

        debugPrint('Current location saved successfully: $fullAddress');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location set: $fullAddress'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching location: $e');

      if (mounted) {
        String errorMessage = 'Error getting location';
        if (e.toString().contains('timeout')) {
          errorMessage =
              'Location request timed out. Please check your GPS signal.';
        } else if (e.toString().contains('PERMISSION')) {
          errorMessage = 'Location permission denied.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;

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

  void _showPermissionPermanentlyDeniedDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. '
          'Please enable it from app settings to use location features.',
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

    if (place.subThoroughfare?.isNotEmpty == true) {
      parts.add(place.subThoroughfare!);
    }
    if (place.street?.isNotEmpty == true) {
      parts.add(place.street!);
    }
    if (place.subLocality?.isNotEmpty == true) {
      parts.add(place.subLocality!);
    }
    if (place.locality?.isNotEmpty == true) {
      parts.add(place.locality!);
    }
    if (place.postalCode?.isNotEmpty == true) {
      parts.add(place.postalCode!);
    }
    if (place.country?.isNotEmpty == true) {
      parts.add(place.country!);
    }

    return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = context.select<HomeViewModel, int>(
      (vm) => vm.selectedCategory,
    );

    return Scaffold(
      drawer: NavigationDrawerView(),
      body: Container(
        color: bgColors[selectedCategory],
        child: SafeArea(
          top: true,
          bottom: true,
          left: true,
          right: true,
          child: Column(
            children: [
              _header(context),
              CategoryTabsWidget(
                selectedCategory: selectedCategory,
                onCategoryChanged: (index) =>
                    context.read<HomeViewModel>().changeCategory(index),
                categoryNames: categoryNames,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: selectedCategory == 0
                    ? Consumer<HomeViewModel>(
                        builder: (context, vm, _) {
                          return RefreshIndicator(
                            onRefresh: () async {
                              await _loadSavedAddress();
                              await vm.refreshData();
                              _hasCheckedProducts = false;
                              await _checkAndShowAvailableProducts();
                              await _loadNotificationCount();
                              await _loadUnreadBlogPostCount();
                            },
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                children: [
                                  Consumer<OffersViewModel>(
                                    builder: (context, offersVm, child) {
                                      final shouldShowOffersSection =
                                          offersVm.isLoading ||
                                          offersVm.errorMessage != null ||
                                          offersVm.offers.isNotEmpty;

                                      if (!shouldShowOffersSection) {
                                        return const SizedBox.shrink();
                                      }

                                      return const Column(
                                        children: [
                                          RepaintBoundary(child: OffersView()),
                                          SizedBox(height: 16),
                                        ],
                                      );
                                    },
                                  ),
                                  _buildGroceryContent(vm, context),
                                  const SizedBox(height: 24),
                                  RepaintBoundary(
                                    child: Builder(
                                      builder: (context) =>
                                          _buildNeedHelpSection(context),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : _comingSoon(categoryNames[selectedCategory]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (BuildContext context) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.menu_rounded,
                      size: 24,
                      color: Color(0xFF000000),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/app_logo.jpg',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.store_rounded, size: 20);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ManageAddressView()),
                );

                if (result != null && result is AddressModel) {
                  await vm.updateSelectedAddress(result);
                  if (!context.mounted) return;

                  // Show toast message after address update
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Address updated: ${result.fullAddress}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );

                  // Reset and check for available products after address change
                  _hasCheckedProducts = false;
                  await _checkAndShowAvailableProducts();
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Deliver to",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vm.getDisplayAddress(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openBlogPostsPage,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 24,
                      color: Color(0xFFFF6B35),
                    ),
                    if (_unreadBlogPostCount > 0)
                      Positioned(
                        right: -4,
                        top: -5,
                        child: _buildCountBadge(_unreadBlogPostCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final token = await _sessionManager.getToken();
                if (!context.mounted) return;

                // Navigate and reload count when coming back
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(
                      authToken: token,
                      baseUrl: _baseUrl,
                    ),
                  ),
                );

                // Reload notification count after returning from notifications screen
                await _loadNotificationCount();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 24,
                      color: Color(0xFFFF6B35),
                    ),
                    // Show badge only if there are unread notifications
                    if (_unreadNotificationCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: _buildCountBadge(_unreadNotificationCount),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade500,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildGroceryContent(HomeViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return _buildHomeLoadingState();
    }

    if (vm.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              'Error loading data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Unknown error',
              style: TextStyle(fontSize: 13, color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => vm.refreshData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildCategoryGrid(vm, context),
        const SizedBox(height: 24),
        _buildProductSections(vm, context),
      ],
    );
  }

  Widget _buildHomeLoadingState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            itemCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: const Color(0xFFF1ECE5),
              highlightColor: const Color(0xFFFBF8F4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(2, (index) {
              return Padding(
                padding: EdgeInsets.only(bottom: index == 1 ? 0 : 18),
                child: Shimmer.fromColors(
                  baseColor: const Color(0xFFF1ECE5),
                  highlightColor: const Color(0xFFFBF8F4),
                  child: Container(
                    height: 210,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedHelpSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need help?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildHelpButton(
                  icon: Icons.help_outline,
                  label: 'FAQ',
                  color: const Color(0xFF9B4DFF),
                  isCustomImage: false,
                  onTap: () => _openFAQ(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpButton(
                  label: 'Messenger',
                  color: const Color(0xFF9B4DFF),
                  isCustomImage: true,
                  imagePath: 'assets/images/messenger.png',
                  onTap: () => _openMessenger(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHelpButton(
                  icon: Icons.call_outlined,
                  label: 'Call',
                  color: const Color(0xFF9B4DFF),
                  isCustomImage: false,
                  onTap: () => _makePhoneCall(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHelpButton(
                  label: 'WhatsApp',
                  color: const Color(0xFF9B4DFF),
                  isCustomImage: true,
                  imagePath: 'assets/images/whatsapp.png',
                  onTap: () => _openWhatsApp(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpButton({
    IconData? icon,
    required String label,
    required Color color,
    required bool isCustomImage,
    String? imagePath,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCustomImage && imagePath != null)
                Image.asset(
                  imagePath,
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image, color: color, size: 20);
                  },
                )
              else if (icon != null)
                Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Open FAQ page
  void _openFAQ(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpView()),
    );
  }

  // Open Messenger
  Future<void> _openMessenger(BuildContext context) async {
    try {
      final messengerUrl = Uri.parse('https://www.facebook.com/bidesibazar');
      if (await canLaunchUrl(messengerUrl)) {
        await launchUrl(messengerUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open Messenger'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening Messenger: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Messenger app not installed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Open WhatsApp
  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      const phoneNumber = '+4368864179877';
      final whatsappUrl = Uri.parse(
        'https://wa.me/${phoneNumber.replaceAll('+', '')}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening WhatsApp: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp not installed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Make phone call
  Future<void> _makePhoneCall(BuildContext context) async {
    try {
      const phoneNumber = '+4368864179877';
      final telUrl = Uri.parse('tel:$phoneNumber');

      if (await canLaunchUrl(telUrl)) {
        await launchUrl(telUrl);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot make phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error making phone call: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error initiating call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCategoryGrid(HomeViewModel vm, BuildContext context) {
    if (vm.subcategories.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No categories available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    final displaySubcategories = vm.subcategories.take(6).toList();
    final hasMore = vm.subcategories.length > 6;

    return Column(
      children: [
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: displaySubcategories.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
          ),
          itemBuilder: (context, index) {
            final subcategory = displaySubcategories[index];
            return CategoryCardWidget(subcategory: subcategory);
          },
        ),
        if (hasMore) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (widget.onSwitchTab != null) {
                    widget.onSwitchTab!(1);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.grid_view_rounded,
                        color: Color(0xFFFF6B35),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'View All Categories',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${vm.subcategories.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
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
      ],
    );
  }

  Widget _buildProductSections(HomeViewModel vm, BuildContext context) {
    if (vm.subcategoriesWithProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: vm.subcategoriesWithProducts
          .map((subcategoryData) {
            return RepaintBoundary(
              child: _buildSubcategorySection(
                context,
                vm,
                subcategoryData['name'],
                subcategoryData['sellers'],
              ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildSubcategorySection(
    BuildContext context,
    HomeViewModel vm,
    String subcategoryName,
    List<Map<String, dynamic>> sellers,
  ) {
    final subcategory = vm.subcategories.firstWhere(
      (subcat) => subcat.name == subcategoryName,
      orElse: () => vm.subcategories.first,
    );

    return _SubcategorySectionWidget(
      subcategoryName: subcategoryName,
      sellers: sellers,
      viewModel: vm,
      onViewMore: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => ProductListViewModel(),
              child: ProductListView(
                subcategoryId: subcategory.id,
                categoryName: subcategoryName,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _comingSoon(String title) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Coming Soon!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// SUBCATEGORY SECTION WIDGET
class _SubcategorySectionWidget extends StatefulWidget {
  final String subcategoryName;
  final List<Map<String, dynamic>> sellers;
  final HomeViewModel viewModel;
  final VoidCallback onViewMore;

  const _SubcategorySectionWidget({
    required this.subcategoryName,
    required this.sellers,
    required this.viewModel,
    required this.onViewMore,
  });

  @override
  State<_SubcategorySectionWidget> createState() =>
      _SubcategorySectionWidgetState();
}

class _SubcategorySectionWidgetState extends State<_SubcategorySectionWidget> {
  int _selectedSellerIndex = 0;

  @override
  void didUpdateWidget(covariant _SubcategorySectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sellers.isEmpty) {
      _selectedSellerIndex = 0;
      return;
    }

    if (_selectedSellerIndex >= widget.sellers.length) {
      _selectedSellerIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sellers.isEmpty) return const SizedBox.shrink();

    final selectedSeller = widget.sellers[_selectedSellerIndex];
    final rawProducts = selectedSeller['products'];
    final products = rawProducts is List
        ? rawProducts.whereType<Map<String, dynamic>>().toList(growable: false)
        : <Map<String, dynamic>>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.subcategoryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onViewMore,
                  child: const Text(
                    'View more >',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9B4DFF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              key: PageStorageKey('${widget.subcategoryName}-sellers'),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.sellers.length,
              cacheExtent: 300,
              itemBuilder: (context, index) {
                final seller = widget.sellers[index];
                return _buildSellerTab(
                  seller['name'],
                  index == _selectedSellerIndex,
                  index,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 238,
            child: ListView.builder(
              key: PageStorageKey(
                '${widget.subcategoryName}-${selectedSeller['name']}-products',
              ),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              cacheExtent: 900,
              itemCount: products.length > 30 ? 30 : products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return _buildProductCard(product, selectedSeller['name']);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerTab(String sellerName, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSellerIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF8C42) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF8C42) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            sellerName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, String sellerName) {
    return ProductCardWidget(
      product: product,
      sellerName: sellerName,
      onTap: () {
        // Navigate to ProductDetailView
        final int? shopProductId = product['id'];
        final String? productName = product['name'];

        debugPrint('Product card tapped');
        debugPrint('   Product ID: $shopProductId');
        debugPrint('   Product Name: $productName');

        if (shopProductId != null && shopProductId > 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailView(
                shopProductId: shopProductId,
                productName: productName,
              ),
            ),
          );
        } else {
          debugPrint('Invalid product ID: $shopProductId');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open product details'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      onWishlistToggle: () {
        widget.viewModel.toggleWishlistNew(
          context,
          product['id'],
          widget.subcategoryName,
          sellerName,
        );
      },

      onQuantityChanged: (newQuantity) {
        widget.viewModel.updateProductQuantityNew(
          product['id'],
          widget.subcategoryName,
          sellerName,
          newQuantity,
        );
      },
    );
  }
}

