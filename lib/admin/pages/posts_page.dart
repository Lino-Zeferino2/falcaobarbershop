// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:typed_data';
import '../controller/admin_controller.dart';
import '../model/post_model.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final AdminController _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        title: const Text('Gestão de Posts', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showPostDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar posts...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<PostModel>>(
              stream: _adminController.getAllPosts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
                }

                final posts = snapshot.data ?? [];
                final filteredPosts = posts.where((post) {
                  final matchesSearch = post.description.toLowerCase().contains(_searchController.text.toLowerCase());
                  return matchesSearch;
                }).toList();

                if (filteredPosts.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhum post encontrado',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
                    return _buildPostCard(post);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFB22222),
        onPressed: () => _showPostDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      color: const Color(0xFF2A2A2A),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Post',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showPostDialog(post: post);
                        break;
                      case 'delete':
                        _deletePost(post.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    const PopupMenuItem(value: 'delete', child: Text('Excluir')),
                  ],
                  child: const Icon(Icons.more_vert, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              SizedBox(
                height: 150,
                width: double.infinity,
                child: Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
  debugPrint('Error loading image: $error, url: ${post.imageUrl}');
  return Container(
    color: const Color(0xFF2A2A2A),
    child: const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_outlined, color: Colors.white38, size: 32),
          SizedBox(height: 6),
          Text(
            'Não foi possível carregar a imagem',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    ),
  );
},
                ),
              ),
            const SizedBox(height: 12),
            MediaQuery.of(context).size.width < 768
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Criado em: ${_formatDate(post.createdAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atualizado em: ${_formatDate(post.updatedAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Criado em: ${_formatDate(post.createdAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      Text(
                        'Atualizado em: ${_formatDate(post.updatedAt)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showPostDialog({PostModel? post}) {
    final isEditing = post != null;
    final descriptionController = TextEditingController(text: post?.description ?? '');
    final imageUrlController = TextEditingController(text: post?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(
          isEditing ? 'Editar Post' : 'Novo Post',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFB22222)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'URL da Imagem (opcional)',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFB22222)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white70),
                    onPressed: () => _pickImage(),
                  ),
                ],
              ),
              if (_selectedImageBytes != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Image.memory(_selectedImageBytes!, height: 100, width: 100, fit: BoxFit.cover),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => _savePost(
              descriptionController.text,
              imageUrlController.text,
              post: post,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB22222),
              foregroundColor: Colors.white,
            ),
            child: Text(isEditing ? 'Salvar' : 'Criar'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePost(String description, String imageUrl, {PostModel? post}) async {
    print('DEBUG _savePost: Iniciando _savePost');
    print('DEBUG _savePost: description = $description');
    print('DEBUG _savePost: imageUrl = $imageUrl');
    print('DEBUG _savePost: post = $post');

    if (description.isEmpty) {
      print('DEBUG _savePost: Descrição vazia, retornando');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha a descrição')),
      );
      return;
    }if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('URL da imagem inválida. Deve começar com http:// ou https://')),
  );
  return;
}

    try {
      String? finalImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
      print('DEBUG _savePost: finalImageUrl inicial = $finalImageUrl');

      // If an image is selected, upload it to Firebase Storage
      if (_selectedImage != null) {
        print('DEBUG _savePost: Fazendo upload da imagem');
        print('DEBUG _savePost: _selectedImage.path = ${_selectedImage!.path}');

        try {
          final random = Random();
          final fileName = 'posts/${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}.jpg';
          final storageRef = FirebaseStorage.instance.ref().child(fileName);
          print('DEBUG _savePost: Tentando upload para $fileName');

          // Read file as bytes to work on both mobile and web
          final bytes = await _selectedImage!.readAsBytes();
          print('DEBUG _savePost: Bytes lidos, tamanho = ${bytes.length}');

          await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          finalImageUrl = await storageRef.getDownloadURL();
          print('DEBUG _savePost: Upload concluído, finalImageUrl = $finalImageUrl');
        } catch (e) {
          print('ERROR _savePost: Erro ao fazer upload: $e');
          throw Exception('Erro ao fazer upload da imagem: $e');
        }
      }

      final now = DateTime.now();
      print('DEBUG _savePost: now = $now');
      final postData = PostModel(
        id: post?.id ?? '',
        description: description,
        imageUrl: finalImageUrl,
        createdAt: post?.createdAt ?? now,
        updatedAt: now,
      );
      print('DEBUG _savePost: postData criado = ${postData.toMap()}');

      if (post != null) {
        print('DEBUG _savePost: Atualizando post existente');
        // Update existing
        await _adminController.updatePost(postData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post atualizado com sucesso!')),
        );
      } else {
        print('DEBUG _savePost: Criando novo post');
        // Create new
        await _adminController.addPost(postData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post criado com sucesso!')),
        );
      }

      // Reset selected image
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
      });

      Navigator.of(context).pop();
    } catch (e) {
      print('ERROR _savePost: Erro ao salvar post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar post: $e')),
      );
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja excluir este post? Essa ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _adminController.deletePost(postId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post excluído com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir post: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = pickedFile;
        _selectedImageBytes = bytes;
      });
    }
  }
}
