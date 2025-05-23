# DNS Manager

A Flutter application for managing DNS configurations on Windows.

## Features

- Create and save multiple DNS server configurations
- Easily switch between different DNS configurations
- Support for primary and alternate DNS servers
- Automatic detection of network interfaces
- Reset to automatic (DHCP) DNS settings
- Modern Material design

## Requirements

- Windows operating system
- Flutter SDK
- Administrator privileges

## Installation

1. Clone this repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the application

## Usage

1. Launch the app **with administrator privileges**
2. Select a network interface from the dropdown
3. Add DNS configurations by tapping the + button
4. Activate a configuration by tapping the play button
5. Return to automatic DNS settings with the "Use Automatic DNS" button

## Administrator Privileges

This application **requires administrator privileges** to modify DNS settings on Windows. 
If the app is not run as an administrator, you'll encounter permission errors when trying to 
change DNS settings.

### Running with Administrator Privileges

#### Option 1: Automatic elevation (recommended)
If the application detects it doesn't have administrator privileges, it will display a screen with a "Restart with Admin Privileges" button. Clicking this button will:
1. Close the current instance
2. Restart the application with administrator privileges
3. Show a UAC prompt that you need to approve

#### Option 2: Manual elevation
You can also manually run the application as administrator:
1. Right-click the application executable
2. Select "Run as administrator"
3. Confirm the UAC prompt

The application uses the Windows PowerShell command `Set-DnsClientServerAddress` to modify 
DNS settings, which requires elevated privileges.

## Troubleshooting

If you encounter permission errors like:
```
Access to a CIM resource was not available to the client.
PermissionDenied: Set-DnsClientServerAddress
```

Make sure you're running the application as an administrator.
#   d n s m a n a g e r  
 