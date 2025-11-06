// lib/src/features/catalog/widgets/edit_entrada_modal.dart
import 'package:flutter/material.dart';
import 'package:libratrack_client/src/core/services/catalog_service.dart';
import 'package:libratrack_client/src/model/catalogo_entrada.dart';
import 'package:libratrack_client/src/model/estado_personal.dart'; // Importa nuestro nuevo Enum

/// Un 'Modal Bottom Sheet' para editar una entrada del catálogo (RF06, RF07).
class EditEntradaModal extends StatefulWidget {
  /// La entrada del catálogo que estamos editando.
  final CatalogoEntrada entrada;

  const EditEntradaModal({super.key, required this.entrada});

  @override
  State<EditEntradaModal> createState() => _EditEntradaModalState();
}

class _EditEntradaModalState extends State<EditEntradaModal> {
  // --- Servicios y Estado ---
  final CatalogService _catalogService = CatalogService();
  bool _isLoading = false;

  // --- Formulario ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _progresoController;
  late EstadoPersonal _selectedEstado;

  @override
  void initState() {
    super.initState();
    // 1. Inicializa el formulario con los datos actuales de la entrada
    _progresoController = TextEditingController(
      text: widget.entrada.progresoEspecifico ?? '',
    );
    _selectedEstado = EstadoPersonal.fromString(widget.entrada.estadoPersonal);
  }

  @override
  void dispose() {
    _progresoController.dispose();
    super.dispose();
  }

  /// Lógica para guardar los cambios (RF06, RF07)
  Future<void> _handleGuardarCambios() async {
    // 1. Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final msgContext = ScaffoldMessenger.of(context);
    final navContext = Navigator.of(context);

    try {
      // 2. Llamar al servicio de actualización
      // Pasa el ID del elemento y los nuevos valores del formulario
      final CatalogoEntrada entradaActualizada =
          await _catalogService.updateElementoDelCatalogo(
        widget.entrada.elementoId,
        estado: _selectedEstado.apiValue, // ej. "EN_PROGRESO"
        progreso: _progresoController.text,
      );

      // 3. (ÉXITO) Devolver la entrada actualizada
      if (!mounted) return;
      msgContext.showSnackBar(
        const SnackBar(
          content: Text('¡Progreso guardado!'),
          backgroundColor: Colors.green,
        ),
      );
      // Cierra el modal y devuelve la entrada actualizada a 'catalog_screen'
      navContext.pop(entradaActualizada);
    } catch (e) {
      // 4. (ERROR)
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      msgContext.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Padding para que el teclado no tape el modal
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        // Usamos Form para la validación
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min, // Para que el modal sea compacto
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Título ---
              Text(
                widget.entrada.elementoTitulo,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),

              // --- Dropdown de Estado (RF06) ---
              DropdownButtonFormField<EstadoPersonal>(
                initialValue: _selectedEstado,
                items: EstadoPersonal.values.map((estado) {
                  return DropdownMenuItem(
                    value: estado,
                    child: Text(estado.displayName), // "En Progreso"
                  );
                }).toList(),
                onChanged: (EstadoPersonal? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedEstado = newValue;
                    });
                  }
                },
                decoration: _buildInputDecoration(labelText: 'Estado'),
              ),
              const SizedBox(height: 16.0),

              // --- Campo de Progreso (RF07) ---
              TextFormField(
                controller: _progresoController,
                decoration: _buildInputDecoration(
                  labelText: 'Progreso Específico',
                  hintText: 'Ej. T2:E5 o Cap. 10',
                ),
                validator: (value) {
                  if (value != null && value.length > 100) {
                    return 'Máximo 100 caracteres'; // Valida el DTO
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),

              // --- Botón de Guardar ---
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                onPressed: _isLoading ? null : _handleGuardarCambios,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Guardar Progreso',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper para un estilo de decoración consistente
  InputDecoration _buildInputDecoration({required String labelText, String? hintText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[600]),
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide.none,
      ),
    );
  }
}