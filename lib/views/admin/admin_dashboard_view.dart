import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/categories_tab.dart';
import 'tabs/subcategories_tab.dart';
import 'tabs/products_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/banners_tab.dart';
import 'tabs/hero_tab.dart';
import 'tabs/store_address_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/payments_tab.dart';
import 'tabs/support_tab.dart';
import 'tabs/notifications_tab.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final int tabIndex;

  const SidebarItem(this.title, this.icon, this.tabIndex);
}

class SidebarGroup {
  final String category;
  final List<SidebarItem> items;

  const SidebarGroup(this.category, this.items);
}

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedTabIndex = 0;

  final List<SidebarGroup> _groups = const [
    SidebarGroup('OVERVIEW', [
      SidebarItem('Dashboard', Icons.dashboard_rounded, 0),
    ]),
    SidebarGroup('USERS & ORDERS', [
      SidebarItem('Users', Icons.people_rounded, 8),
      SidebarItem('Orders', Icons.shopping_cart_rounded, 9),
      SidebarItem('Payments', Icons.payments_rounded, 10),
      SidebarItem('Customer Support', Icons.support_agent_rounded, 11),
    ]),
    SidebarGroup('CATALOG', [
      SidebarItem('Categories', Icons.category_rounded, 1),
      SidebarItem('Sub Categories', Icons.grid_view_rounded, 2),
      SidebarItem('Products', Icons.shopping_basket_rounded, 3),
    ]),
    SidebarGroup('STORE CONFIG', [
      SidebarItem('App Settings', Icons.settings_rounded, 4),
      SidebarItem('Promotional Banners', Icons.ad_units_rounded, 5),
      SidebarItem('Hero Images', Icons.photo_library_rounded, 6),
      SidebarItem('Store Address', Icons.location_on_rounded, 7),
    ]),
    SidebarGroup('MARKETING', [
      SidebarItem('Notifications', Icons.notifications_rounded, 12),
    ]),
  ];

  Widget _buildActiveTab() {
    switch (_selectedTabIndex) {
      case 0:
        return DashboardTab(
          onTabChanged: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        );
      case 1:
        return const CategoriesTab();
      case 2:
        return const SubcategoriesTab();
      case 3:
        return const ProductsTab();
      case 4:
        return const SettingsTab();
      case 5:
        return const BannersTab();
      case 6:
        return const HeroTab();
      case 7:
        return const StoreAddressTab();
      case 8:
        return const UsersTab();
      case 9:
        return const OrdersTab();
      case 10:
        return const PaymentsTab();
      case 11:
        return const SupportTab();
      case 12:
        return const NotificationsTab();
      default:
        return DashboardTab(
          onTabChanged: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        );
    }
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Foodchannel_mnl Admin Panel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
            tooltip: 'LOGOUT',
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: !isDesktop
          ? Drawer(
              backgroundColor: const Color(0xFF0E0724),
              child: Column(
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xFF0D0622)),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu_rounded, color: Color(0xFFFF8A00), size: 48),
                          SizedBox(height: 12),
                          Text('FoodChannel Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: _groups.expand((group) {
                        return [
                          Padding(
                            padding: const EdgeInsets.only(left: 16, top: 18, bottom: 8),
                            child: Text(
                              group.category,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.35),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                          ...group.items.map((item) {
                            final isSelected = _selectedTabIndex == item.tabIndex;
                            return ListTile(
                              leading: Icon(
                                item.icon,
                                color: isSelected ? const Color(0xFFFF8A00) : Colors.white60,
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFFFF8A00) : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: Colors.white.withValues(alpha: 0.05),
                              onTap: () {
                                setState(() {
                                  _selectedTabIndex = item.tabIndex;
                                });
                                Navigator.pop(context);
                              },
                            );
                          }),
                        ];
                      }).toList(),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          // Sidebar for Desktop
          if (isDesktop)
            Container(
              width: 260,
              decoration: BoxDecoration(
                color: const Color(0xFF0E0724),
                border: Border(
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.05),
                    width: 1.2,
                  ),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: _groups.expand((group) {
                  return [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, top: 18, bottom: 8),
                      child: Text(
                        group.category,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    ...group.items.map((item) {
                      final isSelected = _selectedTabIndex == item.tabIndex;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedTabIndex = item.tabIndex;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF8A00).withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(color: const Color(0xFFFF8A00).withValues(alpha: 0.25))
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: isSelected ? const Color(0xFFFF8A00) : Colors.white60,
                                  size: 20,
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFFF8A00) : Colors.white70,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ];
                }).toList(),
              ),
            ),
          
          // Tab Content Area
          Expanded(
            child: SafeArea(
              child: _buildActiveTab(),
            ),
          ),
        ],
      ),
    );
  }
}
