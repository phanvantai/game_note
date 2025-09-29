# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Game Note is a Flutter mobile application for football and esports communities that provides:

- **Offline Mode**: Local tournament management with SQLite database
- **Online Mode**: Social features with Firebase integration
- **Dual Focus**: Traditional football and esports (PES) gaming communities

## Development Commands

### Build & Test
```bash
flutter pub get              # Install dependencies
flutter analyze             # Run static analysis (uses flutter_lints)
flutter test                # Run unit tests
flutter build apk           # Build Android APK
flutter build ios           # Build iOS app
```

### Development
```bash
flutter run                  # Run in debug mode
flutter run --release       # Run in release mode
flutter clean               # Clean build artifacts
```

## Architecture

The project follows **Clean Architecture** principles with clear layer separation:

### Core Structure
- **Domain Layer** (`lib/domain/`): Entities, repository interfaces, use cases
- **Data Layer** (`lib/data/`): Repository implementations, Firebase data sources
- **Presentation Layer** (`lib/presentation/`): UI components, BLoC state management
- **Offline Module** (`lib/offline/`): Complete clean architecture for local features

### Key Technologies
- **State Management**: BLoC pattern with `flutter_bloc`, secondary `provider`
- **Dependency Injection**: `get_it` service locator (configured in `lib/injection_container.dart`)
- **Local Database**: SQLite with `sqflite` (managed by `DatabaseManager`)
- **Firebase**: Auth, Firestore, Storage, Messaging, Analytics
- **Navigation**: Centralized in `lib/routing.dart` with custom page transitions

### Offline vs Online Architecture
- **Offline**: Complete clean architecture in `lib/offline/` with local SQLite storage
- **Online**: Firebase-based repositories in `lib/data/repositories/` with real-time sync

## Code Conventions

### File Structure
- **Feature-based organization**: Group files by domain/feature
- **BLoC Pattern**: Each feature has `bloc/`, `events/`, `states/` structure
- **Repository Pattern**: All data access through repository interfaces

### Naming Conventions
- **Classes**: PascalCase (`LeagueDetailBloc`, `PlayerModel`)
- **Files**: snake_case (`league_detail_bloc.dart`, `player_model.dart`)
- **BLoC Events**: `[Feature][Action]Event` (e.g., `LoadLeagueEvent`)
- **BLoC Methods**: `_on[EventName]` (e.g., `_onLoadLeague`)

### Core Patterns
- **Use Case Pattern**: Business logic encapsulated in use cases
- **Failure Handling**: `Either<Failure, Success>` pattern with `dartz`
- **Real-time Data**: Firebase listeners for online features
- **Dependency Injection**: Register all services in `injection_container.dart`

## Database Management

### Local Database (SQLite)
- **Manager**: `DatabaseManager` in `lib/offline/data/database/`
- **Initialization**: Called in `main.dart` before app start
- **Features**: Tournament data, match results, player statistics

### Firebase Integration
- **Collections**: `users`, `esportGroups`, `esportLeagues`, `esportChats`
- **Authentication**: Email/password and Google Sign-In
- **Real-time**: Firestore listeners for live updates
- **Storage**: Image uploads for avatars and tournament media

## Performance Considerations

### Optimization Strategies
- **Batch Loading**: Use batch queries to avoid N+1 problems (see `PERFORMANCE_OPTIMIZATIONS.md`)
- **Parallel Loading**: Load independent data simultaneously with `Future.wait()`
- **Image Caching**: Use `cached_network_image` for remote images
- **Memory Management**: Properly dispose BLoC instances and streams

### Common Performance Patterns
- **User Batch Loading**: `getUsersById()` for loading multiple users efficiently
- **Parallel Data Loading**: `getParticipantsAndMatches()` for simultaneous API calls
- **Real-time Optimization**: Minimize concurrent Firestore listeners

## Key Features

### Tournament System
- **League Creation**: Automatic round-robin generation with configurable formats
- **Match Management**: Score tracking with automatic statistics calculation
- **Player Statistics**: Real-time wins/draws/losses, goal difference calculations
- **Data Persistence**: All tournament data stored locally with SQLite

### Social Features
- **Groups**: Create/join esports groups with member management
- **Online Tournaments**: Real-time tournament updates via Firestore
- **Chat System**: Group-based messaging with Firebase
- **Push Notifications**: Firebase Messaging for tournament updates

### Firebase Configuration
- **Authentication**: Configured in `lib/firebase/auth/gn_auth.dart`
- **Firestore**: Service layer in `lib/firebase/firestore/gn_firestore.dart`
- **Storage**: File uploads in `lib/firebase/storage/gn_storage.dart`
- **Messaging**: Push notifications in `lib/firebase/messaging/gn_firebase_messaging.dart`

## Testing & Quality

### Code Quality
- **Linting**: Uses `flutter_lints` (configured in `analysis_options.yaml`)
- **Error Handling**: Proper exception handling with user-friendly messages
- **Input Validation**: Form validation for tournament creation and user data

### Common Development Tasks
- **Adding Features**: Start with domain layer (entities/use cases), then data layer, finally presentation
- **BLoC Integration**: Register new BLoCs in `injection_container.dart`
- **Database Changes**: Update `DatabaseManager` for schema modifications
- **Firebase Integration**: Add new collections following existing patterns in `lib/firebase/firestore/`

## Monetization & Analytics
- **Google Mobile Ads**: Integrated throughout the app with proper ad loading
- **Firebase Analytics**: User behavior tracking for feature usage
- **Premium Features**: Feature flags for advanced functionality