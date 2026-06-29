import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import 'database_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });
}

class CartService extends ChangeNotifier {
  // Singleton pattern
  static final CartService instance = CartService._internal();
  CartService._internal();

  final List<CartItem> _items = [];
  StreamSubscription? _dbSyncSubscription;
  String? _currentUid;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount {
    return _items.fold(0.0, (sum, item) {
      final price = item.product.discountPrice > 0 && item.product.discountPrice < item.product.price
          ? item.product.discountPrice
          : item.product.price;
      return sum + (price * item.quantity);
    });
  }

  /// Start listening to Firebase cart for the user and keep local cart synced
  Future<void> initCartSync(String uid) async {
    if (_currentUid == uid) return;
    _currentUid = uid;
    _dbSyncSubscription?.cancel();

    // Fetch product catalog once to resolve product IDs to models
    List<ProductModel> allProds = [];
    try {
      allProds = await DatabaseService.getProducts();
    } catch (_) {}

    _dbSyncSubscription = DatabaseService.getUserCartStream(uid).listen((dbCart) {
      _items.clear();
      dbCart.forEach((productId, qty) {
        final prod = allProds.firstWhere(
          (p) => p.id == productId,
          orElse: () => ProductModel(
            id: productId,
            name: 'Resolving product...',
            description: '',
            imageUrls: [],
            price: 0.0,
            discountPrice: 0.0,
            stock: 99,
            brand: '',
            sku: '',
            categoryId: '',
            subCategoryId: '',
            isAvailable: true,
            isFeatured: false,
            isTrending: false,
            createdDate: DateTime.now(),
          ),
        );
        _items.add(CartItem(product: prod, quantity: qty));
      });
      notifyListeners();
    });
  }

  /// Cancels Firebase database sync and clears local items
  void cancelCartSync() {
    _dbSyncSubscription?.cancel();
    _dbSyncSubscription = null;
    _currentUid = null;
    _items.clear();
    notifyListeners();
  }

  void addToCart(ProductModel product, {int quantity = 1}) {
    if (!product.isAvailable) return;

    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    int finalQty = quantity;
    if (existingIndex >= 0) {
      finalQty = _items[existingIndex].quantity + quantity;
      finalQty = finalQty.clamp(1, product.stock);
      _items[existingIndex].quantity = finalQty;
    } else {
      finalQty = quantity.clamp(1, product.stock);
      _items.add(CartItem(
        product: product,
        quantity: finalQty,
      ));
    }
    notifyListeners();

    // Push to Firebase (Optimistic async update)
    if (_currentUid != null) {
      DatabaseService.saveCartItem(_currentUid!, product.id, finalQty);
    }
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
        notifyListeners();
        if (_currentUid != null) {
          DatabaseService.removeCartItem(_currentUid!, productId);
        }
      } else {
        final maxStock = _items[index].product.stock;
        final finalQty = quantity.clamp(1, maxStock);
        _items[index].quantity = finalQty;
        notifyListeners();
        if (_currentUid != null) {
          DatabaseService.saveCartItem(_currentUid!, productId, finalQty);
        }
      }
    }
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    if (_currentUid != null) {
      DatabaseService.removeCartItem(_currentUid!, productId);
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
    if (_currentUid != null) {
      DatabaseService.clearCart(_currentUid!);
    }
  }
}
