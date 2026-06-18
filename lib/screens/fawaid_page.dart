import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class FawaidPage extends StatelessWidget {
  const FawaidPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fawaid').orderBy('tanggal', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error', style: TextStyle(fontFamily: 'Poppins')));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('Belum ada fawaid', style: TextStyle(fontSize: 16, fontFamily: 'Poppins', color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildFawaidCard(data, isDark);
          },
        );
      },
    );
  }

  Widget _buildFawaidCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFC107).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb, color: Color(0xFFFFC107), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data['judul'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                    color: isDark ? Colors.white : AppTheme.hitamTeks,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['deskripsi'] ?? '',
            style: TextStyle(
              fontSize: 14,
              height: 1.7,
              fontFamily: 'Poppins',
              color: isDark ? Colors.grey[400] : AppTheme.hitamTeks.withOpacity(0.8),
            ),
          ),
          if (data['tanggal'] != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  data['tanggal'],
                  style: TextStyle(fontSize: 12, fontFamily: 'Poppins', color: Colors.grey[500]),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}