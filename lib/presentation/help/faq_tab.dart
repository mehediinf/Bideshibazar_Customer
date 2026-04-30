import 'package:flutter/material.dart';

class FaqTab extends StatefulWidget {
  const FaqTab({Key? key}) : super(key: key);

  @override
  State<FaqTab> createState() => _FaqTabState();
}

class _FaqTabState extends State<FaqTab> {
  int? _expandedIndex;

  final List<FaqItem> _faqList = [
    FaqItem(
      question: "How much do deliveries cost?",
      answer: "Enjoy Free Delivery on All Orders.",
    ),
    FaqItem(
      question: "What are your delivery hours?",
      answer: "Deliveries take 30 minutes to 2 hours, depending on the order and location.",
    ),
    FaqItem(
      question: "What is your policy on refunds?",
      answer: "Once the shop approves your order, there is no refund unless the products are defective.\n\n"
          "If the product is defective, customers must return it to the shop, and Bideshi Bazar will verify the issue.\n\n"
          "If the claim is valid, a full refund will be issued. If not, no refund will be provided.",
    ),
    FaqItem(
      question: "What about the prices?",
      answer: "Our prices match the local market, and we always strive to offer the best price to our customers.",
    ),
    FaqItem(
      question: "Do you serve my area?",
      answer: "We serve all of Vienna, with a maximum delivery distance of 6 km from any shop.",
    ),
    FaqItem(
      question: "Is cash on delivery available?",
      answer: "Yes, cash on delivery is possible if the shop approves it. Otherwise, online payment is required.",
    ),
    FaqItem(
      question: "Can I schedule a delivery for a specific time?",
      answer: "Yes, you can select a preferred delivery time slot when placing your order.",
    ),
    FaqItem(
      question: "What happens if no one is available to receive the delivery?",
      answer: "If no one is available, the delivery person will contact you. If the delivery fails, you can reschedule, but additional charges may apply.",
    ),
    FaqItem(
      question: "Do you deliver fresh and frozen items?",
      answer: "Yes, we deliver fresh and frozen items, ensuring they are properly packaged to maintain quality during transit.",
    ),
    FaqItem(
      question: "Are there any additional charges for COD?",
      answer: "No additional charges for cash on delivery unless specified by the shop.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _faqList.length,
      itemBuilder: (context, index) {
        final faq = _faqList[index];
        final isExpanded = _expandedIndex == index;

        return GestureDetector(
          onTap: () {
            setState(() {
              if (_expandedIndex == index) {
                _expandedIndex = null;
              } else {
                _expandedIndex = index;
              }
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q. ${faq.question}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      faq.answer,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({
    required this.question,
    required this.answer,
  });
}