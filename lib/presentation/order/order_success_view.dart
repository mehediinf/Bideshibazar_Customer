// // lib/presentation/order/order_success_view.dart
//
// import 'package:flutter/material.dart';
//
// class OrderSuccessView extends StatelessWidget {
//   const OrderSuccessView({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(24),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Container(
//                   width: 120,
//                   height: 120,
//                   decoration: BoxDecoration(
//                     color: Colors.green[50],
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.check_circle,
//                     color: Colors.green,
//                     size: 80,
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 const Text(
//                   'Order Placed Successfully!',
//                   style: TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Your order has been placed successfully. You will receive a confirmation shortly.',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey[600],
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 48),
//                 SizedBox(
//                   width: double.infinity,
//                   height: 50,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.pushNamedAndRemoveUntil(
//                         context,
//                         '/home',
//                             (route) => false,
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF0095FF),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     child: const Text(
//                       'Back to Home',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 OutlinedButton(
//                   onPressed: () {
//                     Navigator.pushNamed(context, '/orders');
//                   },
//                   style: OutlinedButton.styleFrom(
//                     minimumSize: const Size(double.infinity, 50),
//                     side: const BorderSide(color: Color(0xFF0095FF)),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: const Text(
//                     'View Orders',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Color(0xFF0095FF),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }