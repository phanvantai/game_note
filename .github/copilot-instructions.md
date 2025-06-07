# Game Note Flutter App - Copilot Instructions

## Project Overview
Game Note is a Flutter mobile application for football and esports communities that provides:
- **Offline Mode**: Local tournament management with match tracking, player statistics, and league tables
- **Online Mode**: Social features with Firebase integration for user groups, tournaments, and chat
- **Dual Focus**: Both traditional football and esports (PES) gaming communities

## Architecture & Patterns

### Clean Architecture
The project follows **Clean Architecture** principles with clear separation:
- **Domain Layer** (`lib/domain/`): Entities, repositories interfaces, use cases
- **Data Layer** (`lib/data/`): Repository implementations, data sources
- **Presentation Layer** (`lib/presentation/`): UI, BLoC state management
- **Offline Module** (`lib/offline/`): Complete clean architecture for local tournament features

### State Management
- **BLoC Pattern**: Primary state management using `flutter_bloc`
- **Provider**: Secondary state management for simple cases
- **Dependency Injection**: Using `get_it` for service locator pattern

### Key Technologies
- **Local Database**: SQLite with `sqflite` for offline tournament data
- **Firebase Services**: Auth, Firestore, Storage, Messaging, Analytics
- **UI**: Material Design with custom theming
- **Ads**: Google Mobile Ads integration
- **Additional**: Image picking, file sharing, charts, social sign-in

## Code Style & Conventions

### File Organization
- **Feature-based structure**: Group files by feature/module
- **Barrel exports**: Use index files where appropriate
- **Clear naming**: Use descriptive names for files and classes

### Naming Conventions
- **Classes**: PascalCase (e.g., `LeagueDetailBloc`, `PlayerModel`)
- **Files**: snake_case (e.g., `league_detail_bloc.dart`, `player_model.dart`)
- **Variables/Functions**: camelCase (e.g., `createLeague`, `playerModel`)
- **Constants**: SCREAMING_SNAKE_CASE or camelCase for private

### BLoC Pattern Implementation
```dart
// Event naming: [Feature][Action]Event
class LoadLeagueEvent extends LeagueDetailEvent

// State naming: [Feature]State with status enums
class LeagueDetailState extends Equatable {
  final LeagueDetailStatus status;
  // ... other properties
}

// BLoC method naming: _on[EventName]
_onLoadLeague(LoadLeagueEvent event, Emitter<LeagueDetailState> emit)
```

## Domain Models & Business Logic

### Core Entities
- **Offline Tournament System**: `LeagueModel`, `MatchModel`, `PlayerModel`, `RoundModel`
- **Statistics**: `PlayerStatsModel`, `ResultModel` with automated calculations
- **Online Social**: `GNUser`, `GNEsportGroup`, `GNEsportLeague`

### Business Rules
- **Tournament Logic**: Round-robin generation, match scoring, point calculations
- **Statistics**: Automatic wins/draws/losses tracking, goal difference calculations
- **User Management**: Firebase Auth with profile management
- **Group Management**: Owner permissions, member management

## Database & Data Management

### Local Database (SQLite)
- **Location**: `lib/offline/data/database/`
- **Manager**: `DatabaseManager` handles all local operations
- **Migrations**: Version-controlled schema updates
- **Relationships**: Proper foreign key relationships between tournaments, matches, players

### Firebase Integration
- **Authentication**: Email/password and Google Sign-In
- **Firestore**: Real-time data sync for groups, tournaments, chat
- **Storage**: Image uploads for avatars and tournament media
- **Messaging**: Push notifications for tournament updates

## UI/UX Guidelines

### Design System
- **Theme**: Material Design with custom colors
- **Dark Mode**: Supported with proper theme switching
- **Responsive**: Adaptive layouts for different screen sizes
- **Accessibility**: Proper semantic labels and navigation

### Widget Structure
- **Reusable Components**: Custom widgets in `lib/widgets/`
- **Feature Widgets**: Component widgets within feature folders
- **Consistent Naming**: `[Feature]View`, `[Feature]Page`, `[Feature]Item`

### Navigation
- **Route Management**: Centralized in `lib/routing.dart`
- **Page Structure**: Separate Page (BLoC provider) and View (UI) widgets
- **Deep Linking**: Support for tournament and group navigation

## Testing & Quality

### Code Quality
- **Linting**: Use `flutter_lints` for consistent code style
- **Error Handling**: Proper try-catch blocks with user-friendly messages
- **Validation**: Input validation for tournament creation and user data

### Testing Strategy
- **Unit Tests**: Business logic and use cases
- **Widget Tests**: UI components and interactions
- **Integration Tests**: Complete user flows

## Development Guidelines

### Adding New Features
1. **Start with Domain**: Define entities and use cases first
2. **Data Layer**: Implement repositories and data sources
3. **Presentation**: Create BLoC, events, states, then UI
4. **Dependency Injection**: Register services in `injection_container.dart`
5. **Routing**: Add navigation routes if needed

### Firebase Integration
- **Collections**: Follow existing naming conventions (`users`, `esportGroups`, `esportLeagues`)
- **Security Rules**: Ensure proper Firestore security rules
- **Offline Capability**: Handle offline scenarios gracefully

### Performance Considerations
- **Image Caching**: Use `cached_network_image` for remote images
- **List Performance**: Implement proper pagination for large datasets
- **Memory Management**: Dispose controllers and streams properly
- **Ad Integration**: Load ads responsibly without blocking UI

### Common Patterns
- **Repository Pattern**: All data access through repository interfaces
- **Use Case Pattern**: Business logic encapsulated in use cases
- **BLoC Pattern**: Consistent state management across features
- **Failure Handling**: Use `Either<Failure, Success>` pattern with `dartz`

## Specific Feature Notes

### Tournament Management
- **League Creation**: Automatic date-based naming, player assignment
- **Match System**: Round-robin generation with configurable formats
- **Statistics**: Real-time calculation of standings and player stats
- **Persistence**: All data stored locally with SQLite

### Social Features
- **Groups**: Create/join esports groups with member management
- **Tournaments**: Online tournaments with real-time updates
- **Chat**: Group-based messaging system
- **Notifications**: Push notifications for important updates

### Monetization
- **Google Ads**: Banner and interstitial ads integrated throughout
- **Premium Features**: Feature flags for advanced functionality
- **Analytics**: Firebase Analytics for user behavior tracking

Remember to maintain consistency with existing patterns and always consider both offline and online user experiences when making changes.
