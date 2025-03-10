class SalesAnalytics {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final double conversionRate;
  final List<double> revenueOverTime;
  final List<ProductSalesData> topProducts;

  SalesAnalytics({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.conversionRate,
    required this.revenueOverTime,
    required this.topProducts,
  });

  factory SalesAnalytics.fromJson(Map<String, dynamic> json) {
    return SalesAnalytics(
      totalRevenue: json['totalRevenue']?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] ?? 0,
      averageOrderValue: json['averageOrderValue']?.toDouble() ?? 0.0,
      conversionRate: json['conversionRate']?.toDouble() ?? 0.0,
      revenueOverTime: List<double>.from(json['revenueOverTime'] ?? []),
      topProducts: (json['topProducts'] as List?)
          ?.map((product) => ProductSalesData.fromJson(product))
          .toList() ?? [],
    );
  }
}

class ProductSalesData {
  final String id;
  final String name;
  final int unitsSold;
  final double revenue;

  ProductSalesData({
    required this.id,
    required this.name,
    required this.unitsSold,
    required this.revenue,
  });

  factory ProductSalesData.fromJson(Map<String, dynamic> json) {
    return ProductSalesData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      unitsSold: json['unitsSold'] ?? 0,
      revenue: json['revenue']?.toDouble() ?? 0.0,
    );
  }
}

class CustomerAnalytics {
  final int totalCustomers;
  final int newCustomers;
  final double returningRate;
  final double averageSatisfaction;
  final List<DemographicData> demographics;
  final List<LocationData> topLocations;

  CustomerAnalytics({
    required this.totalCustomers,
    required this.newCustomers,
    required this.returningRate,
    required this.averageSatisfaction,
    required this.demographics,
    required this.topLocations,
  });

  factory CustomerAnalytics.fromJson(Map<String, dynamic> json) {
    return CustomerAnalytics(
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomers: json['newCustomers'] ?? 0,
      returningRate: json['returningRate']?.toDouble() ?? 0.0,
      averageSatisfaction: json['averageSatisfaction']?.toDouble() ?? 0.0,
      demographics: (json['demographics'] as List?)
          ?.map((demo) => DemographicData.fromJson(demo))
          .toList() ?? [],
      topLocations: (json['topLocations'] as List?)
          ?.map((location) => LocationData.fromJson(location))
          .toList() ?? [],
    );
  }
}

class DemographicData {
  final String group;
  final double percentage;

  DemographicData({
    required this.group,
    required this.percentage,
  });

  factory DemographicData.fromJson(Map<String, dynamic> json) {
    return DemographicData(
      group: json['group'] ?? '',
      percentage: json['percentage']?.toDouble() ?? 0.0,
    );
  }
}

class LocationData {
  final String name;
  final int customers;
  final double percentage;

  LocationData({
    required this.name,
    required this.customers,
    required this.percentage,
  });

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] ?? '',
      customers: json['customers'] ?? 0,
      percentage: json['percentage']?.toDouble() ?? 0.0,
    );
  }
}

class ProductAnalytics {
  final int totalProducts;
  final double averageRating;
  final int stockOuts;
  final int lowStock;
  final List<ProductPerformance> productPerformance;
  final List<InventoryStatus> inventoryStatus;

  ProductAnalytics({
    required this.totalProducts,
    required this.averageRating,
    required this.stockOuts,
    required this.lowStock,
    required this.productPerformance,
    required this.inventoryStatus,
  });

  factory ProductAnalytics.fromJson(Map<String, dynamic> json) {
    return ProductAnalytics(
      totalProducts: json['totalProducts'] ?? 0,
      averageRating: json['averageRating']?.toDouble() ?? 0.0,
      stockOuts: json['stockOuts'] ?? 0,
      lowStock: json['lowStock'] ?? 0,
      productPerformance: (json['productPerformance'] as List?)
          ?.map((product) => ProductPerformance.fromJson(product))
          .toList() ?? [],
      inventoryStatus: (json['inventoryStatus'] as List?)
          ?.map((product) => InventoryStatus.fromJson(product))
          .toList() ?? [],
    );
  }
}

class ProductPerformance {
  final String id;
  final String name;
  final double performance;

  ProductPerformance({
    required this.id,
    required this.name,
    required this.performance,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      performance: json['performance']?.toDouble() ?? 0.0,
    );
  }
}

class InventoryStatus {
  final String id;
  final String name;
  final int stockLevel;

  InventoryStatus({
    required this.id,
    required this.name,
    required this.stockLevel,
  });

  factory InventoryStatus.fromJson(Map<String, dynamic> json) {
    return InventoryStatus(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      stockLevel: json['stockLevel'] ?? 0,
    );
  }
}
