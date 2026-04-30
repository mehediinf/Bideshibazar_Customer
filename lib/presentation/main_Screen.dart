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
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      elevation: 12,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      onTap: (index) {
        if (index == 3) {
          // Search tab
          _navigateToSearch();
        } else {
          setState(() {
            _currentIndex = index;
          });
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(
          icon: Icon(Icons.widgets_outlined),
          label: "Categories",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.store), label: "Store"),
        BottomNavigationBarItem(
          icon: Icon(Icons.search_rounded),
          label: "Search",
        ),
      ],
    );
  }
}
