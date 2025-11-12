// lib/src/features/admin/admin_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; 
import 'package:libratrack_client/src/core/services/admin_service.dart';
import 'package:libratrack_client/src/model/perfil_usuario.dart';
import 'package:libratrack_client/src/core/utils/snackbar_helper.dart';
import 'package:libratrack_client/src/features/admin/admin_elemento_form.dart'; 
// --- ¡NUEVAS IMPORTACIONES! ---
import 'package:libratrack_client/src/model/paginated_response.dart';
import 'dart:async'; // Para el Debouncer

/// Pantalla para que los Admins gestionen los roles de los usuarios (Petición 14).
/// --- ¡ACTUALIZADO (Sprint 7 / Petición B, C, G)! ---
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final AdminService _adminService = AdminService();
  
  // --- ¡NUEVO ESTADO DE LISTA Y PAGINACIÓN! (Petición B) ---
  final List<PerfilUsuario> _usuarios = [];
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isLoadingFirstPage = true;
  bool _isLoadingMore = false;
  String? _loadingError;

  // --- ¡NUEVO ESTADO DE BÚSQUEDA! (Petición C) ---
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // --- ¡NUEVO ESTADO DE FILTRO! (Petición G) ---
  String? _roleFilter; // null = Todos, "MODERADOR" = Mods, "ADMIN" = Admins

  // --- Estado de UI (Petición E) ---
  final Map<int, Map<String, bool>> _pendingChanges = {};

  @override
  void initState() {
    super.initState();
    // 1. Cargamos la primera página
    _loadUsers(isFirstPage: true);
    
    // 2. Listener para scroll infinito (Petición B)
    _scrollController.addListener(_onScroll);
    
    // 3. Listener para la barra de búsqueda (Petición C)
    _searchController.addListener(_onSearchChanged);
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
  
  // --- Lógica de Carga y Paginación (Petición B) ---
  
  /// Listener del Scroll
  void _onScroll() {
    if (_scrollController.position.pixels < _scrollController.position.maxScrollExtent - 200) return;
    if (_isLoadingMore || !_hasNextPage) return;
    _loadUsers();
  }

  /// Carga usuarios (primera página o siguientes)
  Future<void> _loadUsers({bool isFirstPage = false}) async {
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
      if (_isLoadingMore) return;
      setState(() { _isLoadingMore = true; });
    }

    try {
      final PaginatedResponse<PerfilUsuario> respuesta = 
          await _adminService.getAllUsuarios(
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingError = e.toString().replaceFirst("Exception: ", "");
          _isLoadingFirstPage = false;
          _isLoadingMore = false;
        });
      }
    }
  }
  
  // --- Lógica de Búsqueda y Filtros (Petición C, G) ---
  
  /// Reinicia la búsqueda (al cambiar filtros o texto)
  void _reiniciarBusqueda() {
    _debounce?.cancel(); // Cancela búsquedas anteriores
    _loadUsers(isFirstPage: true);
  }
  
  /// Añade un "Debouncer" a la búsqueda para no llamar a la API en cada tecla
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _reiniciarBusqueda();
    });
  }
  
  /// Maneja el clic en los chips de filtro
  void _onFilterChanged(String? newFilter) {
    setState(() {
      _roleFilter = newFilter;
    });
    _reiniciarBusqueda();
  }

  // --- Lógica de Roles (Petición 14, E) ---

  void _onRoleChanged(int userId, String role, bool newValue) {
    setState(() {
      _pendingChanges.putIfAbsent(userId, () => {});
      _pendingChanges[userId]![role] = newValue;
    });
  }

  Future<void> _handleUpdateRoles(int userId, PerfilUsuario currentUser) async {
    final changes = _pendingChanges[userId];
    if (changes == null) return; 

    final bool esModerador = changes['mod'] ?? currentUser.esModerador;
    final bool esAdministrador = changes['admin'] ?? currentUser.esAdministrador;
    
    final msgContext = ScaffoldMessenger.of(context);
    
    try {
      // Guardamos una copia del ID por si la lista se refresca
      final int editingUserId = userId; 
      await _adminService.updateUserRoles(
        editingUserId, 
        esModerador: esModerador, 
        esAdministrador: esAdministrador
      );
      
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, 'Roles de ${currentUser.username} actualizados.', isError: false);
      
      // Actualizamos solo el usuario modificado en la lista local
      // (en lugar de recargar todo)
      setState(() {
        _pendingChanges.remove(editingUserId);
        // Buscamos el índice y actualizamos el objeto
        int index = _usuarios.indexWhere((u) => u.id == editingUserId);
        if (index != -1) {
          _usuarios[index] = PerfilUsuario(
            id: currentUser.id, 
            username: currentUser.username, 
            email: currentUser.email, 
            fotoPerfilUrl: currentUser.fotoPerfilUrl, 
            esModerador: esModerador, 
            esAdministrador: esAdministrador
          );
        }
      });
      
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showTopSnackBar(msgContext, 'Error al actualizar roles: ${e.toString().replaceFirst("Exception: ", "")}', isError: true);
    }
  }

  // --- Lógica de Navegación (Petición 15) ---
  void _goToCrearElemento() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminElementoFormScreen(),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administrador', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        // --- ¡NUEVO! (Petición C) ---
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112.0), // Altura para barra y filtros
          child: Column(
            children: [
              _buildSearchField(context),
              _buildFilterChips(context),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Crear Elemento'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: _goToCrearElemento,
      ),
      
      // --- ¡NUEVO! Body con Paginación ---
      body: _buildBody(context),
    );
  }
  
  /// --- ¡NUEVO! Widget de Búsqueda (Petición C) ---
  Widget _buildSearchField(BuildContext context) {
    final Color iconColor = Theme.of(context).colorScheme.onSurface.withAlpha(0x80);
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: TextField(
        controller: _searchController,
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o email...',
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
  
  /// --- ¡NUEVO! Widget de Filtros (Petición G) ---
  Widget _buildFilterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text('Todos'),
            selected: _roleFilter == null,
            onSelected: (val) => _onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Moderadores'),
            selected: _roleFilter == 'MODERADOR',
            onSelected: (val) => _onFilterChanged('MODERADOR'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Admins'),
            selected: _roleFilter == 'ADMIN',
            onSelected: (val) => _onFilterChanged('ADMIN'),
          ),
        ],
      ),
    );
  }
  
  /// --- ¡NUEVO! Widget Body con Paginación (Petición B) ---
  Widget _buildBody(BuildContext context) {
    if (_isLoadingFirstPage) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadingError != null) {
      return Center(child: Text('Error: $_loadingError', style: const TextStyle(color: Colors.red)));
    }
    if (_usuarios.isEmpty) {
      return const Center(child: Text('No se encontraron usuarios.'));
    }

    return ListView.builder(
      controller: _scrollController,
      // (Petición A) Padding para el FAB y el Appbar
      padding: const EdgeInsets.only(bottom: 96.0, top: 8.0, left: 8.0, right: 8.0),
      itemCount: _usuarios.length + 1, // +1 para el indicador de carga
      itemBuilder: (context, index) {
        
        // Indicador de Carga
        if (index == _usuarios.length) {
          return _hasNextPage
            ? const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ))
            : const SizedBox(height: 1); // No mostrar nada
        }
        
        // Fila de Usuario
        final user = _usuarios[index];
        final bool hasChanges = _pendingChanges.containsKey(user.id);
        final bool isMod = _pendingChanges[user.id]?['mod'] ?? user.esModerador;
        final bool isAdmin = _pendingChanges[user.id]?['admin'] ?? user.esAdministrador;

        // (Petición E) ExpansionTile
        return Card(
          clipBehavior: Clip.antiAlias, 
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ExpansionTile(
            // (Petición D) Avatar y Nombre
            title: Row(
              children: [
                _buildAvatar(context, user.fotoPerfilUrl),
                const SizedBox(width: 16),
                Text(user.username, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            subtitle: Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            
            // (E) Contenido colapsable
            children: [
              const Divider(height: 1),
              SwitchListTile.adaptive(
                title: const Text('Moderador'),
                value: isMod,
                onChanged: (val) => _onRoleChanged(user.id, 'mod', val),
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
              SwitchListTile.adaptive(
                title: const Text('Administrador'),
                value: isAdmin,
                onChanged: (val) => _onRoleChanged(user.id, 'admin', val),
                activeTrackColor: Colors.purple[700], 
              ),
              
              if (hasChanges)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
                    child: TextButton(
                      child: const Text('Guardar Cambios'),
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
  
  /// Helper para el Avatar (Petición D)
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