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
import '../../core/widgets/custom_search_bar.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final AdminService _adminService;
  late TabController _tabController;
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
    _tabController = TabController(length: 3, vsync: this);

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _loadUsers(firstPage: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
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
        title: const Text('Admin Panel'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Buscar usuarios...',
                  onChanged: () {
                    setState(() {});
                  },
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                tabs: const [
                  Tab(text: 'Todos'),
                  Tab(text: 'Moderadores'),
                  Tab(text: 'Administradores'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUserListView(l10n, theme, null, 'ALL'),
                  _buildUserListView(l10n, theme, 'MODERADOR', 'MODS'),
                  _buildUserListView(l10n, theme, 'ADMIN', 'ADMINS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListView(AppLocalizations l10n, ThemeData theme,
      String? roleFilter, String tabKey) {
    // Aplicar filtro de rol si es necesario
    final List<PerfilUsuario> filteredUsers = roleFilter == null
        ? _usuarios
        : _usuarios.where((user) {
            final changes = _pendingChanges[user.id];
            final bool isMod = changes != null && changes.containsKey('mod')
                ? changes['mod']!
                : user.esModerador;
            final bool isAdmin = changes != null && changes.containsKey('admin')
                ? changes['admin']!
                : user.esAdministrador;
            return roleFilter == 'MODERADOR' ? isMod : isAdmin;
          }).toList();

    if (_isLoadingFirst) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
          child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }

    if (filteredUsers.isEmpty) {
      return Center(child: Text(l10n.adminPanelNoUsersFound));
    }

    return ListView.builder(
      key: PageStorageKey('admin_tab_$tabKey'),
      controller: _scrollController,
      itemCount: filteredUsers.length + 1,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        if (index == filteredUsers.length) {
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()))
              : const SizedBox.shrink();
        }

        final user = filteredUsers[index];
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
