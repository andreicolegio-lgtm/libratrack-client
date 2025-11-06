// lib/src/features/elemento/elemento_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/elemento_service.dart';
import 'package:libratrack_client/src/model/elemento.dart';

/// Pantalla de Ficha de Detalle (RF10, RF11, RF12).
///
/// Muestra toda la información de un Elemento específico.
/// Es un [StatefulWidget] porque necesita "esperar" (cargar)
/// los datos de la API.
class ElementoDetailScreen extends StatefulWidget {
  /// El ID del elemento que debemos cargar.
  /// Este ID se pasa desde la pantalla anterior (ej. SearchScreen).
  final int elementoId;
  
  const ElementoDetailScreen({
    super.key,
    required this.elementoId,
  });

  @override
  State<ElementoDetailScreen> createState() => _ElementoDetailScreenState();
}

class _ElementoDetailScreenState extends State<ElementoDetailScreen> {
  // --- Servicios y Estado ---
  final ElementoService _elementoService = ElementoService();
  
  // Usamos un 'Future' para manejar el estado de la carga en la UI
  // con un 'FutureBuilder'.
  // Esta es la variable que SOLUCIONA el error
  late Future<Elemento> _elementoFuture; 

  @override
  void initState() {
    super.initState();
    // 1. En cuanto la pantalla se crea, llamamos al servicio
    // para que empiece a cargar el elemento usando el ID
    // que recibimos en el constructor ('widget.elementoId').
    _elementoFuture = _elementoService.getElementoById(widget.elementoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Usamos un FutureBuilder. Este widget sabe cómo manejar
      // los 3 estados de un 'Future': 'waiting', 'error' y 'done'.
      body: FutureBuilder<Elemento>(
        future: _elementoFuture,
        builder: (context, snapshot) {
          
          // --- Caso 1: Aún estamos cargando (waiting) ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- Caso 2: Hubo un error (error) ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el elemento:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          
          // --- Caso 3: Éxito (done) ---
          // Si llegamos aquí, 'snapshot.hasData' es true.
          // Guardamos el objeto 'Elemento' en una variable.
          final Elemento elemento = snapshot.data!;
          
          // Usamos 'CustomScrollView' para tener una imagen de cabecera
          // que colapsa (SliverAppBar), como en muchas apps profesionales.
          return CustomScrollView(
            slivers: <Widget>[
              // --- Cabecera con Imagen ---
              SliverAppBar(
                expandedHeight: 300.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    elemento.titulo,
                    style: const TextStyle(shadows: [Shadow(blurRadius: 10)]),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // La imagen (si existe)
                      if (elemento.imagenPortadaUrl != null)
                        Image.network(
                          elemento.imagenPortadaUrl!,
                          fit: BoxFit.cover,
                          // Placeholder mientras carga
                          loadingBuilder: (context, child, progress) {
                            return progress == null
                                ? child
                                : const Center(child: CircularProgressIndicator());
                          },
                          // Placeholder si falla
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[800]);
                          },
                        )
                      else
                        Container(color: Colors.grey[800]), // Color si no hay imagen
                      
                      // Gradiente oscuro para que el título sea legible
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                      
                      // --- Chip "OFICIAL" (RF11) ---
                      Positioned(
                        top: 40,
                        right: 16,
                        child: _buildEstadoChip(elemento.estadoContenido),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- Cuerpo de la Página (Detalles) ---
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Tipo y Géneros ---
                          Text(
                            // ej. "Serie | Fantasía, Misterio"
                            '${elemento.tipo} | ${elemento.generos.join(", ")}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[400],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          
                          const SizedBox(height: 24),

                          // --- Botón de Añadir (RF05) ---
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Añadir a Mi Catálogo'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            onPressed: () {
                              // TO DO: Implementar lógica de RF05
                            },
                          ),
                          
                          const SizedBox(height: 24),

                          // --- Sinopsis (RF10) ---
                          Text(
                            'Sinopsis',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            elemento.descripcion,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // --- Reseñas (RF12) ---
                          Text(
                            'Reseñas',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          // TO DO: Implementar lista de reseñas (RF12)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Las reseñas irán aquí.'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  /// (RF11) Widget auxiliar para mostrar 
  /// el chip "OFICIAL" o "COMUNITARIO"
  Widget _buildEstadoChip(String estado) {
    // Asumimos que el estado es "OFICIAL" o "COMUNITARIO"
    // (basado en el Enum 'EstadoContenido' de la API)
    final bool isOficial = estado == "OFICIAL"; 
    
    return Chip(
      label: Text(
        isOficial ? "OFICIAL" : "COMUNITARIO",
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isOficial ? Colors.blue[600] : Colors.grey[700],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    );
  }
}