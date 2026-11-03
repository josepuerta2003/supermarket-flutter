import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/sample_data.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// Crear o editar un producto.
class AdminProductForm extends StatefulWidget {
  const AdminProductForm({super.key, this.product});

  /// null = producto nuevo.
  final Product? product;

  @override
  State<AdminProductForm> createState() => _AdminProductFormState();
}

class _AdminProductFormState extends State<AdminProductForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _oldPrice;
  late final TextEditingController _unit;
  late final TextEditingController _stock;
  late final TextEditingController _description;
  late String _categoryId;
  late String _emoji;
  late bool _active;
  late bool _featured;

  bool get _isNew => widget.product == null;

  String _num(double? v) => v == null ? '' : formatNumber(v).replaceAll('.', '');

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    final state = context.read<AppState>();
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: _num(p?.price));
    _oldPrice = TextEditingController(text: p?.onSale == true ? _num(p!.oldPrice) : '');
    _unit = TextEditingController(text: p?.unit ?? '');
    _stock = TextEditingController(text: p == null ? '' : '${p.stock}');
    _description = TextEditingController(text: p?.description ?? '');
    _categoryId = p?.categoryId ?? state.categories.first.id;
    _emoji = p?.emoji ?? productEmojis.first;
    _active = p?.active ?? true;
    _featured = p?.featured ?? false;
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _oldPrice, _unit, _stock, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obligatorio' : null;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final category = state.categoryById(_categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Nuevo producto' : 'Editar producto'),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final nav = Navigator.of(context);
                final ok = await confirmDialog(
                  context,
                  title: 'Eliminar producto',
                  message: '¿Eliminar "${widget.product!.name}" del catálogo?',
                  confirmLabel: 'Eliminar',
                  destructive: true,
                );
                if (!ok) return;
                state.deleteProduct(widget.product!);
                nav.pop();
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            Center(
              child: ProductImage(
                emoji: _emoji,
                color: category.color,
                size: 110,
                radius: 26,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final e in productEmojis)
                    GestureDetector(
                      onTap: () => setState(() => _emoji = e),
                      child: Container(
                        width: 44,
                        margin: const EdgeInsets.only(right: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: e == _emoji
                              ? Theme.of(context).colorScheme.primary.withAlpha(40)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En la versión final aquí se sube la foto real del producto.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nombre del producto'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            const Text('Categoría', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in state.categories)
                  ChoiceChip(
                    label: Text('${c.emoji} ${c.name}'),
                    selected: _categoryId == c.id,
                    onSelected: (_) => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio (USD)',
                      prefixText: '\$ ',
                    ),
                    validator: (v) {
                      final n = parseNumber(v ?? '');
                      if (n == null || n <= 0) return 'Precio inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _oldPrice,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Precio antes (oferta)',
                      prefixText: '\$ ',
                      helperText: 'Opcional',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final old = parseNumber(v);
                      final price = parseNumber(_price.text);
                      if (old == null) return 'Número inválido';
                      if (price != null && old <= price) {
                        return 'Debe ser mayor al precio';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Presentación',
                      hintText: 'Ej: Paquete 1 kg',
                    ),
                    validator: _required,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Existencia'),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 0) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible en la tienda'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Destacar en "Lo más pedido"'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: FilledButton(
          onPressed: () => _save(state),
          child: Text(_isNew ? 'Crear producto' : 'Guardar cambios'),
        ),
      ),
    );
  }

  void _save(AppState state) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final price = parseNumber(_price.text)!;
    final old = parseNumber(_oldPrice.text);
    final stock = int.parse(_stock.text.trim());

    if (_isNew) {
      state.addProduct(Product(
        id: state.newProductId(),
        name: _name.text.trim(),
        categoryId: _categoryId,
        price: price,
        oldPrice: old,
        unit: _unit.text.trim(),
        emoji: _emoji,
        description: _description.text.trim(),
        stock: stock,
        active: _active,
        featured: _featured,
      ));
    } else {
      final p = widget.product!
        ..name = _name.text.trim()
        ..categoryId = _categoryId
        ..price = price
        ..oldPrice = old
        ..unit = _unit.text.trim()
        ..emoji = _emoji
        ..description = _description.text.trim()
        ..stock = stock
        ..active = _active
        ..featured = _featured;
      state.productUpdated(p);
    }
    showSnack(context, _isNew ? 'Producto creado' : 'Cambios guardados');
    Navigator.of(context).pop();
  }
}
