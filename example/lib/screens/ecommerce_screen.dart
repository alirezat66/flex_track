import 'package:flutter/material.dart';
import 'package:flex_track/flex_track.dart';
import '../events/business_events.dart';
import '../events/app_events.dart';

class ECommerceScreen extends StatefulWidget {
  const ECommerceScreen({super.key});

  @override
  _ECommerceScreenState createState() => _ECommerceScreenState();
}

class _ECommerceScreenState extends State<ECommerceScreen> {
  final List<Product> _cart = [];
  final List<Product> _products = [
    Product(id: 'p1', name: 'Premium Analytics', price: 99.99, currency: 'USD'),
    Product(id: 'p2', name: 'Basic Tracking', price: 49.99, currency: 'USD'),
    Product(id: 'p3', name: 'Enterprise Suite', price: 299.99, currency: 'USD'),
    Product(id: 'p4', name: 'Mobile Analytics', price: 79.99, currency: 'USD'),
  ];

  @override
  void initState() {
    super.initState();
    // Track screen view
    FlexTrack.track(PageViewEvent(
      pageName: 'eCommerce',
      parameters: {'product_count': _products.length.toString()},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Cart Summary
          Container(
            padding: EdgeInsets.all(16),
            // ignore: deprecated_member_use
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.shopping_cart),
                SizedBox(width: 8),
                Text('Cart: ${_cart.length} items'),
                Spacer(),
                Text(
                  'Total: \$${_getCartTotal().toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final isInCart = _cart.any((p) => p.id == product.id);

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
                    trailing: isInCart
                        ? IconButton(
                            icon: Icon(Icons.remove_shopping_cart),
                            onPressed: () => _removeFromCart(product),
                          )
                        : IconButton(
                            icon: Icon(Icons.add_shopping_cart),
                            onPressed: () => _addToCart(product),
                          ),
                  ),
                );
              },
            ),
          ),

          // Action Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cart.isNotEmpty ? _checkout : null,
                    child: Text(
                        'Checkout (\$${_getCartTotal().toStringAsFixed(2)})'),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cart.isNotEmpty ? _abandonCart : null,
                        child: Text('Abandon Cart'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearCart,
                        child: Text('Clear Cart'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    setState(() {
      _cart.add(product);
    });

    // Track add to cart event
    FlexTrack.track(AddToCartEvent(
      productId: product.id,
      productName: product.name,
      price: product.price,
      currency: product.currency,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  void _removeFromCart(Product product) {
    setState(() {
      _cart.removeWhere((p) => p.id == product.id);
    });

    // Track remove from cart (could be a custom event)
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'remove_from_cart',
      buttonText: 'Remove ${product.name}',
      screenName: 'eCommerce',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} removed from cart')),
    );
  }

  void _checkout() {
    if (_cart.isEmpty) return;

    final totalAmount = _getCartTotal();

    // Track purchase for each item
    for (final product in _cart) {
      FlexTrack.track(PurchaseEvent(
        productId: product.id,
        productName: product.name,
        amount: product.price,
        currency: product.currency,
        paymentMethod: 'credit_card',
      ));
    }

    // Track overall checkout completion
    FlexTrack.track(ButtonClickEvent(
      buttonId: 'checkout_complete',
      buttonText: 'Checkout Complete',
      screenName: 'eCommerce',
    ));

    setState(() {
      _cart.clear();
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Purchase Complete!'),
        content: Text(
            'Total: \$${totalAmount.toStringAsFixed(2)}\n\nThank you for your purchase!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _abandonCart() {
    if (_cart.isEmpty) return;

    final totalValue = _getCartTotal();
    final productIds = _cart.map((p) => p.id).toList();

    // Track cart abandonment
    FlexTrack.track(CartAbandonmentEvent(
      productIds: productIds,
      totalValue: totalValue,
      currency: 'USD',
      itemCount: _cart.length,
      abandonmentStage: 'cart',
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cart abandonment tracked')),
    );
  }

  void _clearCart() {
    if (_cart.isNotEmpty) {
      // Track clear cart action
      FlexTrack.track(ButtonClickEvent(
        buttonId: 'clear_cart',
        buttonText: 'Clear Cart',
        screenName: 'eCommerce',
      ));
    }

    setState(() {
      _cart.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Cart cleared')),
    );
  }

  double _getCartTotal() {
    return _cart.fold(0.0, (sum, product) => sum + product.price);
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  final String currency;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
  });
}
