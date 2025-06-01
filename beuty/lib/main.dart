// ملف main.dart لتطبيق مستحضرات التجميل

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';

// Cart item model
class CartItem {
  final String id;
  final String name;
  final String image;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.quantity = 1,
  });
}

// Cart state
class CartState extends ChangeNotifier {
  final List<CartItem> _items = [];
  
  List<CartItem> get items => List.unmodifiable(_items);
  
  double get total => _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  
  void updateQuantity(String id, int quantity) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity = quantity;
      notifyListeners();
    }
  }
  
  void clear() {
    _items.clear();
    notifyListeners();
  }
}

// Error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;

  const ErrorBoundary({Key? key, required this.child}) : super(key: key);

  @override
  _ErrorBoundaryState createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text('حدث خطأ غير متوقع'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  hasError = false;
                });
              },
              child: Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}

// Global key for showing snackbars from anywhere
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Show error dialog
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('فشل في تهيئة Firebase'),
                Text(e.toString()),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  
  runApp(
    ChangeNotifierProvider(
      create: (_) => CartState(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'متجر التجميل',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.pink,
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  int _currentCarouselIndex = 0;
  final CartState cartState = CartState();

  void _showError(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _addToCart(String id, String name, String image, double price) {
    cartState.addItem(
      CartItem(
        id: id,
        name: name,
        image: image,
        price: price,
      ),
    );
    
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('تمت الإضافة إلى السلة'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            cartState.removeItem(id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مستحضرات التجميل'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.shopping_cart),
                if (cartState.items.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cartState.items.length}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartPage(cartState: cartState),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // سلايدر الإعلانات
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('ads').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    _showError('حدث خطأ في تحميل الإعلانات');
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red),
                          SizedBox(height: 16),
                          Text('حدث خطأ في تحميل الإعلانات'),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_not_supported, size: 48),
                          SizedBox(height: 16),
                          Text('لا توجد إعلانات متوفرة'),
                        ],
                      ),
                    );
                  }

                  final ads = snapshot.data!.docs;
                  return Column(
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 180.0,
                          autoPlay: true,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                        ),
                        items: ads.map((doc) {
                          final image = doc['image']?.toString() ?? '';
                          final desc = doc['description']?.toString() ?? '';
                          return Builder(
                            builder: (context) => Stack(
                              alignment: Alignment.bottomCenter,
                              children: [
                                Image.network(
                                  image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(Icons.error),
                                    );
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  color: Colors.black54,
                                  padding: EdgeInsets.all(8),
                                  width: double.infinity,
                                  child: Text(
                                    desc,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ads.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(
                                    _currentCarouselIndex == entry.key ? 0.9 : 0.4,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 16),

              // الأقسام
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('الأقسام',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: firestore.collection('category').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدث خطأ في تحميل الأقسام'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('لا توجد أقسام متوفرة'),
                    );
                  }

                  final categories = snapshot.data!.docs;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final iconUrl = cat['icon']?.toString() ?? '';
                      final name = cat['name']?.toString() ?? '';
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductsPage(categoryName: name),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                iconUrl,
                                height: 60,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.error, size: 60);
                                },
                              ),
                              SizedBox(height: 12),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),

              SizedBox(height: 16),

              // المنتجات الحديثة
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('منتجات جديدة',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection('products')
                    .where('isNew', isEqualTo: true)
                    .limit(10) // Limit for better performance
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('حدث خطأ في تحميل المنتجات'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text('لا توجد منتجات جديدة'),
                    );
                  }

                  final products = snapshot.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final doc = products[index];
                      final productName = doc['name']?.toString() ?? 'Unnamed Product';
                      final productImage = doc['image']?.toString() ?? '';
                      final productPrice = doc['price']?.toString() ?? '0';
                      final productDesc = doc['description']?.toString();
                      
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(8),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              productImage,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error),
                                );
                              },
                            ),
                          ),
                          title: Text(
                            productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                '$productPrice ر.س',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (productDesc != null)
                                Text(
                                  productDesc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.add_shopping_cart),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              _addToCart(doc.id, productName, productImage, double.parse(productPrice));
                              // TODO: Implement cart functionality
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  final String categoryName;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  ProductsPage({required this.categoryName});

  void _addToCart(BuildContext context, String id, String name, String image, double price) {
    final cartState = Provider.of<CartState>(context, listen: false);
    cartState.addItem(
      CartItem(
        id: id,
        name: name,
        image: image,
        price: price,
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تمت الإضافة إلى السلة'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'تراجع',
          onPressed: () {
            cartState.removeItem(id);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('products')
            .where('category', isEqualTo: categoryName)
            .orderBy('name')
            .limit(20) // Pagination for better performance
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('حدث خطأ في تحميل المنتجات'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48),
                  SizedBox(height: 16),
                  Text('لا توجد منتجات في هذا القسم'),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs;
          return GridView.builder(
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productName = product['name']?.toString() ?? 'Unnamed Product';
              final productImage = product['image']?.toString() ?? '';
              final productPrice = product['price']?.toString() ?? '0';
              final productDesc = product['description']?.toString();
              
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              '$productPrice ر.س',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (productDesc != null)
                              Text(
                                productDesc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Spacer(),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _addToCart(context, product.id, productName, productImage, double.parse(productPrice));
                                },
                                child: Text('إضافة للسلة'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CartPage extends StatelessWidget {
  final CartState cartState;

  const CartPage({Key? key, required this.cartState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('سلة التسوق'),
        centerTitle: true,
      ),
      body: cartState.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('السلة فارغة'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: cartState.items.length,
              padding: EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(item.name),
                    subtitle: Text('${item.price} ر.س'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            if (item.quantity > 1) {
                              cartState.updateQuantity(item.id, item.quantity - 1);
                            } else {
                              cartState.removeItem(item.id);
                            }
                          },
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            cartState.updateQuantity(item.id, item.quantity + 1);
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            cartState.removeItem(item.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: cartState.items.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('المجموع'),
                      Text(
                        '${cartState.total} ر.س',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement checkout
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('سيتم تنفيذ عملية الشراء قريباً'),
                        ),
                      );
                    },
                    child: Text('إتمام الشراء'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
