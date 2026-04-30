// lib/presentation/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home/home_view.dart';
import 'home/home_viewmodel.dart';
import 'offers/offers_viewmodel.dart';
import 'category/categories_view.dart';
import 'store/store_view.dart';
import 'search/search_view.dart';
import 'navigationdrawer/navigation_drawer.dart';
import 'widgets/floating_cart_widget.dart';
import 'cart/cart_view.dart';
import '../core/utils/cart_manager.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
      final homeViewModel = context.read<HomeViewModel>();
      homeViewModel.reloadAddress();

      context.read<CartManager>().syncWithServer();
    }
  }

  void _navigateToSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchView()),
    ).then((_) {
      setState(() {
        _currentIndex = 0;
      });
    });
  }

  void _navigateToCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartView()),
    );
  }

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => OffersViewModel()),
      ],
      child: Scaffold(
        drawer: const NavigationDrawerView(),
        body: Stack(
          children: [
            // Main Content
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeView(onSwitchTab: _switchToTab),
                const CategoriesView(),
                const StoreView(),
              ],
            ),
            
            if (_currentIndex == 0 || _currentIndex == 1)
              FloatingCartWidget(onTap: _navigateToCart),
          ],
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 66,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFFFF1E8),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFFFF8C42)
                  : Colors.grey.shade600,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 22,
              color: isSelected
                  ? const Color(0xFFFF8C42)
                  : Colors.grey.shade500,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            if (index == 3) {
              _navigateToSearch();
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Categories',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'Store',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.travel_explore_rounded),
              label: 'Search',
            ),
          ],
        ),
      ),
    );
  }
}
