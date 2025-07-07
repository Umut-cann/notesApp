# Clean Architecture Structure with GetX


bildirim geldiğinde ilgili görevin task detay sayfasını aç 
görevi silme de ekle




## Overview
This application follows Clean Architecture principles with three main layers:

1. **Presentation Layer**: UI components and GetX controllers
2. **Domain Layer**: Business logic and use cases
3. **Data Layer**: Data sources and repositories implementation

## Directory Structure

```
lib/
├── core/                  # Core functionality used across the app
│   ├── constants/         # App constants
│   ├── errors/            # Error handling
│   └── utils/             # Utility functions
│
├── data/                  # Data Layer
│   ├── datasources/       # Data sources (local with Hive)
│   │   └── local/         # Local data source implementations
│   ├── models/            # Data models (Task model, etc.)
│   └── repositories/      # Repository implementations
│
├── domain/                # Domain Layer
│   ├── entities/          # Business entities
│   ├── repositories/      # Repository interfaces
│   └── usecases/          # Use cases (business logic)
│
├── presentation/          # Presentation Layer
│   ├── bindings/          # GetX dependency injection
│   ├── controllers/       # GetX controllers
│   ├── pages/             # Screen implementations
│   └── widgets/           # Reusable UI components
│
└── routes/                # App routing with GetX
```

## Implementation Steps
1. Move from Provider to GetX for state management
2. Separate data, domain, and presentation concerns
3. Implement dependency injection with GetX
4. Create use cases for all app features
5. Ensure each layer depends only on the layer below it
