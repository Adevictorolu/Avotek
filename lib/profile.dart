import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 70,
              backgroundImage: AssetImage('assets/image/gif/download (2).jpg'),
            ),
            const Gap(10),
            const Text(
              'ADEMOLA VICTOR',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            const Gap(10),
            const Text(
              'adevictorolu@gmail.com',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500
              ),
            ),
            const Gap(20),
            Container(
              height: 50,
              width: 500,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(30),
                ),
                color: Colors.yellow[400]
              ),
              child: const Center(
                child: Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white
                  ),
                ),
              ),
            ),
            const Gap(20),
            Container(
              height: 50,
              width: 500,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(30),
                ),
                color: Colors.grey[800]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 35,
                    ),
                  ),
                  Text(
                    'Your order history',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400
                    ),
                  ),
                   Padding(
                     padding: EdgeInsets.only(right: 12),
                     child: Icon(Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                     ),
                   ),
                ]
              ),
            ),
            const Gap(20),
            Container(
              height: 50,
              width: 500,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(30),
                ),
                color: Colors.grey[800]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.help_outline,
                    color: Colors.white,
                    size: 35,
                    ),
                  ),
                  Text(
                    'Help and support',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400
                    ),
                  ),
                   Padding(
                     padding: EdgeInsets.only(right: 12),
                     child: Icon(Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                     ),
                   ),
                ]
              ),
            ),
            const Gap(20),
            Container(
              height: 50,
              width: 500,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(30),
                ),
                color: Colors.grey[800]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.card_giftcard,
                    color: Colors.white,
                    size: 35,
                    ),
                  ),
                  Text(
                    'Load gift card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400
                    ),
                  ),
                   Padding(
                     padding: EdgeInsets.only(right: 12),
                     child: Icon(Icons.arrow_forward,
                      color: Colors.white,
                      size: 30,
                     ),
                   ),
                ]
              ),
            ),
            const Gap(20),
            Container(
              height: 50,
              width: 500,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(
                  Radius.circular(30),
                ),
                color: Colors.grey[800]
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.logout,
                    color: Colors.white,
                    size: 35,
                    ),
                  ),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400
                    ),
                  ),
                ]
              ),
            )
          ],
        ),
      ),
    );
  }
}