// lib/data/models/cart_product_item.dart

class CartProductItem extends StatelessWidget {
  final String image;
  final String title;
  final double price;
  final int quantity;
  final String unit;

  const CartProductItem({
    super.key,
    required this.image,
    required this.title,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Image.asset(
            image,
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "€ ${price.toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
              ),
              _QuantityControl(quantity: quantity),
            ],
          )
        ],
      ),
    );
  }
}


