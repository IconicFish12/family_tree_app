# Family Tree Application

## Overview

The Family Tree Application is a sophisticated mobile and web solution built with Flutter, designed to facilitate the digital management and visualization of family lineages. This application provides users with an intuitive interface to create, edit, and explore complex family structures, ensuring that genealogical data is preserved and easily accessible.

## Key Features

- **Interactive Genealogy Visualization**: utilizes `GraphView` to render dynamic, interactive family trees that allow users to navigate through generations seamlessly.
- **Comprehensive Profile Management**: Enables detailed storage of family member information, including personal details, media associations, and historical data.
- **Relationship Mapping**: Efficiently handles complex relationship types including spouses, children, and parents, maintaining data integrity across the tree.
- **Cross-Platform Compatibility**: Fully optimized for both Android and iOS platforms, with web support capabilities.
- **Modern Infrastructure**: Built on a robust architecture ensuring scalability and performance.

## Technology Stack

This project leverages a modern technology stack to ensure performance and maintainability:

- **Framework**: Flutter (Dart)
- **State Management**: Provider
- **Networking**: Dio
- **Data Modeling**: Freezed & JSON Serializable
- **Navigation**: GoRouter
- **Visualization**: GraphView
- **Utilities**:
    - `fpdart` for functional programming patterns
    - `get_it` for dependency injection
    - `logger` for advanced logging

## Getting Started

### Prerequisites

- Flutter SDK (Latest Stable Version)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1.  **Clone the Repository**

    ```bash
    git clone <repository-url>
    ```

2.  **Install Dependencies**

    Navigate to the project directory and run:

    ```bash
    flutter pub get
    ```

3.  **Code Generation**

    This project uses code generation for JSON serialization and immutability. Run the build runner:

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

### Running the Application

To run the application in debug mode:

```bash
flutter run
```

For a release build:

```bash
flutter run --release
```

## Project Structure

The codebase adheres to a clean architecture pattern, organized as follows:

- `lib/core`: Contains core utilities and shared functionality.
- `lib/data`: Handles data layer responsibilities including models and repositories.
- `lib/views`: Contains UI components and screens.
- `lib/config`: Configuration files and environment settings.
- `lib/components`: Reusable UI widgets.

## Development

for any development inquiries or contributions, please refer to the project's contribution guidelines or contact the development team.
