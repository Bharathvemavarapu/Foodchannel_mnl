import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/banner_hero.dart';
import '../models/app_settings.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/payment.dart';
import '../models/support_ticket.dart';
import '../models/notification.dart';
import '../models/address.dart';
import '../models/review.dart';
import '../models/promo_code.dart';

class DatabaseService {
  static const String dbUrl = "https://foodchannelmnl-default-rtdb.firebaseio.com";

  static Future<String?> _getToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  }

  // --- CATEGORIES ---
  static Future<List<CategoryModel>> getCategories() async {
    final response = await http.get(Uri.parse('$dbUrl/store/categories.json'));
    if (response.statusCode != 200) throw Exception('Failed to load categories');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<CategoryModel> list = [];
    data.forEach((key, value) {
      list.add(CategoryModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addCategory(String name, String imageUrl) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/categories.json?auth=$token');
    final response = await http.post(url, body: jsonEncode({
      'name': name,
      'imageUrl': imageUrl,
      'createdDate': DateTime.now().toIso8601String(),
    }));
    if (response.statusCode != 200) throw Exception('Failed to add category');
  }

  static Future<void> updateCategory(String id, String name, String imageUrl) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/categories/$id.json?auth=$token');
    final response = await http.patch(url, body: jsonEncode({
      'name': name,
      'imageUrl': imageUrl,
    }));
    if (response.statusCode != 200) throw Exception('Failed to update category');
  }

  static Future<void> deleteCategory(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/categories/$id.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Failed to delete category');
  }

  // --- SUBCATEGORIES ---
  static Future<List<SubCategoryModel>> getSubCategories() async {
    final response = await http.get(Uri.parse('$dbUrl/store/subcategories.json'));
    if (response.statusCode != 200) throw Exception('Failed to load subcategories');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<SubCategoryModel> list = [];
    data.forEach((key, value) {
      list.add(SubCategoryModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addSubCategory(String categoryId, String name, String imageUrl) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/subcategories.json?auth=$token');
    final response = await http.post(url, body: jsonEncode({
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'createdDate': DateTime.now().toIso8601String(),
    }));
    if (response.statusCode != 200) throw Exception('Failed to add subcategory');
  }

  static Future<void> updateSubCategory(String id, String categoryId, String name, String imageUrl) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/subcategories/$id.json?auth=$token');
    final response = await http.patch(url, body: jsonEncode({
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
    }));
    if (response.statusCode != 200) throw Exception('Failed to update subcategory');
  }

  static Future<void> deleteSubCategory(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/subcategories/$id.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Failed to delete subcategory');
  }

  // --- PRODUCTS ---
  static Future<List<ProductModel>> getProducts() async {
    final response = await http.get(Uri.parse('$dbUrl/store/products.json'));
    if (response.statusCode != 200) throw Exception('Failed to load products');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<ProductModel> list = [];
    data.forEach((key, value) {
      list.add(ProductModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addProduct(ProductModel product) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/products.json?auth=$token');
    final response = await http.post(url, body: jsonEncode(product.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to add product');
  }

  static Future<void> updateProduct(String id, ProductModel product) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/products/$id.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(product.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to update product');
  }

  static Future<void> deleteProduct(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/products/$id.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Failed to delete product');
  }

  // --- APP SETTINGS ---
  static Future<AppSettingsModel> getAppSettings() async {
    final response = await http.get(Uri.parse('$dbUrl/store/settings.json'));
    if (response.statusCode != 200) throw Exception('Failed to load app settings');
    if (response.body == 'null' || response.body.isEmpty) return AppSettingsModel.empty();

    return AppSettingsModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> saveAppSettings(AppSettingsModel settings) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/settings.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(settings.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to save settings');
  }

  // --- PROMOTIONAL BANNERS ---
  static Future<List<BannerModel>> getBanners() async {
    final response = await http.get(Uri.parse('$dbUrl/store/banners.json'));
    if (response.statusCode != 200) throw Exception('Failed to load banners');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<BannerModel> list = [];
    data.forEach((key, value) {
      list.add(BannerModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addBanner(String imageUrl, bool isEnabled) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/banners.json?auth=$token');
    final response = await http.post(url, body: jsonEncode({
      'imageUrl': imageUrl,
      'isEnabled': isEnabled,
      'createdDate': DateTime.now().toIso8601String(),
    }));
    if (response.statusCode != 200) throw Exception('Failed to add banner');
  }

  static Future<void> updateBanner(String id, String imageUrl, bool isEnabled) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/banners/$id.json?auth=$token');
    final response = await http.patch(url, body: jsonEncode({
      'imageUrl': imageUrl,
      'isEnabled': isEnabled,
    }));
    if (response.statusCode != 200) throw Exception('Failed to update banner');
  }

  static Future<void> deleteBanner(String id) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/banners/$id.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Failed to delete banner');
  }

  // --- HERO IMAGES ---
  static Future<List<HeroImageModel>> getHeroImages() async {
    final response = await http.get(Uri.parse('$dbUrl/store/heroImages.json'));
    if (response.statusCode != 200) throw Exception('Failed to load hero images');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<HeroImageModel> list = [];
    data.forEach((key, value) {
      list.add(HeroImageModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  static Future<void> saveHeroImages(List<HeroImageModel> images) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/heroImages.json?auth=$token');
    
    // Clear and overwrite with new sorted list
    final Map<String, dynamic> payload = {};
    for (int i = 0; i < images.length; i++) {
      final img = images[i];
      final key = img.id.isEmpty || img.id.startsWith('new_') ? 'hero_${DateTime.now().microsecondsSinceEpoch}_$i' : img.id;
      payload[key] = {
        'imageUrl': img.imageUrl,
        'sortOrder': i,
      };
    }
    
    final response = await http.put(url, body: jsonEncode(payload));
    if (response.statusCode != 200) throw Exception('Failed to save hero images');
  }

  // --- STORE ADDRESS ---
  static Future<StoreAddressModel> getStoreAddress() async {
    final response = await http.get(Uri.parse('$dbUrl/store/address.json'));
    if (response.statusCode != 200) throw Exception('Failed to load store address');
    if (response.body == 'null' || response.body.isEmpty) return StoreAddressModel.empty();

    return StoreAddressModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> saveStoreAddress(StoreAddressModel address) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/address.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(address.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to save store address');
  }

  // --- USERS MANAGEMENT ---
  static Future<List<UserModel>> getUsers() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load users');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<UserModel> list = [];
    data.forEach((key, value) {
      list.add(UserModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> updateUserProfile(UserModel user) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/${user.uid}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(user.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to update user profile');
  }

  static Future<void> deleteUser(String uid) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) throw Exception('Failed to delete user');
  }

  // --- ORDERS ---
  static Future<List<OrderModel>> getOrders() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/orders.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load orders');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<OrderModel> list = [];
    data.forEach((key, value) {
      list.add(OrderModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addOrder(OrderModel order) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/orders/${order.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(order.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add order: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus, String notes) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/orders/$orderId.json?auth=$token');
    
    final getResponse = await http.get(Uri.parse('$dbUrl/orders/$orderId.json?auth=$token'));
    if (getResponse.statusCode != 200) {
      throw Exception('Failed to fetch order details (Status: ${getResponse.statusCode}): ${getResponse.body}');
    }
    if (getResponse.body == 'null') {
      throw Exception('Order $orderId does not exist in the database');
    }
    
    final order = OrderModel.fromJson(orderId, jsonDecode(getResponse.body));
    final updatedTimeline = List<OrderTimelineEvent>.from(order.timeline)
      ..add(OrderTimelineEvent(
        status: newStatus,
        timestamp: DateTime.now(),
        notes: notes,
      ));
    
    final response = await http.patch(url, body: jsonEncode({
      'status': newStatus,
      'paymentStatus': newStatus == 'Delivered' ? 'Paid' : order.paymentStatus,
      'timeline': updatedTimeline.map((t) => t.toJson()).toList(),
    }));
    if (response.statusCode != 200) {
      throw Exception('Failed to update order status (Status: ${response.statusCode}): ${response.body}');
    }
  }

  static Future<void> cancelOrder(String orderId) async {
    await updateOrderStatus(orderId, 'Cancelled', 'Order was cancelled by administrator.');
  }

  static Future<void> approveRefund(String orderId) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/orders/$orderId.json?auth=$token');
    
    final getResponse = await http.get(Uri.parse('$dbUrl/orders/$orderId.json?auth=$token'));
    if (getResponse.statusCode != 200) {
      throw Exception('Failed to fetch order details (Status: ${getResponse.statusCode}): ${getResponse.body}');
    }
    if (getResponse.body == 'null') {
      throw Exception('Order $orderId does not exist in the database');
    }
    
    final order = OrderModel.fromJson(orderId, jsonDecode(getResponse.body));
    final updatedTimeline = List<OrderTimelineEvent>.from(order.timeline)
      ..add(OrderTimelineEvent(
        status: 'Refunded',
        timestamp: DateTime.now(),
        notes: 'Refund approved by administrator.',
      ));

    final response = await http.patch(url, body: jsonEncode({
      'status': 'Refunded',
      'paymentStatus': 'Refunded',
      'timeline': updatedTimeline.map((t) => t.toJson()).toList(),
    }));
    if (response.statusCode != 200) {
      throw Exception('Failed to approve refund (Status: ${response.statusCode}): ${response.body}');
    }
  }

  // --- PAYMENTS ---
  static Future<PaymentSettingsModel> getPaymentSettings() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/store/paymentsSettings.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load payment settings');
    if (response.body == 'null' || response.body.isEmpty) return PaymentSettingsModel.empty();

    return PaymentSettingsModel.fromJson(jsonDecode(response.body));
  }

  static Future<void> savePaymentSettings(PaymentSettingsModel settings) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/store/paymentsSettings.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(settings.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to save settings: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<PaymentTransactionModel>> getTransactions() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/payments.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load transactions');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<PaymentTransactionModel> list = [];
    data.forEach((key, value) {
      list.add(PaymentTransactionModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addTransaction(PaymentTransactionModel tx) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/payments/${tx.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(tx.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to add transaction');
  }

  // --- SUPPORT ---
  static Future<List<SupportTicketModel>> getSupportTickets() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/supportTickets.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load support tickets');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<SupportTicketModel> list = [];
    data.forEach((key, value) {
      list.add(SupportTicketModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> createSupportTicket(SupportTicketModel ticket) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/supportTickets/${ticket.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(ticket.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to create ticket');
  }

  static Future<void> addReplyToTicket(String ticketId, SupportReplyModel reply, String newStatus) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/supportTickets/$ticketId.json?auth=$token');
    
    final getResponse = await http.get(Uri.parse('$dbUrl/supportTickets/$ticketId.json?auth=$token'));
    if (getResponse.statusCode != 200 || getResponse.body == 'null') return;
    
    final ticket = SupportTicketModel.fromJson(ticketId, jsonDecode(getResponse.body));
    final updatedReplies = List<SupportReplyModel>.from(ticket.replies)..add(reply);

    final response = await http.patch(url, body: jsonEncode({
      'status': newStatus,
      'replies': updatedReplies.map((r) => r.toJson()).toList(),
      'updatedDate': DateTime.now().toIso8601String(),
    }));
    if (response.statusCode != 200) throw Exception('Failed to reply to ticket');
  }

  static Future<void> updateTicketStatus(String ticketId, String status) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/supportTickets/$ticketId.json?auth=$token');
    final response = await http.patch(url, body: jsonEncode({
      'status': status,
      'updatedDate': DateTime.now().toIso8601String(),
    }));
    if (response.statusCode != 200) throw Exception('Failed to update ticket status');
  }

  // --- NOTIFICATIONS ---
  static Future<List<NotificationModel>> getNotifications() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/notifications.json?auth=$token'));
    if (response.statusCode != 200) throw Exception('Failed to load notifications');
    if (response.body == 'null' || response.body.isEmpty) return [];

    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<NotificationModel> list = [];
    data.forEach((key, value) {
      list.add(NotificationModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Future<void> addNotification(NotificationModel notif) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/notifications/${notif.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(notif.toJson()));
    if (response.statusCode != 200) throw Exception('Failed to add notification');
  }

  static Future<void> checkAndPrepopulateDatabase() async {
    try {
      final categories = await getCategories();
      final banners = await getBanners();
      final hasCookware = categories.any((c) => c.name == 'Cookware');
      final hasCookwareBanner = banners.any((b) => b.imageUrl.contains("photo-1506368249639-73a05d6f6488") || b.imageUrl.contains("photo-1547592180-85f173990554"));
      
      if (categories.isNotEmpty && !hasCookware && !hasCookwareBanner) return;

      final token = await _getToken();

      // Clear existing database store data if Cookware or Cookware banners are present
      if (hasCookware || hasCookwareBanner || categories.isNotEmpty) {
        await http.delete(Uri.parse('$dbUrl/store.json?auth=$token'));
        await http.delete(Uri.parse('$dbUrl/banners.json?auth=$token'));
        await http.delete(Uri.parse('$dbUrl/hero_images.json?auth=$token'));
      }

      // 1. Save App Settings
      final settings = AppSettingsModel(
        name: "FoodChannel MNL",
        logoUrl: "https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=200",
        description: "Craving something delicious? Order from Visakhapatnam's premium culinary kitchen hub.",
        contactNumber: "+91 98765 43210",
        email: "support@foodchannelmnl.com",
        whatsapp: "919876543210",
      );
      await saveAppSettings(settings);

      // 2. Save Store Address
      final address = StoreAddressModel(
        fullAddress: "Flat 402, Signature Towers, MVP Colony, Visakhapatnam, Andhra Pradesh, 530017",
        latitude: 17.7447,
        longitude: 83.3318,
      );
      await saveStoreAddress(address);

      // 3. Add Banners
      await addBanner("https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800", true);
      await addBanner("https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800", true);

      // 4. Add Hero Slider Images
      final heroes = [
        HeroImageModel(id: 'hero_1', imageUrl: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200", sortOrder: 0),
        HeroImageModel(id: 'hero_2', imageUrl: "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=1200", sortOrder: 1),
      ];
      await saveHeroImages(heroes);

      // 5. Add Categories & Subcategories
      final catUrl = Uri.parse('$dbUrl/store/categories.json?auth=$token');
      final subUrl = Uri.parse('$dbUrl/store/subcategories.json?auth=$token');

      // Fast Food Category
      final cat1Response = await http.post(catUrl, body: jsonEncode({
        'name': 'Fast Food',
        'imageUrl': 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final cat1Id = jsonDecode(cat1Response.body)['name'] as String;

      final sub1Response = await http.post(subUrl, body: jsonEncode({
        'categoryId': cat1Id,
        'name': 'Pizzas & Burgers',
        'imageUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final sub1Id = jsonDecode(sub1Response.body)['name'] as String;

      // Indian Food Category
      final cat2Response = await http.post(catUrl, body: jsonEncode({
        'name': 'Indian Food',
        'imageUrl': 'https://images.unsplash.com/photo-1585938338392-50a59970d8ee?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final cat2Id = jsonDecode(cat2Response.body)['name'] as String;

      final sub2Response = await http.post(subUrl, body: jsonEncode({
        'categoryId': cat2Id,
        'name': 'Biryani & Main Course',
        'imageUrl': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final sub2Id = jsonDecode(sub2Response.body)['name'] as String;

      // Street Food Category
      final cat3Response = await http.post(catUrl, body: jsonEncode({
        'name': 'Street Food',
        'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final cat3Id = jsonDecode(cat3Response.body)['name'] as String;

      final sub3Response = await http.post(subUrl, body: jsonEncode({
        'categoryId': cat3Id,
        'name': 'Rolls & Chaat',
        'imageUrl': 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final sub3Id = jsonDecode(sub3Response.body)['name'] as String;

      // Desserts Category
      final cat4Response = await http.post(catUrl, body: jsonEncode({
        'name': 'Desserts',
        'imageUrl': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final cat4Id = jsonDecode(cat4Response.body)['name'] as String;

      final sub4Response = await http.post(subUrl, body: jsonEncode({
        'categoryId': cat4Id,
        'name': 'Cakes & Brownies',
        'imageUrl': 'https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final sub4Id = jsonDecode(sub4Response.body)['name'] as String;

      // Drinks Category
      final cat5Response = await http.post(catUrl, body: jsonEncode({
        'name': 'Drinks',
        'imageUrl': 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final cat5Id = jsonDecode(cat5Response.body)['name'] as String;

      final sub5Response = await http.post(subUrl, body: jsonEncode({
        'categoryId': cat5Id,
        'name': 'Shakes & Mojitos',
        'imageUrl': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500',
        'createdDate': DateTime.now().toIso8601String(),
      }));
      final sub5Id = jsonDecode(sub5Response.body)['name'] as String;

      // 6. Add Products (8 Hero Best Combinations)
      final productsList = [
        ProductModel(
          id: '',
          categoryId: cat1Id,
          subCategoryId: sub1Id,
          name: 'Cheese Burst Pizza',
          description: 'Loaded with extra mozzarella cheese, fresh basil leaves, and tomato sauce.',
          price: 399.0,
          discountPrice: 299.0,
          stock: 25,
          brand: 'Pizza Hut',
          sku: 'FF-PZ-CB',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat1Id,
          subCategoryId: sub1Id,
          name: 'Gourmet Burger',
          description: 'Premium flame-grilled beef/veg burger with lettuce, tomatoes, cheddar cheese, and signature sauce.',
          price: 249.0,
          discountPrice: 199.0,
          stock: 30,
          brand: 'Burger King',
          sku: 'FF-BG-GM',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat1Id,
          subCategoryId: sub1Id,
          name: 'Crispy Fried Chicken',
          description: 'Golden, crispy, and crunchy fried chicken, seasoned with hot and spicy herbs.',
          price: 499.0,
          discountPrice: 449.0,
          stock: 15,
          brand: 'KFC',
          sku: 'FF-CH-CR',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1626082927389-6cd097cdc6ec?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat2Id,
          subCategoryId: sub2Id,
          name: 'Chicken Dum Biryani',
          description: 'Rich and aromatic Hyderabadi basmati rice biryani cooked with marinated chicken pieces.',
          price: 349.0,
          discountPrice: 299.0,
          stock: 40,
          brand: 'Behrouz',
          sku: 'IN-BY-CK',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat3Id,
          subCategoryId: sub3Id,
          name: 'Shawarma Roll',
          description: 'Tender garlic grilled chicken wrapped in soft flatbread with house sauce and pickles.',
          price: 179.0,
          discountPrice: 149.0,
          stock: 50,
          brand: 'Al Taza',
          sku: 'SF-SH-RL',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1662116765994-4e4473e440b8?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat1Id,
          subCategoryId: sub1Id,
          name: 'French Fries',
          description: 'Crispy salted classic french fries served with spicy tomato dip.',
          price: 129.0,
          discountPrice: 99.0,
          stock: 100,
          brand: 'McDonalds',
          sku: 'FF-FR-CL',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500'],
          isFeatured: true,
          isTrending: false,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat5Id,
          subCategoryId: sub5Id,
          name: 'Cold Coffee Mojito',
          description: 'Refreshing chilled cold drink soft blend beverage.',
          price: 49.0,
          discountPrice: 39.0,
          stock: 150,
          brand: 'Coca Cola',
          sku: 'DK-SD-CC',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500'],
          isFeatured: true,
          isTrending: false,
          createdDate: DateTime.now(),
        ),
        ProductModel(
          id: '',
          categoryId: cat4Id,
          subCategoryId: sub4Id,
          name: 'Fudgy Brownie Dessert',
          description: 'Warm, gooey chocolate brownie cake piece topped with chocolate syrup.',
          price: 149.0,
          discountPrice: 119.0,
          stock: 45,
          brand: 'Warm Oven',
          sku: 'DS-BW-CH',
          isAvailable: true,
          imageUrls: ['https://images.unsplash.com/photo-1564355808539-22fda35bed7e?w=500'],
          isFeatured: true,
          isTrending: true,
          createdDate: DateTime.now(),
        ),
      ];

      for (var prod in productsList) {
        await addProduct(prod);
      }

      // 7. Prepopulate Active Promo Codes
      await http.put(Uri.parse('$dbUrl/store/promoCodes/FIRST50.json?auth=$token'), body: jsonEncode({
        'discountPercentage': 50.0,
        'minOrderAmount': 199.0,
        'isActive': true,
      }));
      await http.put(Uri.parse('$dbUrl/store/promoCodes/BINGE.json?auth=$token'), body: jsonEncode({
        'discountPercentage': 20.0,
        'minOrderAmount': 299.0,
        'isActive': true,
      }));
      await http.put(Uri.parse('$dbUrl/store/promoCodes/FREEDEL.json?auth=$token'), body: jsonEncode({
        'discountPercentage': 10.0,
        'minOrderAmount': 99.0,
        'isActive': true,
      }));

    } catch (e) {
      print("Pre-population error: $e");
    }
  }

  // --- STREAM METHODS FOR USER HOME PAGE & BROWSING ---
  static Stream<List<HeroImageModel>> getHeroImagesStream() async* {
    try {
      yield await getHeroImages();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        return await getHeroImages();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<BannerModel>> getBannersStream() async* {
    try {
      yield await getBanners();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        return await getBanners();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<CategoryModel>> getCategoriesStream() async* {
    try {
      yield await getCategories();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        return await getCategories();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<SubCategoryModel>> getSubCategoriesStream(String categoryId) async* {
    try {
      final list = await getSubCategories();
      yield list.where((sub) => sub.categoryId == categoryId).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final subcats = await getSubCategories();
        return subcats.where((sub) => sub.categoryId == categoryId).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<ProductModel>> getFeaturedProductsStream() async* {
    try {
      final list = await getProducts();
      yield list.where((p) => p.isFeatured && p.isAvailable).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final prods = await getProducts();
        return prods.where((p) => p.isFeatured && p.isAvailable).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<ProductModel>> getTrendingProductsStream() async* {
    try {
      final list = await getProducts();
      yield list.where((p) => p.isTrending && p.isAvailable).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final prods = await getProducts();
        return prods.where((p) => p.isTrending && p.isAvailable).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<ProductModel>> getProductsByCategoryStream(String categoryId) async* {
    try {
      final list = await getProducts();
      yield list.where((p) => p.categoryId == categoryId && p.isAvailable).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final prods = await getProducts();
        return prods.where((p) => p.categoryId == categoryId && p.isAvailable).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<ProductModel>> getProductsBySubCategoryStream(String subCategoryId) async* {
    try {
      final list = await getProducts();
      yield list.where((p) => p.subCategoryId == subCategoryId && p.isAvailable).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final prods = await getProducts();
        return prods.where((p) => p.subCategoryId == subCategoryId && p.isAvailable).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<ProductModel>> searchProductsStream(String query) async* {
    try {
      final list = await getProducts();
      final q = query.toLowerCase().trim();
      if (q.isEmpty) {
        yield list;
      } else {
        yield list.where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)).toList();
      }
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final prods = await getProducts();
        final q = query.toLowerCase().trim();
        if (q.isEmpty) return prods;
        return prods.where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)).toList();
      } catch (_) {
        return [];
      }
    });
  }

  // --- USER PROFILE, CART, WISHLIST, AND ORDER ENDPOINTS ---
  static Future<Map<String, int>> getUserCart(String uid) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users/$uid/cart.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return {};
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    return data.map((key, value) => MapEntry(key, value as int));
  }

  static Future<void> saveCartItem(String uid, String productId, int quantity) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/cart/$productId.json?auth=$token');
    await http.put(url, body: jsonEncode(quantity));
  }

  static Future<void> removeCartItem(String uid, String productId) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/cart/$productId.json?auth=$token');
    await http.delete(url);
  }

  static Future<void> clearCart(String uid) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/cart.json?auth=$token');
    await http.delete(url);
  }

  static Stream<Map<String, int>> getUserCartStream(String uid) async* {
    try {
      yield await getUserCart(uid);
    } catch (_) {
      yield {};
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getUserCart(uid);
      } catch (_) {
        return {};
      }
    });
  }

  static Future<List<String>> getUserWishlist(String uid) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users/$uid/wishlist.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return [];
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<String> list = [];
    data.forEach((key, value) {
      if (value == true) list.add(key);
    });
    return list;
  }

  static Future<void> toggleWishlist(String uid, String productId) async {
    final token = await _getToken();
    final current = await getUserWishlist(uid);
    final url = Uri.parse('$dbUrl/users/$uid/wishlist/$productId.json?auth=$token');
    if (current.contains(productId)) {
      await http.delete(url);
    } else {
      await http.put(url, body: jsonEncode(true));
    }
  }

  static Stream<List<String>> getUserWishlistStream(String uid) async* {
    try {
      yield await getUserWishlist(uid);
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getUserWishlist(uid);
      } catch (_) {
        return [];
      }
    });
  }

  static Stream<List<OrderModel>> getUserOrdersStream(String uid) async* {
    try {
      final orders = await getOrders();
      yield orders.where((o) => o.customerId == uid).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 20)).asyncMap((_) async {
      try {
        final orders = await getOrders();
        return orders.where((o) => o.customerId == uid).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Future<void> updateUserProfileFields(String uid, Map<String, dynamic> data) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid.json?auth=$token');
    final response = await http.patch(url, body: jsonEncode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile fields: ${response.body}');
    }
  }

  static Future<UserModel?> getUserProfile(String uid) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users/$uid.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return null;
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    return UserModel.fromJson(uid, data);
  }

  static Stream<UserModel?> getUserProfileStream(String uid) async* {
    try {
      yield await getUserProfile(uid);
    } catch (_) {
      yield null;
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getUserProfile(uid);
      } catch (_) {
        return null;
      }
    });
  }

  // --- USER ADDRESSES ENDPOINTS ---
  static Future<List<UserAddressModel>> getUserAddresses(String uid) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users/$uid/addresses.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return [];
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<UserAddressModel> list = [];
    data.forEach((key, value) {
      list.add(UserAddressModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Stream<List<UserAddressModel>> getUserAddressesStream(String uid) async* {
    try {
      yield await getUserAddresses(uid);
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getUserAddresses(uid);
      } catch (_) {
        return [];
      }
    });
  }

  static Future<void> addUserAddress(String uid, UserAddressModel address) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/addresses/${address.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(address.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to add address');
    }
  }

  static Future<void> deleteUserAddress(String uid, String addressId) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/addresses/$addressId.json?auth=$token');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete address');
    }
  }

  // --- USER NOTIFICATIONS ENDPOINTS ---
  static Stream<List<NotificationModel>> getUserNotificationsStream(String uid) async* {
    try {
      final notifs = await getNotifications();
      yield notifs.where((n) => n.type == 'All Users' || n.targetUserIds.contains(uid)).toList();
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        final notifs = await getNotifications();
        return notifs.where((n) => n.type == 'All Users' || n.targetUserIds.contains(uid)).toList();
      } catch (_) {
        return [];
      }
    });
  }

  static Future<List<String>> getUserReadNotifications(String uid) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/users/$uid/readNotifications.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return [];
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<String> list = [];
    data.forEach((key, value) {
      if (value == true) {
        list.add(key);
      }
    });
    return list;
  }

  static Stream<List<String>> getUserReadNotificationsStream(String uid) async* {
    try {
      yield await getUserReadNotifications(uid);
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getUserReadNotifications(uid);
      } catch (_) {
        return [];
      }
    });
  }

  static Future<void> markNotificationAsRead(String uid, String notifId) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/users/$uid/readNotifications/$notifId.json?auth=$token');
    await http.put(url, body: jsonEncode(true));
  }

  // --- PRODUCT REVIEWS ENDPOINTS ---
  static Future<List<ProductReviewModel>> getProductReviews(String productId) async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/reviews/$productId.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return [];
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<ProductReviewModel> list = [];
    data.forEach((key, value) {
      list.add(ProductReviewModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }

  static Stream<List<ProductReviewModel>> getProductReviewsStream(String productId) async* {
    try {
      yield await getProductReviews(productId);
    } catch (_) {
      yield [];
    }
    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        return await getProductReviews(productId);
      } catch (_) {
        return [];
      }
    });
  }

  static Future<void> submitProductReview(String productId, ProductReviewModel review) async {
    final token = await _getToken();
    final url = Uri.parse('$dbUrl/reviews/$productId/${review.id}.json?auth=$token');
    final response = await http.put(url, body: jsonEncode(review.toJson()));
    if (response.statusCode != 200) {
      throw Exception('Failed to submit review');
    }
  }

  // --- PROMO CODES ENDPOINTS ---
  static Future<List<PromoCodeModel>> getPromoCodes() async {
    final token = await _getToken();
    final response = await http.get(Uri.parse('$dbUrl/store/promoCodes.json?auth=$token'));
    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return [];
    }
    final Map<String, dynamic> data = jsonDecode(response.body);
    final List<PromoCodeModel> list = [];
    data.forEach((key, value) {
      list.add(PromoCodeModel.fromJson(key, Map<String, dynamic>.from(value)));
    });
    return list;
  }
}
