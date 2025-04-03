# Factory Reporting System

A Flutter desktop application for Windows that enables factories to create custom inspection forms, assign them to inspectors, and collect inspection data.

## Project Overview

This application uses Flutter for the UI and SQLite for local data storage. The system allows administrators to create customized forms with various field types, assign them to inspectors, and view completed reports.

## Features (Phase 1)

- **User Authentication**: Login system with different user roles (admin and inspector)
- **Database Foundation**: SQLite database with tables for users, forms, form fields, reports, and assignments
- **Windows Desktop Support**: Configured for Windows desktop deployment

## Getting Started

### Prerequisites

- Flutter SDK (version 3.6.0 or higher)
- Windows development environment
- Visual Studio with C++ desktop development workload

### Setup

1. Clone the repository
2. Install dependencies:
   ```
   flutter pub get
   ```
3. Run the application:
   ```
   flutter run -d windows
   ```

### First Time Setup

When you first run the application, you'll need to create an admin user:
1. Click on "Create Admin User (First Time Setup)" on the login screen
2. Enter a username and password for the admin account
3. Click "Create" to create the admin user
4. Login with the newly created admin credentials

## Project Structure

- `lib/main.dart` - Application entry point and provider setup
- `lib/services/database_helper.dart` - SQLite database management
- `lib/models/` - Data models for the application
- `lib/screens/` - UI screens

## Database Schema

The application uses the following database tables:

- **Users** - Stores user accounts and passwords
- **Forms** - Stores form templates
- **FormFields** - Stores fields for each form
- **Reports** - Stores completed reports
- **ReportData** - Stores the data for each report
- **FormAssignments** - Stores assignments of forms to inspectors

## Future Development (Phase 2+)

- Form creation and management UI
- User management
- Report creation and submission
- Report analytics and export
