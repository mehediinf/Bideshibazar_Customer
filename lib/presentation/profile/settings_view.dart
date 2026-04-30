import 'package:flutter/material.dart';
import 'package:bideshibazar/presentation/profile/change_password_view.dart';
import 'package:bideshibazar/presentation/profile/delete_account_view.dart';



class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          _item(
            icon: Icons.notifications_outlined,
            title: "Notification Settings",
            onTap: () {},
          ),

          _item(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangePasswordView(),
                ),
              );
            },
          ),

          _item(
            icon: Icons.delete_outline,
            title: "Delete My Account",
            isDanger: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeleteAccountView(),
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : const Color(0xff2196F3),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            color: isDanger ? Colors.red : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}
