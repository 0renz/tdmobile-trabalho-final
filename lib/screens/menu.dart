import 'package:flutter/material.dart';
import 'biblioteca_gatos.dart';
import 'gatos.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => _MenuOptionsState();
}

class _MenuOptionsState extends State<MenuOptions> {
  static const Color deepPurple = Color(0xFF673AB7);
  static const Color lightPurple = Color(0xFFD1C4E9);

  int pageIndex = 0;
  late final PageController pc;
  final GlobalKey<GatosScreenState> gatosKey =
      GlobalKey<GatosScreenState>();
  String userName = 'Usuário';

  final List<String> paginas = [
    'Encontrar gatos',
    'Biblioteca de gatos',
  ];

  String titulo = 'Encontrar gatos';

  @override
  void initState() {
    super.initState();
    pc = PageController(initialPage: pageIndex);
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      userName = displayName;
    }
    if (currentUser != null) {
      UserService().getUser().then((user) {
        if (user != null && mounted) {
          setState(() {
            userName = user.displayName.trim().isEmpty
                ? 'Usuário'
                : user.displayName;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void setPaginaAtual(int index) {
    setState(() {
      pageIndex = index;
      titulo = paginas[index];
    });
  }

  void irParaPagina(int index) {
    pc.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void selecionarPagina(int index) {
    if (index == 0 && pageIndex != 0) {
      gatosKey.currentState?.loadAnotherCat();
    }
    setPaginaAtual(index);
    irParaPagina(index);
    Navigator.pop(context);
  }

  Future<void> sairDoAplicativo() async {
    Navigator.pop(context);
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      drawer: Drawer(
        width: 290,
        child: Column(
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                24,
                55,
                24,
                28,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    deepPurple,
                    Color(0xFF512DA8),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 36,
                      color: deepPurple,
                    ),
                  ),

                  SizedBox(height: 18),

                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Opções
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.pets_outlined,
                    label: 'Encontrar gatos',
                    onTap: () => selecionarPagina(0),
                  ),
                  _buildMenuItem(
                    index: 1,
                    icon: Icons.collections_bookmark_outlined,
                    label: 'Biblioteca de gatos',
                    onTap: () => selecionarPagina(1),
                  ),

                  const Divider(
                    height: 32,
                    indent: 16,
                    endIndent: 16,
                    thickness: 1,
                  ),

                  _buildMenuItem(
                    index: -1,
                    icon: Icons.login_outlined,
                    label: 'Login',
                    onTap: sairDoAplicativo,
                  ),
                ],
              ),
            ),

            // Rodapé
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),

                      const SizedBox(width: 10),

                      Text(
                        'Criado por Lorenzo!!!!!!',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: PageView(
        controller: pc,
        onPageChanged: setPaginaAtual,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          GatosScreen(key: gatosKey),
          const BibliotecaGatosScreen(),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback? onTap
  }) {
    final bool selecionado = pageIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              color: selecionado
                  ? lightPurple.withOpacity(0.55)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selecionado
                      ? deepPurple
                      : Colors.grey[700],
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selecionado
                          ? deepPurple
                          : Colors.grey[800],
                      fontSize: 16,
                      fontWeight: selecionado
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),

                if (selecionado)
                  const Icon(
                    Icons.chevron_right,
                    color: deepPurple,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
