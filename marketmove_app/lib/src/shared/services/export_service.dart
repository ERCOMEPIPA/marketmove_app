import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'clientes_service.dart';
import 'deals_service.dart';
import '../models/venta_model.dart';
import '../models/gasto_model.dart';

/// Servicio para exportar datos a CSV
/// Soporta tanto web como móvil (Android/iOS)
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final DateFormat _dateOnlyFormat = DateFormat('dd/MM/yyyy');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '€',
    decimalDigits: 2,
  );

  /// Exportar lista de clientes a CSV
  Future<void> exportarClientesCSV(List<ClienteModel> clientes) async {
    if (clientes.isEmpty) {
      _mostrarMensaje('No hay clientes para exportar');
      return;
    }

    // Cabeceras
    final headers = [
      'Nombre',
      'Email',
      'Teléfono',
      'Empresa',
      'Cargo',
      'Estado',
      'Fuente',
      'Valor Estimado',
      'Notas',
      'Fecha Creación',
      'Última Actualización',
    ];

    // Filas de datos
    final rows = clientes.map((cliente) {
      return [
        _escaparCSV(cliente.nombre),
        _escaparCSV(cliente.email ?? ''),
        _escaparCSV(cliente.telefono ?? ''),
        _escaparCSV(cliente.empresa ?? ''),
        _escaparCSV(cliente.cargo ?? ''),
        _escaparCSV(EstadoCliente.nombre(cliente.estado)),
        _escaparCSV(cliente.fuente ?? ''),
        cliente.valorEstimado.toStringAsFixed(2),
        _escaparCSV(cliente.notas ?? ''),
        _dateFormat.format(cliente.createdAt),
        _dateFormat.format(cliente.updatedAt),
      ];
    }).toList();

    // Generar contenido CSV
    final csvContent = _generarCSV(headers, rows);

    // Nombre del archivo con fecha
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nombreArchivo = 'clientes_$fecha.csv';

    // Descargar/Compartir
    await _exportarArchivo(csvContent, nombreArchivo);
  }

  /// Exportar lista de deals/pipeline a CSV
  Future<void> exportarDealsCSV(List<DealModel> deals) async {
    if (deals.isEmpty) {
      _mostrarMensaje('No hay deals para exportar');
      return;
    }

    // Cabeceras
    final headers = [
      'Título',
      'Cliente',
      'Valor',
      'Etapa',
      'Probabilidad (%)',
      'Valor Ponderado',
      'Descripción',
      'Fecha Cierre Estimada',
      'Fecha Cierre Real',
      'Motivo Pérdida',
      'Notas',
      'Fecha Creación',
    ];

    // Filas de datos
    final rows = deals.map((deal) {
      return [
        _escaparCSV(deal.titulo),
        _escaparCSV(deal.clienteNombre ?? 'Sin cliente'),
        deal.valor.toStringAsFixed(2),
        _escaparCSV(EtapasPipeline.nombre(deal.etapa)),
        deal.probabilidad.toString(),
        deal.valorPonderado.toStringAsFixed(2),
        _escaparCSV(deal.descripcion ?? ''),
        deal.fechaCierreEstimada != null
            ? _dateFormat.format(deal.fechaCierreEstimada!)
            : '',
        deal.fechaCierreReal != null
            ? _dateFormat.format(deal.fechaCierreReal!)
            : '',
        _escaparCSV(deal.motivoPerdida ?? ''),
        _escaparCSV(deal.notas ?? ''),
        _dateFormat.format(deal.createdAt),
      ];
    }).toList();

    // Generar contenido CSV
    final csvContent = _generarCSV(headers, rows);

    // Nombre del archivo con fecha
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nombreArchivo = 'pipeline_$fecha.csv';

    // Descargar/Compartir
    await _exportarArchivo(csvContent, nombreArchivo);
  }

  /// Exportar historial de ventas a CSV
  Future<void> exportarVentasCSV(List<VentaModel> ventas) async {
    if (ventas.isEmpty) {
      _mostrarMensaje('No hay ventas para exportar');
      return;
    }

    // Cabeceras
    final headers = ['Fecha', 'Monto', 'Método de Pago', 'Productos', 'Notas'];

    // Filas de datos
    final rows = ventas.map((venta) {
      // Generar descripción de productos
      String productos = '';
      if (venta.detalles != null && venta.detalles!.isNotEmpty) {
        productos = venta.detalles!
            .map((d) => '${d.productoNombre ?? "Producto"} x${d.cantidad}')
            .join('; ');
      }

      return [
        _dateFormat.format(venta.fecha),
        venta.monto.toStringAsFixed(2),
        _escaparCSV(venta.metodoPago?.displayName ?? 'No especificado'),
        _escaparCSV(productos),
        _escaparCSV(venta.notas ?? ''),
      ];
    }).toList();

    // Generar contenido CSV
    final csvContent = _generarCSV(headers, rows);

    // Nombre del archivo con fecha
    final fecha = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final nombreArchivo = 'ventas_$fecha.csv';

    // Descargar/Compartir
    await _exportarArchivo(csvContent, nombreArchivo);
  }

  /// Exportar reporte mensual completo a CSV
  /// Incluye resumen y detalle de ventas y gastos
  Future<void> exportarReporteMensualCSV({
    required String periodo,
    required double totalVentas,
    required double totalGastos,
    required List<VentaModel> ventas,
    required List<GastoModel> gastos,
  }) async {
    final buffer = StringBuffer();
    final balance = totalVentas - totalGastos;

    // BOM para UTF-8
    buffer.write('\uFEFF');

    // === SECCIÓN DE RESUMEN ===
    buffer.writeln('REPORTE MENSUAL - $periodo');
    buffer.writeln('');
    buffer.writeln('RESUMEN');
    buffer.writeln('Total Ventas,${_currencyFormat.format(totalVentas)}');
    buffer.writeln('Total Gastos,${_currencyFormat.format(totalGastos)}');
    buffer.writeln('Balance,${_currencyFormat.format(balance)}');
    buffer.writeln('Número de Ventas,${ventas.length}');
    buffer.writeln('Número de Gastos,${gastos.length}');
    buffer.writeln('');

    // === SECCIÓN DE VENTAS ===
    buffer.writeln('DETALLE DE VENTAS');
    buffer.writeln('Fecha,Monto,Método de Pago,Productos,Notas');

    for (var venta in ventas) {
      String productos = '';
      if (venta.detalles != null && venta.detalles!.isNotEmpty) {
        productos = venta.detalles!
            .map((d) => '${d.productoNombre ?? "Producto"} x${d.cantidad}')
            .join('; ');
      }

      buffer.writeln(
        [
          _dateOnlyFormat.format(venta.fecha),
          venta.monto.toStringAsFixed(2),
          _escaparCSV(venta.metodoPago?.displayName ?? 'N/A'),
          _escaparCSV(productos),
          _escaparCSV(venta.notas ?? ''),
        ].join(','),
      );
    }

    buffer.writeln('');

    // === SECCIÓN DE GASTOS ===
    buffer.writeln('DETALLE DE GASTOS');
    buffer.writeln('Fecha,Concepto,Monto,Categoría,Método de Pago,Notas');

    for (var gasto in gastos) {
      buffer.writeln(
        [
          _dateOnlyFormat.format(gasto.fecha),
          _escaparCSV(gasto.concepto),
          gasto.monto.toStringAsFixed(2),
          _escaparCSV(gasto.categoriaNombre ?? 'Sin categoría'),
          _escaparCSV(gasto.metodoPago?.displayName ?? 'N/A'),
          _escaparCSV(gasto.notas ?? ''),
        ].join(','),
      );
    }

    // Nombre del archivo
    final fecha = DateFormat('yyyy-MM').format(DateTime.now());
    final nombreArchivo = 'reporte_mensual_$fecha.csv';

    // Descargar/Compartir
    await _exportarArchivo(buffer.toString(), nombreArchivo);
  }

  /// Generar contenido CSV con BOM para compatibilidad con Excel
  String _generarCSV(List<String> headers, List<List<String>> rows) {
    final buffer = StringBuffer();

    // BOM para UTF-8 (para que Excel reconozca caracteres especiales)
    buffer.write('\uFEFF');

    // Cabeceras
    buffer.writeln(headers.join(','));

    // Filas
    for (var row in rows) {
      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Escapar valores para CSV (manejar comas, comillas, saltos de línea)
  String _escaparCSV(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      // Escapar comillas dobles duplicándolas
      final escaped = valor.replaceAll('"', '""');
      return '"$escaped"';
    }
    return valor;
  }

  /// Exportar archivo - usa método apropiado según la plataforma
  Future<void> _exportarArchivo(String contenido, String nombreArchivo) async {
    try {
      if (kIsWeb) {
        // Para web, usamos importación condicional
        await _exportarArchivoWeb(contenido, nombreArchivo);
      } else {
        // Para móvil (Android/iOS), guardamos y compartimos
        await _exportarArchivoMovil(contenido, nombreArchivo);
      }
    } catch (e) {
      _mostrarMensaje('Error al exportar: $e');
    }
  }

  /// Exportar archivo en plataformas móviles (Android/iOS)
  Future<void> _exportarArchivoMovil(
    String contenido,
    String nombreArchivo,
  ) async {
    try {
      // Obtener directorio temporal
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$nombreArchivo';

      // Escribir archivo
      final file = File(filePath);
      await file.writeAsString(contenido, encoding: utf8);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Exportación: $nombreArchivo',
        text: 'Archivo CSV exportado desde MarketMove',
      );

      _mostrarMensaje('Archivo "$nombreArchivo" listo para compartir');
    } catch (e) {
      _mostrarMensaje('Error al exportar en móvil: $e');
    }
  }

  /// Exportar archivo en web
  /// Este método solo se ejecuta en web
  Future<void> _exportarArchivoWeb(
    String contenido,
    String nombreArchivo,
  ) async {
    // En web, necesitamos usar una importación condicional
    // Por ahora, mostramos un mensaje ya que la funcionalidad web
    // requiere imports específicos que no están disponibles en móvil
    _mostrarMensaje(
      'La exportación web no está disponible en esta versión móvil',
    );
  }

  /// Mostrar mensaje al usuario (solo imprime por ahora)
  void _mostrarMensaje(String mensaje) {
    // ignore: avoid_print
    print('ExportService: $mensaje');
  }
}
