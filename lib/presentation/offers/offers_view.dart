//lib/presentation/offers/offers_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'offers_viewmodel.dart';
import 'widgets/offer_card.dart';

class OffersView extends StatefulWidget {
  const OffersView({super.key});

  @override
  State<OffersView> createState() => _OffersViewState();
}

class _OffersViewState extends State<OffersView> {
  @override
  void initState() {
    super.initState();
    // Fetch offers when view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OffersViewModel>().fetchOffers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OffersViewModel>(
      builder: (context, vm, child) {
        if (!vm.isLoading && vm.errorMessage == null && vm.offers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Special Offers',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all offers page
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 200, child: _buildOffersList(vm)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOffersList(OffersViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(
              'Failed to load offers',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => vm.fetchOffers(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (vm.offers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No offers available',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: vm.offers.length,
      itemBuilder: (context, index) {
        final offer = vm.offers[index];
        final product = vm.getFirstProduct(offer);

        return OfferCard(offer: offer, product: product);
      },
    );
  }
}
