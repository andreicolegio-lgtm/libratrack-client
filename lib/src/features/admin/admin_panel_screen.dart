import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/admin_service.dart';
import '../../model/perfil_usuario.dart';
import '../../model/paginated_response.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import '../../core/utils/api_exceptions.dart';
import 'admin_elemento_form.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final AdminService _adminService;

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

  // --- Gestión de Roles ---

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
          // Actualizar usuario en la lista local
          final index = _usuarios.indexWhere((u) => u.id == user.id);
          if (index != -1) {
            _usuarios[index] = updatedUser;
          }
          // Limpiar cambios pendientes
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminElementoFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.adminPanelCreateElement),
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
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
      padding: const EdgeInsets.only(bottom: 80),
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundImage: user.fotoPerfilUrl != null
                  ? CachedNetworkImageProvider(user.fotoPerfilUrl!)
                  : null,
              child:
                  user.fotoPerfilUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(user.username,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
