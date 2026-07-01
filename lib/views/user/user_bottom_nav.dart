import 'package:flutter/material.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/persistent_cart_bar.dart';
import 'user_home_view.dart';
import 'categories_view.dart';
import 'wishlist_view.dart';
import 'cart_view.dart';
import 'profile_view.dart';

class UserBottomNav extends StatefulWidget {
  static final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

  const UserBottomNav({super.key});

  @override
  State<UserBottomNav> createState() => _UserBottomNavState();
}

class _UserBottomNavState extends State<UserBottomNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    UserHomeView(),
    CategoriesView(),
    WishlistView(),
    CartView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    UserBottomNav.activeTabNotifier.value = 0;
    UserBottomNav.activeTabNotifier.addListener(_onTabChanged);
    final user = AuthService.currentUser;
    if (user != null) {
      CartService.instance.initCartSync(user.uid);
    }
  }

  @override
  void dispose() {
    UserBottomNav.activeTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) {
      setState(() {
        _selectedIndex = UserBottomNav.activeTabNotifier.value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      body: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: CartService.instance,
              builder: (context, _) {
                final totalItems = CartService.instance.totalItems;
                final hasCartBar = totalItems > 0 && _selectedIndex != 3;
                return Padding(
                  padding: EdgeInsets.only(bottom: hasCartBar ? 76.0 : 0.0),
                  child: _pages[_selectedIndex],
                );
              },
            ),
          ),
          if (_selectedIndex != 3)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PersistentCartBar(),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0D0622),
        indicatorColor: const Color(0xFFFF8A00).withValues(alpha: 0.25),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          UserBottomNav.activeTabNotifier.value = index;
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFFFF8A00)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category, color: Color(0xFFFF8A00)),
            label: 'Categories',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_outline_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: Color(0xFFFF8A00)),
            label: 'Wishlist',
          ),
          NavigationDestination(
            icon: ListenableBuilder(
              listenable: CartService.instance,
              builder: (context, _) {
                final count = CartService.instance.totalItems;
                if (count == 0) return const Icon(Icons.shopping_cart_outlined);
                return Badge(
                  label: Text(count.toString()),
                  backgroundColor: const Color(0xFFDA1B60),
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            selectedIcon: ListenableBuilder(
              listenable: CartService.instance,
              builder: (context, _) {
                final count = CartService.instance.totalItems;
                if (count == 0) return const Icon(Icons.shopping_cart, color: Color(0xFFFF8A00));
                return Badge(
                  label: Text(count.toString()),
                  backgroundColor: const Color(0xFFDA1B60),
                  child: const Icon(Icons.shopping_cart, color: Color(0xFFFF8A00)),
                );
              },
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFFFF8A00)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
