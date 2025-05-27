import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initDB(); // Khởi tạo CSDL
  runApp(const MyApp());
}

/// Lớp quản lý SQLite
class DatabaseHelper {
  Database? _db;
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();

  Future<void> initDB() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'warehouse.db');

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Tạo bảng products
        await db.execute(''' 
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT NOT NULL,
            quantity INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Database get db => _db!;

  // Thêm sản phẩm
  Future<int> insertProduct(Product product) async {
    return await db.insert('products', product.toMap());
  }

  // Lấy toàn bộ sản phẩm
  Future<List<Product>> getAllProducts() async {
    final maps = await db.query('products', orderBy: 'name ASC');
    return maps.map((e) => Product.fromMap(e)).toList();
  }

  // Tìm sản phẩm theo barcode
  Future<Product?> getByBarcode(String barcode) async {
    final maps = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (maps.isNotEmpty) {
      return Product.fromMap(maps.first);
    }
    return null;
  }

  // Cập nhật sản phẩm
  Future<int> updateProduct(Product product) async {
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }
}

/// Lớp mô tả sản phẩm
class Product {
  final int? id;
  final String name;
  final String barcode;
  final int quantity;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      quantity: map['quantity'],
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản lý kho - Văn Hiếu - Thiện Khải',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Màn hình chính
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  void _goToAddProduct(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddProductScreen()),
    );
  }

  void _goToList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductListScreen()),
    );
  }

  void _scan(BuildContext context) async {
    var result = await BarcodeScanner.scan();
    if (result.type == ResultType.Barcode) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImportExportScreen(barcode: result.rawContent),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không quét được mã hợp lệ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đặt nền màn hình chính thành trắng
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // Đặt màu nền AppBar thành xanh da trời
        title: const Text('Quản lý kho (QR) - Hiếu và Khải'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _goToAddProduct(context),
                child: const Text('Thêm sản phẩm'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _goToList(context),
                child: const Text('Báo cáo kho'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _scan(context),
                child: const Text('Nhập/Xuất'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Màn hình thêm sản phẩm mới
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');

  Future<void> _saveProduct() async {
    final name = _nameCtrl.text.trim();
    final barcode = _barcodeCtrl.text.trim();
    final quantity = int.tryParse(_qtyCtrl.text) ?? 0;

    if (name.isEmpty || barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ.')),
      );
      return;
    }

    final p = Product(name: name, barcode: barcode, quantity: quantity);
    await DatabaseHelper.instance.insertProduct(p);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm sản phẩm "$name".')),
    );

    Navigator.pop(context);
  }

  Future<void> _scanBarcode() async {
    var result = await BarcodeScanner.scan();
    if (result.type == ResultType.Barcode) {
      setState(() {
        _barcodeCtrl.text = result.rawContent;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không quét được mã hợp lệ.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinkTextFieldDecoration = InputDecoration(
      labelText: '...',
      filled: true,
      fillColor: Colors.pink[50],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink.shade400, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white, // Đặt nền của màn hình này thành trắng
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // Đặt màu nền AppBar thành xanh da trời
        title: const Text('Thêm sản phẩm'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: pinkTextFieldDecoration.copyWith(
                labelText: 'Tên sản phẩm',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeCtrl,
                    decoration: pinkTextFieldDecoration.copyWith(
                      labelText: 'Mã QR/Barcode',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _scanBarcode,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: pinkTextFieldDecoration.copyWith(
                labelText: 'Số lượng ban đầu',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProduct,
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn hình danh sách sản phẩm
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getAllProducts();
    setState(() {
      _products = data;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đặt nền của màn hình này thành trắng
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // Đặt màu nền AppBar thành xanh da trời
        title: const Text('Danh sách sản phẩm'),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('Chưa có sản phẩm.'))
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final p = _products[index];
          return ListTile(
            title: Text(p.name),
            subtitle: Text(
              'Barcode: ${p.barcode} | Số lượng: ${p.quantity}',
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.pink,
        child: const Icon(Icons.refresh),
        onPressed: _loadData,
      ),
    );
  }
}

/// Màn hình nhập/xuất kho sau khi quét
class ImportExportScreen extends StatefulWidget {
  final String barcode;
  const ImportExportScreen({Key? key, required this.barcode}) : super(key: key);

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  Product? _product;
  final _qtyCtrl = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final p = await DatabaseHelper.instance.getByBarcode(widget.barcode);
    setState(() {
      _product = p;
    });
  }

  Future<void> _import() async {
    if (_product == null) return;
    final delta = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (delta <= 0) return;

    final newQty = _product!.quantity + delta;
    final updated = _product!.copyWith(quantity: newQty);
    await DatabaseHelper.instance.updateProduct(updated);
    setState(() {
      _product = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Nhập +$delta → Số lượng = $newQty')),
    );
  }

  Future<void> _export() async {
    if (_product == null) return;
    final delta = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (delta <= 0) return;

    if (delta > _product!.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xuất vượt quá số lượng tồn!')),
      );
      return;
    }
    final newQty = _product!.quantity - delta;
    final updated = _product!.copyWith(quantity: newQty);
    await DatabaseHelper.instance.updateProduct(updated);
    setState(() {
      _product = updated;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Xuất -$delta → Số lượng = $newQty')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinkTextFieldDecoration = InputDecoration(
      labelText: 'Số lượng',
      filled: true,
      fillColor: Colors.pink[50],
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.pink.shade400, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white, // Đặt nền của màn hình này thành trắng
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // Đặt màu nền AppBar thành xanh da trời
        title: const Text('Nhập/Xuất kho'),
      ),
      body: _product == null
          ? Center(
        child: Text(
          'Không tìm thấy sản phẩm với mã: ${widget.barcode}',
          style: const TextStyle(fontSize: 16),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Tên: ${_product!.name}', style: const TextStyle(fontSize: 18)),
            Text('Barcode: ${_product!.barcode}', style: const TextStyle(fontSize: 16)),
            Text('Tồn kho: ${_product!.quantity}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: pinkTextFieldDecoration,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _import,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                  ),
                  child: const Text('Nhập'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _export,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                  ),
                  child: const Text('Xuất'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

/// Hàm mở rộng để copyWith cho Product
extension on Product {
  Product copyWith({
    int? id,
    String? name,
    String? barcode,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
    );
  }
}
