import 'package:cloud_firestore/cloud_firestore.dart';
import '../../firestore_instance.dart';
import '../model/financial_stats_model.dart';

class FinancialStatsController {
  final FirebaseFirestore _firestore = firestore;

  // Get all professionals for filter dropdown
  Future<List<Map<String, String>>> getAllProfessionals() async {
    try {
      final snapshot = await _firestore
          .collection('profissionais')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return <String, String>{
          'id': doc.id,
          'name': data['name'] ?? 'Desconhecido',
        };
      }).toList();
    } catch (e) {
      print('Error getting professionals: $e');
      return [];
    }
  }

  // Get all barbershops for filter dropdown
  Future<List<Map<String, String>>> getAllBarbershops() async {
    try {
      final snapshot = await _firestore
          .collection('barbearias')
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final name = data['name'] ?? 'Desconhecida';
        return <String, String>{
          'id': name, // Use name as ID since bookings store name, not ID
          'name': name,
        };
      }).toList();
    } catch (e) {
      print('Error getting barbershops: $e');
      return [];
    }
  }

  // Fetch bookings with filters
  Future<List<BookingData>> fetchFilteredBookings(FilterModel filter) async {
    try {
      // Get date range
      final dateRange = filter.getDateRange();
      final startDate = dateRange['start']!;
      final endDate = dateRange['end']!;

      // Determine status based on view mode
      final status = filter.viewMode == ViewMode.real ? 'completed' : 'confirmed';

      // Build base query - only filter by status to avoid Firestore composite index issues
      Query query = _firestore.collection('agendamentos');
      query = query.where('status', isEqualTo: status);

      // Execute query
      final snapshot = await query.get();

      // Parse bookings and apply ALL filters in memory
      final bookings = <BookingData>[];
      
      for (var doc in snapshot.docs) {
        final booking = BookingData.fromFirestore(doc);
        
        // Apply professional filter in memory
        if (filter.professionalId != null && 
            filter.professionalId!.isNotEmpty && 
            booking.professionalId != filter.professionalId) {
          continue;
        }

        // Apply barbershop filter in memory
        if (filter.barbershopId != null && 
            filter.barbershopId!.isNotEmpty && 
            booking.barbershopId != filter.barbershopId) {
          continue;
        }
        
        // Get effective date for filtering
        final effectiveDate = booking.getEffectiveDate();
        
        // Apply date filter in memory (inclusive on both ends)
        if ((effectiveDate.isAfter(startDate) || effectiveDate.isAtSameMomentAs(startDate)) &&
            (effectiveDate.isBefore(endDate) || effectiveDate.isAtSameMomentAs(endDate))) {
          bookings.add(booking);
        }
      }

      // Fetch professional names for bookings
      await _enrichBookingsWithProfessionalNames(bookings);

      return bookings;
    } catch (e) {
      print('Error fetching filtered bookings: $e');
      return [];
    }
  }

  // Enrich bookings with professional names
  Future<void> _enrichBookingsWithProfessionalNames(List<BookingData> bookings) async {
    final professionalIds = bookings
        .map((b) => b.professionalId)
        .where((id) => id.isNotEmpty)
        .toSet();

    final professionalNames = <String, String>{};

    for (var id in professionalIds) {
      try {
        final doc = await _firestore.collection('profissionais').doc(id).get();
        if (doc.exists) {
          professionalNames[id] = doc.data()?['name'] ?? id;
        }
      } catch (e) {
        // Keep original ID if fetch fails
      }
    }

    // Update booking professional names
    for (var i = 0; i < bookings.length; i++) {
      if (professionalNames.containsKey(bookings[i].professionalId)) {
        bookings[i] = BookingData(
          id: bookings[i].id,
          serviceName: bookings[i].serviceName,
          professionalId: bookings[i].professionalId,
          professionalName: professionalNames[bookings[i].professionalId]!,
          barbershopId: bookings[i].barbershopId,
          barbershopName: bookings[i].barbershopName,
          price: bookings[i].price,
          dateTime: bookings[i].dateTime,
          concludedAt: bookings[i].concludedAt,
          status: bookings[i].status,
        );
      }
    }
  }

  // Get financial statistics based on filter
  Future<FinancialStatsModel> getFinancialStats(FilterModel filter) async {
    try {
      final bookings = await fetchFilteredBookings(filter);
      return FinancialStatsModel.fromBookings(bookings);
    } catch (e) {
      print('Error getting financial stats: $e');
      return FinancialStatsModel.empty();
    }
  }

  // Get revenue by day chart data
  Future<RevenueByDayData> getRevenueByDayData(FilterModel filter) async {
    try {
      final bookings = await fetchFilteredBookings(filter);
      return RevenueByDayData.fromBookings(bookings);
    } catch (e) {
      print('Error getting revenue by day data: $e');
      return RevenueByDayData([]);
    }
  }

  // Get revenue by professional chart data
  Future<RevenueByProfessionalData> getRevenueByProfessionalData(FilterModel filter) async {
    try {
      final bookings = await fetchFilteredBookings(filter);
      return RevenueByProfessionalData.fromBookings(bookings);
    } catch (e) {
      print('Error getting revenue by professional data: $e');
      return RevenueByProfessionalData([]);
    }
  }

  // Get top services chart data
  Future<TopServicesData> getTopServicesData(FilterModel filter) async {
    try {
      final bookings = await fetchFilteredBookings(filter);
      return TopServicesData.fromBookings(bookings);
    } catch (e) {
      print('Error getting top services data: $e');
      return TopServicesData([]);
    }
  }

  // Export to CSV
  String exportToCSV(List<BookingData> bookings, FilterModel filter) {
    final buffer = StringBuffer();
    
    // Header with metadata
    buffer.writeln('RELATÓRIO DE ESTATÍSTICAS FINANCEIRAS');
    buffer.writeln('Gerado em: ${_formatDateTime(DateTime.now())}');
    buffer.writeln('Modo: ${filter.viewMode == ViewMode.real ? "Valores Reais (Concluídos)" : "Valores Estimados (Confirmados)"}');
    buffer.writeln('Período: ${filter.getPeriodLabel()}');
    if (filter.customStartDate != null && filter.customEndDate != null) {
      buffer.writeln('De: ${_formatDate(filter.customStartDate!)} até ${_formatDate(filter.customEndDate!)}');
    }
    buffer.writeln('Total de Registros: ${bookings.length}');
    buffer.writeln('');
    
    // Summary statistics
    final totalRevenue = bookings.fold<double>(0.0, (sum, b) => sum + b.price);
    final avgTicket = bookings.isNotEmpty ? totalRevenue / bookings.length : 0.0;
    buffer.writeln('RESUMO');
    buffer.writeln('Total Faturado: €${totalRevenue.toStringAsFixed(2)}');
    buffer.writeln('Serviços Realizados: ${bookings.length}');
    buffer.writeln('Ticket Médio: €${avgTicket.toStringAsFixed(2)}');
    buffer.writeln('');
    
    // Data table header
    buffer.writeln('Data,Dia da Semana,Hora,Serviço,Profissional,Barbearia,Preço (€),Status');
    
    // Data rows
    for (var booking in bookings) {
      final date = booking.getEffectiveDate();
      final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      final dayOfWeek = _getDayOfWeek(date.weekday);
      final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final statusText = booking.status == 'completed' ? 'Concluído' : 'Confirmado';
      
      buffer.writeln(
        '"$dateStr","$dayOfWeek","$timeStr","${booking.serviceName}","${booking.professionalName}","${booking.barbershopName}","${booking.price.toStringAsFixed(2)}","$statusText"'
      );
    }
    
    return buffer.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getDayOfWeek(int weekday) {
    const days = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }
}
