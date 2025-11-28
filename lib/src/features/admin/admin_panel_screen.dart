import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/admin_service.dart';
import '../../core/services/auth_service.dart';
import '../../model/perfil_usuario.dart';
import '../../model/paginated_response.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/utils/api_exceptions.dart';
import 'admin_elemento_form.dart';
import 'admin_created_elements_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final AdminService _adminService;
  int? _currentUserId;

  // Estado de Datos
  final List<PerfilUsuario> _usuarios = [];
  final ScrollController _scrollController = ScrollController();

  // Paginación
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirst = true;
  bool _isLoadingMore = false;
  String? _error;

  // Búsqueda y Filtros
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String? _roleFilter;

  // Cambios Locales (UserId -> {role: value})
  final Map<int, Map<String, bool>> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    _adminService = context.read<AdminService>();
    final authService = context.read<AuthService>();
    _currentUserId = authService.currentUser?.id;

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadUsers(firstPage: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadUsers();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadUsers(firstPage: true);
    });
  }

  Future<void> _loadUsers({bool firstPage = false}) async {
    if (firstPage) {
      setState(() {
        _isLoadingFirst = true;
        _currentPage = 0;
        _usuarios.clear();
        _pendingChanges.clear();
        _hasNextPage = true;
        _error = null;
      });
    } else {
      if (_isLoadingMore || !_hasNextPage) {
        return;
      }
      setState(() => _isLoadingMore = true);
    }

    try {
      final PaginatedResponse<PerfilUsuario> response =
          await _adminService.getUsuarios(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        roleFilter: _roleFilter,
      );

      if (mounted) {
        setState(() {
          _usuarios.addAll(response.content);

          // Si el usuario actual está en la lista, lo movemos al índice 0
          if (_currentUserId != null) {
            final int myIndex =
                _usuarios.indexWhere((u) => u.id == _currentUserId);
            if (myIndex > 0) {
              final me = _usuarios.removeAt(myIndex);
              _usuarios.insert(0, me);
            }
          }

          _currentPage++;
          _hasNextPage = !response.isLast;
          _isLoadingFirst = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFirst = false;
          _isLoadingMore = false;
          _error = e.toString();
        });
      }
    }
  }

  // --- Gestión de Roles (Sin cambios en lógica) ---

  void _onRoleChanged(int userId, String role, bool value) {
    setState(() {
      if (!_pendingChanges.containsKey(userId)) {
        _pendingChanges[userId] = {};
      }
      _pendingChanges[userId]![role] = value;
    });
  }

  Future<void> _saveRoles(PerfilUsuario user) async {
    final changes = _pendingChanges[user.id];
    if (changes == null) {
      return;
    }

    final bool newMod =
        changes.containsKey('mod') ? changes['mod']! : user.esModerador;
    final bool newAdmin =
        changes.containsKey('admin') ? changes['admin']! : user.esAdministrador;

    final l10n = AppLocalizations.of(context);

    try {
      final updatedUser =
          await _adminService.updateUserRoles(user.id, newMod, newAdmin);

      if (mounted) {
        setState(() {
          final index = _usuarios.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _usuarios[index] = updatedUser;
            // Re-verificar orden por si acaso (opcional)
          }
          _pendingChanges.remove(user.id);
        });

        SnackBarHelper.showTopSnackBar(
            context, l10n.snackbarAdminRolesUpdated(user.username),
            isError: false);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (e is ApiException) {
          msg = ErrorTranslator.translate(context, e.message);
        }
        SnackBarHelper.showTopSnackBar(context, msg, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAdminPanelButton),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.adminPanelSearchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        if (value.text.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: l10n.adminPanelFilterAll,
                      isSelected: _roleFilter == null,
                      onSelected: () => setState(() {
                        _roleFilter = null;
                        _loadUsers(firstPage: true);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.adminPanelFilterMods,
                      isSelected: _roleFilter == 'MODERADOR',
                      onSelected: () => setState(() {
                        _roleFilter = 'MODERADOR';
                        _loadUsers(firstPage: true);
                      }),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: l10n.adminPanelFilterAdmins,
                      isSelected: _roleFilter == 'ADMIN',
                      onSelected: () => setState(() {
                        _roleFilter = 'ADMIN';
                        _loadUsers(firstPage: true);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),

      // 3. BOTONES SIMÉTRICOS (HISTORIAL Y CREAR)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón Izquierdo: Historial
            FloatingActionButton.extended(
              heroTag: 'btnHistory', // Necesario tag único
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminCreatedElementsScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Historial'), // Idealmente l10n.history
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
            ),

            // Botón Derecho: Crear Elemento
            FloatingActionButton.extended(
              heroTag: 'btnCreate', // Necesario tag único
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdminElementoFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.adminPanelCreateElement),
            ),
          ],
        ),
      ),

      // 1. SAFE ZONE APLICADA AL CUERPO
      body: SafeArea(
        child: _buildBody(l10n, theme),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, ThemeData theme) {
    if (_isLoadingFirst) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (_usuarios.isEmpty) {
      return Center(child: Text(l10n.adminPanelNoUsersFound));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _usuarios.length + 1,
      // 4. PADDING INFERIOR AUMENTADO
      // 100px asegura que el último item se vea por encima de los botones flotantes
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        if (index == _usuarios.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox.shrink();
        }

        final user = _usuarios[index];
        final changes = _pendingChanges[user.id];
        final bool isMod = changes != null && changes.containsKey('mod')
            ? changes['mod']!
            : user.esModerador;
        final bool isAdmin = changes != null && changes.containsKey('admin')
            ? changes['admin']!
            : user.esAdministrador;
        final bool hasUnsavedChanges = changes != null && changes.isNotEmpty;
        final bool isMe = _currentUserId != null && user.id == _currentUserId;

        return Card(
          // Resaltado visual si soy yo
          shape: isMe
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary, width: 2))
              : null,
          color: isMe ? theme.colorScheme.primaryContainer.withAlpha(50) : null,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundImage: user.fotoPerfilUrl != null
                  ? CachedNetworkImageProvider(user.fotoPerfilUrl!)
                  : null,
              child:
                  user.fotoPerfilUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'TÚ',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ]
              ],
            ),
            subtitle: Text(user.email),
            children: [
              SwitchListTile(
                title: Text(l10n.adminPanelRoleMod),
                value: isMod,
                onChanged: (val) => _onRoleChanged(user.id, 'mod', val),
              ),
              SwitchListTile(
                title: Text(l10n.adminPanelRoleAdmin),
                value: isAdmin,
                onChanged: (val) => _onRoleChanged(user.id, 'admin', val),
              ),
              if (hasUnsavedChanges)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => _saveRoles(user),
                      icon: const Icon(Icons.save),
                      label: Text(l10n.adminPanelSaveButton),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }
}
