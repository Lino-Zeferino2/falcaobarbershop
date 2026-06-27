// ignore_for_file: avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';

// Enum for view mode
enum ViewMode {
  real, // Valores Reais (completed)
  estimated, // Valores Estimados (confirmed)
}

// Enum for period filter
enum PeriodFilter {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  always,
  custom,
}

// Filter configuration model
class FilterModel {
  final ViewMode viewMode;
  final PeriodFilter periodFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final String? professionalId;
  final String? barbershopId;

  FilterModel({
    this.viewMode = ViewMode.real,
    this.periodFilter = PeriodFilter.thisMonth,
    this.customStartDate,
    this.customEndDate,
    this.professionalId,
    this.barbershopId,
  });

  FilterModel copyWith({
    ViewMode? viewMode,
    PeriodFilter? periodFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? professionalId,
    String? barbershopId,
    bool clearCustomDates = false,
    bool clearProfessional = false,
    bool clearBarbershop = false,
  }) {
    return FilterModel(
      viewMode: viewMode ?? this.viewMode,
      periodFilter: periodFilter ?? this.periodFilter,
      customStartDate: clearCustomDates ? null : (customStartDate ?? this.customStartDate),
      customEndDate: clearCustomDates ? null : (customEndDate ?? this.customEndDate),
      professionalId: clearProfessional ? null : (professionalId ?? this.professionalId),
      barbershopId: clearBarbershop ? null : (barbershopId ?? this.barbershopId),
    );
  }

  // Get date range based on period filter
  Map<String, DateTime> getDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (periodFilter) {
      case PeriodFilter.today:
        return {
          'start': today,
          'end': today.add(const Duration(days: 1)),
        };
      case PeriodFilter.thisWeek:
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return {
          'start': weekStart,
          'end': weekStart.add(const Duration(days: 7)),
        };
      case PeriodFilter.thisMonth:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        return {'start': monthStart, 'end': monthEnd};
      case PeriodFilter.thisYear:
        final yearStart = DateTime(now.year, 1, 1);
        final yearEnd = DateTime(now.year + 1, 1, 1);
        return {'start': yearStart, 'end': yearEnd};
      case PeriodFilter.always:
        return {
          'start': DateTime(2020, 1, 1),
          'end': DateTime(2100, 12, 31),
        };
      case PeriodFilter.custom:
        if (customStartDate != null && customEndDate != null) {
          return {
            'start': customStartDate!,
            'end': customEndDate!.add(const Duration(days: 1)),
          };
        }
        return {'start': today, 'end': today.add(const Duration(days: 1))};
    }
  }

  String getPeriodLabel() {
    switch (periodFilter) {
      case PeriodFilter.today:
        return 'Hoje';
      case PeriodFilter.thisWeek:
        return 'Esta Semana';
      case PeriodFilter.thisMonth:
        return 'Este Mês';
      case PeriodFilter.thisYear:
        return 'Este Ano';
      case PeriodFilter.always:
        return 'Sempre';
      case PeriodFilter.custom:
        return 'Personalizado';
    }
  }
}

// Booking data model for statistics
class BookingData {
  final String id;
  final String serviceName;
  final String professionalId;
  final String professionalName;
  final String barbershopId;
  final String barbershopName;
  final double price;
  final DateTime dateTime;
  final DateTime? concludedAt;
  final String status;

  BookingData({
    required this.id,
    required this.serviceName,
    required this.professionalId,
    required this.professionalName,
    required this.barbershopId,
    required this.barbershopName,
    required this.price,
    required this.dateTime,
    this.concludedAt,
    required this.status,
  });

  factory BookingData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse date and time
    DateTime parsedDate;
    final dateStr = data['date'] ?? '';
    final timeStr = data['time'] ?? '00:00';
    
    try {
      final combinedDateTime = '${dateStr}T${timeStr}:00';
      parsedDate = DateTime.parse(combinedDateTime);
    } catch (e) {
      try {
        parsedDate = DateTime.parse(dateStr);
      } catch (e2) {
        parsedDate = DateTime.now();
      }
    }

    // Parse concludedAt
    DateTime? concludedAt;
    if (data['concludedAt'] != null) {
      if (data['concludedAt'] is Timestamp) {
        concludedAt = (data['concludedAt'] as Timestamp).toDate();
      } else if (data['concludedAt'] is String) {
        try {
          concludedAt = DateTime.parse(data['concludedAt']);
        } catch (e) {
          // Keep as null
        }
      }
    }

    // Get barbershop ID and name
    // Priority: barbershopId field, then barbearia field (name), then default
    String barbershopId = data['barbershopId'] ?? '';
    String barbershopName = data['barbearia'] ?? 'Desconhecida';
    
    // If no barbershopId but has barbearia name, use name as ID for filtering
    if (barbershopId.isEmpty && barbershopName != 'Desconhecida') {
      barbershopId = barbershopName;
    }

    return BookingData(
      id: doc.id,
      serviceName: data['service'] ?? 'Serviço Desconhecido',
      professionalId: data['professional'] ?? '',
      professionalName: data['professionalName'] ?? data['professional'] ?? 'Desconhecido',
      barbershopId: barbershopId,
      barbershopName: barbershopName,
      price: (data['price'] ?? 0.0).toDouble(),
      dateTime: parsedDate,
      concludedAt: concludedAt,
      status: data['status'] ?? 'pending',
    );
  }

  // Get effective date for statistics (concludedAt or dateTime)
  DateTime getEffectiveDate() {
    return concludedAt ?? dateTime;
  }
}

// Financial statistics model
class FinancialStatsModel {
  final double totalRevenue;
  final int totalServices;
  final double averageTicket;
  final String mostProfitableProfessional;
  final double mostProfitableProfessionalRevenue;
  final String mostProfitableDay;
  final double mostProfitableDayRevenue;
  final List<BookingData> bookings;

  FinancialStatsModel({
    required this.totalRevenue,
    required this.totalServices,
    required this.averageTicket,
    required this.mostProfitableProfessional,
    required this.mostProfitableProfessionalRevenue,
    required this.mostProfitableDay,
    required this.mostProfitableDayRevenue,
    required this.bookings,
  });

  factory FinancialStatsModel.empty() {
    return FinancialStatsModel(
      totalRevenue: 0.0,
      totalServices: 0,
      averageTicket: 0.0,
      mostProfitableProfessional: 'N/A',
      mostProfitableProfessionalRevenue: 0.0,
      mostProfitableDay: 'N/A',
      mostProfitableDayRevenue: 0.0,
      bookings: [],
    );
  }

  factory FinancialStatsModel.fromBookings(List<BookingData> bookings) {
    if (bookings.isEmpty) {
      return FinancialStatsModel.empty();
    }

    // Calculate total revenue
    final totalRevenue = bookings.fold<double>(
      0.0,
      (sum, booking) => sum + booking.price,
    );

    // Calculate total services
    final totalServices = bookings.length;

    // Calculate average ticket
    final averageTicket = totalServices > 0 ? totalRevenue / totalServices : 0.0;

    // Find most profitable professional
    final professionalRevenue = <String, double>{};
    final professionalNames = <String, String>{};
    
    for (var booking in bookings) {
      professionalRevenue[booking.professionalId] = 
          (professionalRevenue[booking.professionalId] ?? 0.0) + booking.price;
      professionalNames[booking.professionalId] = booking.professionalName;
    }

    String mostProfitableProfessional = 'N/A';
    double mostProfitableProfessionalRevenue = 0.0;
    
    if (professionalRevenue.isNotEmpty) {
      final topProfessional = professionalRevenue.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostProfitableProfessional = professionalNames[topProfessional.key] ?? 'Desconhecido';
      mostProfitableProfessionalRevenue = topProfessional.value;
    }

    // Find most profitable day
    final dayRevenue = <String, double>{};
    
    for (var booking in bookings) {
      final date = booking.getEffectiveDate();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dayRevenue[dateKey] = (dayRevenue[dateKey] ?? 0.0) + booking.price;
    }

    String mostProfitableDay = 'N/A';
    double mostProfitableDayRevenue = 0.0;
    
    if (dayRevenue.isNotEmpty) {
      final topDay = dayRevenue.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      mostProfitableDay = topDay.key;
      mostProfitableDayRevenue = topDay.value;
    }

    return FinancialStatsModel(
      totalRevenue: totalRevenue,
      totalServices: totalServices,
      averageTicket: averageTicket,
      mostProfitableProfessional: mostProfitableProfessional,
      mostProfitableProfessionalRevenue: mostProfitableProfessionalRevenue,
      mostProfitableDay: mostProfitableDay,
      mostProfitableDayRevenue: mostProfitableDayRevenue,
      bookings: bookings,
    );
  }
}

// Chart data models
class ChartDataPoint {
  final String label;
  final double value;
  final DateTime? date;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.date,
  });
}

class RevenueByDayData {
  final List<ChartDataPoint> dataPoints;

  RevenueByDayData(this.dataPoints);

  factory RevenueByDayData.fromBookings(List<BookingData> bookings) {
    final dayRevenue = <String, double>{};
    final dayDates = <String, DateTime>{};

    for (var booking in bookings) {
      final date = booking.getEffectiveDate();
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dayRevenue[dateKey] = (dayRevenue[dateKey] ?? 0.0) + booking.price;
      dayDates[dateKey] = date;
    }

    final dataPoints = dayRevenue.entries.map((entry) {
      return ChartDataPoint(
        label: entry.key,
        value: entry.value,
        date: dayDates[entry.key],
      );
    }).toList();

    // Sort by date
    dataPoints.sort((a, b) => a.date!.compareTo(b.date!));

    return RevenueByDayData(dataPoints);
  }
}

class RevenueByProfessionalData {
  final List<ChartDataPoint> dataPoints;

  RevenueByProfessionalData(this.dataPoints);

  factory RevenueByProfessionalData.fromBookings(List<BookingData> bookings) {
    final professionalRevenue = <String, double>{};
    final professionalNames = <String, String>{};

    for (var booking in bookings) {
      professionalRevenue[booking.professionalId] = 
          (professionalRevenue[booking.professionalId] ?? 0.0) + booking.price;
      professionalNames[booking.professionalId] = booking.professionalName;
    }

    final dataPoints = professionalRevenue.entries.map((entry) {
      return ChartDataPoint(
        label: professionalNames[entry.key] ?? 'Desconhecido',
        value: entry.value,
      );
    }).toList();

    // Sort by value descending
    dataPoints.sort((a, b) => b.value.compareTo(a.value));

    return RevenueByProfessionalData(dataPoints);
  }
}

class TopServicesData {
  final List<ChartDataPoint> dataPoints;

  TopServicesData(this.dataPoints);

  factory TopServicesData.fromBookings(List<BookingData> bookings) {
    final serviceCount = <String, int>{};
    final serviceRevenue = <String, double>{};

    for (var booking in bookings) {
      serviceCount[booking.serviceName] = 
          (serviceCount[booking.serviceName] ?? 0) + 1;
      serviceRevenue[booking.serviceName] = 
          (serviceRevenue[booking.serviceName] ?? 0.0) + booking.price;
    }

    final dataPoints = serviceRevenue.entries.map((entry) {
      return ChartDataPoint(
        label: '${entry.key} (${serviceCount[entry.key]}x)',
        value: entry.value,
      );
    }).toList();

    // Sort by value descending
    dataPoints.sort((a, b) => b.value.compareTo(a.value));

    // Take top 10
    return TopServicesData(dataPoints.take(10).toList());
  }
}
