# FreshFarmily Shared Library

A Flutter package containing shared components, services, and utilities used across all FreshFarmily mobile applications.

## Overview

This shared library provides a consistent foundation for all FreshFarmily applications, ensuring code reuse and maintaining a unified experience across the consumer, farmer, and driver apps.

## Features

- **API Services**: Centralized API communication with the FreshFarmily backend
- **Authentication**: JWT authentication and token management
- **Models**: Data models and entities shared across applications
- **UI Components**: Reusable UI components with consistent styling
- **Utilities**: Common utility functions and extensions
- **State Management**: Core state management patterns
- **Configuration**: Environment configuration and settings
- **Real-time Communication**: WebSocket services for real-time updates

## Getting Started

### Installation

To use this package in another FreshFarmily app:

1. Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  freshfarmily_shared:
    path: ../shared
```

2. Import the package in your Dart code:

```dart
import 'package:freshfarmily_shared/freshfarmily_shared.dart';
```

## Architecture

The shared library is organized into several key modules:

- **api/**: API client and service interfaces
- **models/**: Data models and DTOs
- **services/**: Shared business logic and services
- **utils/**: Helper functions and utilities
- **widgets/**: Reusable UI components
- **config/**: Configuration settings
- **constants/**: Application constants

## Usage Examples

### Authentication

```dart
import 'package:freshfarmily_shared/services/auth_service.dart';

final authService = AuthService();
final loginResult = await authService.login(email, password);
```

### API Services

```dart
import 'package:freshfarmily_shared/services/order_service.dart';

final orderService = OrderService();
final orders = await orderService.getOrders();
```

### UI Components

```dart
import 'package:freshfarmily_shared/widgets/product_card.dart';

ProductCard(
  product: product,
  onTap: () => navigateToProductDetail(product),
)
```

## Related Repositories

- [FreshFarmily Backend](https://github.com/freshfarmily/backend)
- [FreshFarmily Consumer App](https://github.com/freshfarmily/consumer-app)
- [FreshFarmily Driver App](https://github.com/freshfarmily/driver-app)
- [FreshFarmily Farmer App](https://github.com/freshfarmily/farmer-app)
