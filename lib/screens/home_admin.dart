import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeAdmin extends StatefulWidget {
  const HomeAdmin({super.key});

  @override
  State<HomeAdmin> createState() => _HomeAdminState();
}

class _HomeAdminState extends State<HomeAdmin> {
  final _db = FirebaseFirestore.instance;
  String _menuAktif = 'kajian';

  final _menuList = [
    {'title': 'Kajian', 'icon': Icons.menu_book, 'collection': 'kajian'},
    {'title': 'Khutbah', 'icon': Icons.mic, 'collection': 'khutbah'},
    {'title': 'Fatwa', 'icon': Icons.question_answer, 'collection': 'fatwa'},
    {'title': 'Muhadhoroh', 'icon': Icons.campaign, 'collection': 'muhadhoroh'},
    {'title': 'Fawaid', 'icon': Icons.lightbulb, 'collection': 'fawaid'},
    {'title': 'PDF', 'icon': Icons.picture_as_pdf, 'collection': 'pdf'},
    {'title': 'Video', 'icon': Icons.video_library, 'collection': 'video'},
  ];

  @override
  Widget build(BuildContext context) {
    final current = _menuList.firstWhere((m) => m['collection'] == _menuAktif);

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin - ${current['title']}'),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(current['collection'] as String),
            tooltip: 'Tambah ${current['title']}',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _buildContent(current['collection'] as String),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green[800]),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text('Admin Dashboard', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Kajian Syaikh Hafidzh', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          ..._menuList.map((menu) => ListTile(
            leading: Icon(menu['icon'] as IconData, color: _menuAktif == menu['collection'] ? Colors.green[800] : null),
            title: Text(menu['title'] as String),
            selected: _menuAktif == menu['collection'],
            selectedTileColor: Colors.green[50],
            onTap: () {
              setState(() => _menuAktif = menu['collection'] as String);
              Navigator.pop(context);
            },
          )),
        ],
      ),
    );
  }

  Widget _buildContent(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection(collection).orderBy('tanggal', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text('Error'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('Belum ada data', style: TextStyle(fontSize: 18, color: Colors.grey[500])),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddDialog(collection),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildCard(docId, data, collection);
          },
        );
      },
    );
  }

  Widget _buildCard(String docId, Map<String, dynamic> data, String collection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(_iconForCollection(collection), color: Colors.green[800]),
        ),
        title: Text(
          data['judul'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${data['kategori'] ?? ''} • ${data['tanggal'] ?? ''}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'hapus', child: Text('Hapus', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(docId, data, collection);
            } else if (value == 'hapus') {
              _hapusItem(docId, data['judul'] ?? '', collection);
            }
          },
        ),
      ),
    );
  }

  IconData _iconForCollection(String col) {
    switch (col) {
      case 'kajian': return Icons.menu_book;
      case 'khutbah': return Icons.mic;
      case 'fatwa': return Icons.question_answer;
      case 'muhadhoroh': return Icons.campaign;
      case 'fawaid': return Icons.lightbulb;
      case 'pdf': return Icons.picture_as_pdf;
      case 'video': return Icons.video_library;
      default: return Icons.article;
    }
  }

  void _showAddDialog(String collection) {
    final judulCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    final pemateriCtrl = TextEditingController(text: 'Asy-Syaikh Hafidzh bin Abdillah Al Junaidi');
    final linkCtrl = TextEditingController();
    final tanggalCtrl = TextEditingController();
    String kategori = 'kajian';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah ${collection.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 8),
              TextField(controller: deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi/Isi'), maxLines: 3),
              if (collection != 'fawaid' && collection != 'pdf' && collection != 'video') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: kategori,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ['kajian', 'khutbah', 'fatwa', 'muhadhoroh']
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => kategori = v!,
                ),
              ],
              if (collection != 'pdf' && collection != 'video') ...[
                const SizedBox(height: 8),
                TextField(controller: pemateriCtrl, decoration: const InputDecoration(labelText: 'Pemateri')),
              ],
              const SizedBox(height: 8),
              TextField(controller: tanggalCtrl, decoration: const InputDecoration(labelText: 'Tanggal (contoh: 20 Juni 2026)')),
              const SizedBox(height: 8),
              TextField(
                controller: linkCtrl,
                decoration: InputDecoration(labelText: collection == 'pdf' ? 'Link PDF (Google Drive)' : (collection == 'video' ? 'Link YouTube' : 'Link YouTube')),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (judulCtrl.text.isEmpty) return;
              final newData = <String, dynamic>{
                'judul': judulCtrl.text,
                'deskripsi': deskripsiCtrl.text,
                'tanggal': tanggalCtrl.text,
              };
              if (collection == 'pdf') {
                newData['link'] = linkCtrl.text;
              } else if (collection == 'video') {
                newData['linkVideo'] = linkCtrl.text;
                newData['kategori'] = 'video';
              } else {
                newData['kategori'] = collection == 'fawaid' ? 'fawaid' : kategori;
                newData['pemateri'] = pemateriCtrl.text;
                newData['linkVideo'] = linkCtrl.text;
              }
              await _db.collection(collection).add(newData);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data, String collection) {
    final judulCtrl = TextEditingController(text: data['judul']);
    final deskripsiCtrl = TextEditingController(text: data['deskripsi']);
    final pemateriCtrl = TextEditingController(text: data['pemateri'] ?? '');
    final linkCtrl = TextEditingController(text: data['linkVideo'] ?? data['link'] ?? '');
    final tanggalCtrl = TextEditingController(text: data['tanggal']);
    String kategori = data['kategori'] ?? 'kajian';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${collection.toUpperCase()}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: judulCtrl, decoration: const InputDecoration(labelText: 'Judul')),
              const SizedBox(height: 8),
              TextField(controller: deskripsiCtrl, decoration: const InputDecoration(labelText: 'Deskripsi/Isi'), maxLines: 3),
              if (collection != 'fawaid' && collection != 'pdf' && collection != 'video') ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: kategori,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: ['kajian', 'khutbah', 'fatwa', 'muhadhoroh']
                      .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => kategori = v!,
                ),
              ],
              if (collection != 'pdf' && collection != 'video') ...[
                const SizedBox(height: 8),
                TextField(controller: pemateriCtrl, decoration: const InputDecoration(labelText: 'Pemateri')),
              ],
              const SizedBox(height: 8),
              TextField(controller: tanggalCtrl, decoration: const InputDecoration(labelText: 'Tanggal')),
              const SizedBox(height: 8),
              TextField(
                controller: linkCtrl,
                decoration: InputDecoration(labelText: collection == 'pdf' ? 'Link PDF' : 'Link YouTube'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final updateData = <String, dynamic>{
                'judul': judulCtrl.text,
                'deskripsi': deskripsiCtrl.text,
                'tanggal': tanggalCtrl.text,
              };
              if (collection == 'pdf') {
                updateData['link'] = linkCtrl.text;
              } else if (collection == 'video') {
                updateData['linkVideo'] = linkCtrl.text;
              } else {
                updateData['kategori'] = collection == 'fawaid' ? 'fawaid' : kategori;
                updateData['pemateri'] = pemateriCtrl.text;
                updateData['linkVideo'] = linkCtrl.text;
              }
              await _db.collection(collection).doc(docId).update(updateData);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _hapusItem(String docId, String judul, String collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus'),
        content: Text('Yakin hapus "$judul"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection(collection).doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}