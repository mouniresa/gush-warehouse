import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const GushWarehouseApp());
}

/// Gush Global Color Palette
class GushColors {
  static const Color primary = Color(0xFF7D1BFF); // Gush signature purple
  static const Color primaryDark = Color(0xFF5A08C9);
  static const Color background = Color(0xFFF7F8FA);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color stockInGreen = Color(0xFF10B981);
  static const Color stockOutRed = Color(0xFFEF4444);
}

/// Simple Localization Dictionary
class AppStrings {
  static const Map<String, Map<String, String>> localizedValues = {
    'en': {
      'app_title': 'Gush Warehouse',
      'search_hint': 'Search product name or SKU...',
      'total_products': 'Total SKUs',
      'total_stock': 'Total Items',
      'stock_in': 'Stock IN',
      'stock_out': 'Stock OUT',
      'add_product': 'Add Product',
      'sku': 'SKU / Barcode',
      'product_name': 'Product Name',
      'initial_qty': 'Initial Quantity',
      'current_qty': 'Stock',
      'take_photo': 'Take Photo',
      'choose_gallery': 'Choose from Gallery',
      'save': 'Save Product',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'qty_to_change': 'Enter quantity:',
      'insufficient_stock': 'Cannot stock out: Quantity exceeds current stock!',
      'no_products': 'No products in warehouse yet. Tap "+" to add one.',
      'photo_required': 'Please select an image',
      'field_required': 'This field is required',
    },
    'zh': {
      'app_title': 'Gush 仓储管理',
      'search_hint': '搜索商品名称或SKU编号...',
      'total_products': '商品种类',
      'total_stock': '库存总量',
      'stock_in': '入库 (+)',
      'stock_out': '出库 (-)',
      'add_product': '新增商品',
      'sku': '商品编号 / SKU',
      'product_name': '商品名称',
      'initial_qty': '初始库存数量',
      'current_qty': '当前库存',
      'take_photo': '拍照上传',
      'choose_gallery': '从相册选择',
      'save': '保存商品',
      'cancel': '取消',
      'confirm': '确定',
      'qty_to_change': '请输入操作数量：',
      'insufficient_stock': '出库失败：出库数量大于现有库存！',
      'no_products': '仓库暂无商品，点击右下角 “+” 添加',
      'photo_required': '请选择商品图片',
      'field_required': '此项为必填项',
    },
  };

  static String get(String key, String lang) {
    return localizedValues[lang]?[key] ?? key;
  }
}

class Product {
  final String id;
  final String name;
  final String sku;
  int quantity;
  final String? imagePath;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.quantity,
    this.imagePath,
  });
}

class GushWarehouseApp extends StatefulWidget {
  const GushWarehouseApp({super.key});

  @override
  State<GushWarehouseApp> createState() => _GushWarehouseAppState();
}

class _GushWarehouseAppState extends State<GushWarehouseApp> {
  String _currentLang = 'en'; // Default English

  void _toggleLanguage() {
    setState(() {
      _currentLang = _currentLang == 'en' ? 'zh' : 'en';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gush Warehouse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: GushColors.background,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: GushColors.primary),
        useMaterial3: true,
      ),
      home: WarehouseHomeScreen(
        lang: _currentLang,
        onToggleLanguage: _toggleLanguage,
      ),
    );
  }
}

class WarehouseHomeScreen extends StatefulWidget {
  final String lang;
  final VoidCallback onToggleLanguage;

  const WarehouseHomeScreen({
    super.key,
    required this.lang,
    required this.onToggleLanguage,
  });

  @override
  State<WarehouseHomeScreen> createState() => _WarehouseHomeScreenState();
}

class _WarehouseHomeScreenState extends State<WarehouseHomeScreen> {
  final List<Product> _products = [];
  String _searchQuery = '';

  String t(String key) => AppStrings.get(key, widget.lang);

  // Quick In / Out Stock logic
  void _updateStock(Product product, int delta) {
    if (delta < 0 && product.quantity + delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('insufficient_stock')),
          backgroundColor: GushColors.stockOutRed,
        ),
      );
      return;
    }
    setState(() {
      product.quantity += delta;
    });
  }

  void _showStockDialog(Product product, bool isStockIn) {
    final controller = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isStockIn ? '${t('stock_in')}: ${product.name}' : '${t('stock_out')}: ${product.name}',
          style: TextStyle(
            color: isStockIn ? GushColors.stockInGreen : GushColors.stockOutRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t('current_qty')}: ${product.quantity}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: t('qty_to_change'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t('cancel'), style: const TextStyle(color: GushColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isStockIn ? GushColors.stockInGreen : GushColors.stockOutRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = int.tryParse(controller.text) ?? 0;
              if (val > 0) {
                _updateStock(product, isStockIn ? val : -val);
              }
              Navigator.pop(ctx);
            },
            child: Text(t('confirm')),
          ),
        ],
      ),
    );
  }

  void _openAddProductModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddProductSheet(
        lang: widget.lang,
        onProductAdded: (newProd) {
          setState(() {
            _products.insert(0, newProd);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList();

    int totalStock = _products.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: GushColors.primary,
        elevation: 0,
        title: Row(
          children: [
            // Gush stylized logo circle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.all_inbox_rounded, color: GushColors.primary, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              t('app_title'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          // Language Switcher Button
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: OutlinedButton(
              onPressed: widget.onToggleLanguage,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white, width: 1.5),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                widget.lang == 'en' ? '中文' : 'EN',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Statistics Banner
          Container(
            color: GushColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(t('total_products'), '${_products.length}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(t('total_stock'), '$totalStock'),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: GushColors.textMuted),
                hintText: t('search_hint'),
                hintStyle: const TextStyle(fontSize: 14, color: GushColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      t('no_products'),
                      style: const TextStyle(color: GushColors.textMuted, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildProductCard(item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProductModal,
        backgroundColor: GushColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          t('add_product'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String val) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 68,
                height: 68,
                color: Colors.grey[200],
                child: item.imagePath != null
                    ? Image.file(
                        File(item.imagePath!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 36),
              ),
            ),
            const SizedBox(width: 14),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextNavigatorState == null ? TextOverflow.ellipsis : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: GushColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item.sku}',
                    style: const TextStyle(fontSize: 12, color: GushColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${t('current_qty')}: ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: item.quantity <= 5 ? GushColors.stockOutRed : GushColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // In / Out Quick Action Buttons
            Column(
              children: [
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _showStockDialog(item, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GushColors.stockInGreen.withOpacity(0.12),
                      elevation: 0,
                      foregroundColor: GushColors.stockInGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(t('stock_in'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _showStockDialog(item, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GushColors.stockOutRed.withOpacity(0.12),
                      elevation: 0,
                      foregroundColor: GushColors.stockOutRed,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(t('stock_out'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal Sheet to Add Product with Camera or Gallery Picture
class AddProductSheet extends StatefulWidget {
  final String lang;
  final Function(Product) onProductAdded;

  const AddProductSheet({super.key, required this.lang, required this.onProductAdded});

  @override
  State<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends State<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  String? _imagePath;

  String t(String key) => AppStrings.get(key, widget.lang);

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _imagePath = picked.path;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        quantity: int.tryParse(_qtyController.text) ?? 0,
        imagePath: _imagePath,
      );
      widget.onProductAdded(newProduct);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('add_product'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GushColors.textDark),
              ),
              const SizedBox(height: 16),

              // Image Selector Preview
              Center(
                child: GestureDetector(
                  onTap: () => _showImageSourcePicker(),
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo, color: GushColors.primary, size: 30),
                              const SizedBox(height: 6),
                              Text(
                                t('take_photo'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, color: GushColors.textMuted),
                              )
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t('product_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.isEmpty ? t('field_required') : null,
              ),
              const SizedBox(height: 12),

              // SKU Field
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: t('sku'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (val) => val == null || val.isEmpty ? t('field_required') : null,
              ),
              const SizedBox(height: 12),

              // Initial Qty Field
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: t('initial_qty'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GushColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  t('save'),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: GushColors.primary),
              title: Text(t('take_photo')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: GushColors.primary),
              title: Text(t('choose_gallery')),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
