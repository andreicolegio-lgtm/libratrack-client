import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/admin_service.dart';
import '../../model/perfil_usuario.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../core/utils/error_translator.dart';
import 'admin_elemento_form.dart';
import '../../model/paginated_response.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../core/utils/api_exceptions.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() {
    return _AdminPanelScreenState();
  }
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  late final AdminService _adminService;

  final List<PerfilUsuario> _usuarios = <PerfilUsuario>[];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _roleFilter;

  final Map<int, Map<String, bool>> _pendingChanges =
      <int, Map<String, bool>>{};

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();

    _adminService = context.read<AdminService>();

    _scrollController.addListener(_onScroll);

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataLoaded) {
      _loadUsers(isFirstPage: true);
      _isDataLoaded = true;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    if (_isLoadingMore || !_hasNextPage) {
      return;
    }
    _loadUsers();
  }

  Future<void> _loadUsers({bool isFirstPage = false}) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    if (isFirstPage) {
      setState(() {
        _isLoadingFirstPage = true;
        _currentPage = 0;
        _usuarios.clear();
        _pendingChanges.clear();
        _hasNextPage = true;
        _loadingError = null;
      });
    } else {
      if (_isLoadingMore) {
        return;
      }
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final PaginatedResponse<PerfilUsuario> respuesta =
          await _adminService.getUsuarios(
        page: _currentPage,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        roleFilter: _roleFilter,
      );

      if (mounted) {
        setState(() {
          _usuarios.addAll(respuesta.content);
          _currentPage++;
          _hasNextPage = !respuesta.isLast;

          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = ErrorTranslator.translate(context, e.message);
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = l10n.errorLoadingUsers(e.toString());
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _reiniciarBusqueda() {
    _debounce?.cancel();
    _loadUsers(isFirstPage: true);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reiniciarBusqueda();
    });
  }

  void _onFilterChanged(String? newFilter) {
    setState(() {
      _roleFilter = newFilter;
    });
    _reiniciarBusqueda();
  }

  void _onRoleChanged(int userId, String role, bool newValue) {
    setState(() {
      _pendingChanges.putIfAbsent(userId, () => <String, bool>{});
      _pendingChanges[userId]![role] = newValue;
    });
  }

  Future<void> _handleUpdateRoles(int userId, PerfilUsuario currentUser) async {
    final Map<String, bool>? changes = _pendingChanges[userId];
    if (changes == null) {
      return;
    }

    final bool esModerador = changes['mod'] ?? currentUser.esModerador;
    final bool esAdministrador =
        changes['admin'] ?? currentUser.esAdministrador;

    final ScaffoldMessengerState msgContext = ScaffoldMessenger.of(context);
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    try {
      final int editingUserId = userId;

      await _adminService.updateUserRoles(
        editingUserId,
        esModerador,
        esAdministrador,
      );

      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          msgContext, l10n.snackbarAdminRolesUpdated(currentUser.username),
          isError: false);

      setState(() {
        _pendingChanges.remove(editingUserId);
        int index =
            _usuarios.indexWhere((PerfilUsuario u) => u.id == editingUserId);
        if (index != -1) {
          _usuarios[index] = PerfilUsuario(
              id: currentUser.id,
              username: currentUser.username,
              email: currentUser.email,
              fotoPerfilUrl: currentUser.fotoPerfilUrl,
              esModerador: esModerador,
              esAdministrador: esAdministrador);
        }
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          msgContext, l10n.errorUpdatingRoles(e.toString()),
          isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      SnackBarHelper.showTopSnackBar(
          msgContext, l10n.errorUnexpected(e.toString()),
          isError: true);
    }
  }

  void _goToCrearElemento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const AdminElementoFormScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileAdminPanelButton,
            style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112.0),
          child: Column(
            children: <Widget>[
              _buildSearchField(context, l10n),
              _buildFilterChips(context, l10n),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.adminPanelCreateElement),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _goToCrearElemento,
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildSearchField(BuildContext context, AppLocalizations l10n) {
    final Color iconColor =
        Theme.of(context).colorScheme.onSurface.withAlpha(0x80);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: l10n.adminPanelSearchHint,
          hintStyle: Theme.of(context).textTheme.labelLarge,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
          prefixIcon: Icon(Icons.search, color: iconColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: iconColor),
                  onPressed: () {
                    _searchController.clear();
                    _reiniciarBusqueda();
                  },
                )
              : null,
        ),
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _reiniciarBusqueda(),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FilterChip(
            label: Text(l10n.adminPanelFilterAll),
            selected: _roleFilter == null,
            onSelected: (bool val) => _onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.adminPanelFilterMods),
            selected: _roleFilter == 'MODERADOR',
            onSelected: (bool val) => _onFilterChanged('MODERADOR'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.adminPanelFilterAdmins),
            selected: _roleFilter == 'ADMIN',
            onSelected: (bool val) => _onFilterChanged('ADMIN'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoadingFirstPage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(
          child:
              Text(_loadingError!, style: const TextStyle(color: Colors.red)));
    }
    if (_usuarios.isEmpty) {
      return Center(child: Text(l10n.adminPanelNoUsersFound));
    }

    return ListView.builder(
      controller: _scrollController,
      padding:
          const EdgeInsets.only(bottom: 96.0, top: 8.0, left: 8.0, right: 8.0),
      itemCount: _usuarios.length + 1,
      itemBuilder: (BuildContext context, int index) {
        if (index == _usuarios.length) {
          return _hasNextPage
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ))
              : const SizedBox(height: 1);
        }

        final PerfilUsuario user = _usuarios[index];
        final bool hasChanges = _pendingChanges.containsKey(user.id);
        final bool isMod = _pendingChanges[user.id]?['mod'] ?? user.esModerador;
        final bool isAdmin =
            _pendingChanges[user.id]?['admin'] ?? user.esAdministrador;

        return Card(
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            title: Row(
              children: <Widget>[
                _buildAvatar(context, user.fotoPerfilUrl),
                const SizedBox(width: 16),
                Text(user.username,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            subtitle:
                Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            children: <Widget>[
              const Divider(height: 1),
              SwitchListTile.adaptive(
                title: Text(l10n.adminPanelRoleMod),
                value: isMod,
                onChanged: (bool val) => _onRoleChanged(user.id, 'mod', val),
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
              SwitchListTile.adaptive(
                title: Text(l10n.adminPanelRoleAdmin),
                value: isAdmin,
                onChanged: (bool val) => _onRoleChanged(user.id, 'admin', val),
                activeTrackColor: Colors.purple[700],
              ),
              if (hasChanges)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                    child: TextButton(
                      child: Text(l10n.adminPanelSaveButton),
                      onPressed: () => _handleUpdateRoles(user.id, user),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surface,
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: const Icon(Icons.person_outline, size: 20),
    );
  }
}
