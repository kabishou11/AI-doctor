# HarmonyOS Harmony Stage Application

This directory contains the HarmonyOS Harmony Stage application scaffold for the AI Medical Consultation Panel.

## Overview

This is a native HarmonyOS application built with ArkTS and ArkUI that replicates the desktop web client's UI structure and functionality for HarmonyOS devices. The application provides a medical consultation interface with support for multiple AI-powered doctors.

## Directory Structure

```
harmony/
├── entry/                              # Main entry module
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── ability/
│   │   │   │   └── MyAbility.ts       # Main ability entry point
│   │   │   ├── Application/
│   │   │   │   └── MyAbilityStage.ts  # Application stage
│   │   │   ├── components/
│   │   │   │   ├── Header.ets         # Header with logo and actions
│   │   │   │   ├── DiscussionPane.ets # Discussion area placeholder
│   │   │   │   ├── StatusPane.ets     # Status panel placeholder
│   │   │   │   ├── modals/
│   │   │   │   │   ├── GlobalSettingsModal.ets
│   │   │   │   │   └── ConsultationSettingsModal.ets
│   │   │   │   └── drawers/
│   │   │   │       └── SessionListDrawer.ets
│   │   │   ├── pages/
│   │   │   │   └── Index.ets          # Main page with layout
│   │   │   └── utils/
│   │   │       └── Logger.ts          # Logging utility
│   │   ├── resources/
│   │   │   ├── base/
│   │   │   │   ├── element/           # String and color resources
│   │   │   │   └── media/
│   │   │   │       └── logo.svg       # Application logo
│   │   │   └── zh_CN/                 # Chinese localization resources
│   │   └── module.json5               # Module configuration
│   ├── build-profile.json5            # Build configuration
│   ├── hvigorfile.ts                  # Hvigor build script
│   └── oh-package.json5               # Package configuration
├── build-profile.json5                # Root build configuration
├── hvigorfile.ts                      # Root hvigor build script
├── oh-package.json5                   # Root package configuration
└── README.md                          # This file
```

## Prerequisites

- HarmonyOS SDK 4.0 or later
- DevEco Studio 5.0 or later
- Node.js 16.0 or later

## Installation and Setup

1. **Install DevEco Studio**
   - Download and install DevEco Studio from the official Huawei website
   - Configure the HarmonyOS SDK path

2. **Install hvigor (if building from command line)**
   ```bash
   npm install -g @ohos/hvigor-cli
   ```

3. **Install project dependencies**
   ```bash
   cd harmony
   npm install
   # or
   pnpm install
   ```

## Building the Application

### Using DevEco Studio

1. Open DevEco Studio
2. File → Open → Select the `harmony` directory
3. Wait for project indexing to complete
4. Click Build → Build App → Build HAP (or press Ctrl+Shift+B)

### Using Command Line

```bash
cd harmony

# Build the entry module
hvigor assembleEntry

# Build with release configuration
hvigor assembleEntry -m entry -p release
```

## Running the Application

### On HarmonyOS Device

1. Connect a HarmonyOS device via USB with USB debugging enabled
2. In DevEco Studio, select your device from the device dropdown
3. Click the Run button (or press Shift+F10)

### On HarmonyOS Emulator

1. Launch the HarmonyOS emulator from DevEco Studio
2. Click the Run button to deploy and launch the application

### Command Line Deployment

```bash
# After building successfully
hvigor install -m entry

# Launch the application
hdc shell am start -n com.example.harmonymedical/.MyAbility
```

## UI Layout

The application mirrors the desktop Vue web client layout:

### Header Section
- **Logo**: AI Medical Consultation Panel logo
- **Title**: Application title and disclaimer
- **Action Buttons**:
  - "问诊列表" (Consultation List) - Opens session list drawer
  - "全局设置" (Global Settings) - Opens global settings modal
  - "问诊设置" (Consultation Settings) - Opens consultation settings modal

### Body Section (Two-Column Layout)

#### Left Column - Discussion Pane (2/3 width)
- **Purpose**: Displays doctor discussions and patient consultation history
- **Features**:
  - Scrollable discussion history
  - Input field for patient queries
  - Send button to submit messages
- **Placeholder**: Currently displays sample messages

#### Right Column - Status Pane (1/3 width)
- **Purpose**: Shows consultation status and information
- **Features**:
  - Patient information display
  - Participating doctors status
  - Action buttons (Start Consultation, Settings)
- **Placeholder**: Currently displays sample status data

### Modal/Drawer Components

#### Global Settings Modal
- Placeholder for system-wide settings
- Tab-based interface
- Save/Cancel actions

#### Consultation Settings Modal
- Doctor configuration management
- Doctor selection for current consultation
- Tab-based interface

#### Session List Drawer
- Lists all previous consultations
- Actions for each session (View, Export, Delete)
- New session creation option

## Key Components

### ArkTS Files

1. **MyAbility.ts** - Main ability lifecycle management
2. **MyAbilityStage.ts** - Application stage initialization
3. **Logger.ts** - Centralized logging utility

### ArkUI Components

1. **Index.ets** - Main page layout combining header and two-column body
2. **Header.ets** - Top navigation with logo, title, and action buttons
3. **DiscussionPane.ets** - Left panel for discussion history
4. **StatusPane.ets** - Right panel for consultation status
5. **GlobalSettingsModal.ets** - Global settings dialog
6. **ConsultationSettingsModal.ets** - Consultation configuration dialog
7. **SessionListDrawer.ets** - Side drawer for session management

## Resource Files

- **logo.svg** - Application logo imported from the web client
- **strings.json** - Localized string resources
- **color.json** - Color definitions for consistent styling

## Build Output

After a successful build, the HAP (HarmonyOS Ability Package) will be located at:

```
entry/build/default/outputs/entry-default-release.hap
```

## Linking with Web Client

The web client continues to run independently:

```bash
# Web client (from project root)
pnpm install
pnpm dev

# HarmonyOS client (from harmony directory)
npm install
# Build and run via DevEco Studio or hvigor command
```

Both clients share:
- Same application concept and workflow
- Same logo asset
- Similar UI layout and structure
- Different technology stacks (Vue 3 vs ArkUI)

## Future Enhancements

- Integrate with existing backend API (if applicable)
- Add state management (similar to Pinia in web client)
- Implement actual consultation logic
- Add data persistence (LocalStorage equivalent)
- Enhanced styling and animations
- Localization for multiple languages
- Integration with HarmonyOS system capabilities

## Contributing

When making changes to the HarmonyOS app:

1. Follow HarmonyOS/ArkUI design guidelines
2. Maintain consistency with the web client's layout
3. Test on multiple device sizes (tablets, phones)
4. Use meaningful component and variable names
5. Keep components modular and reusable

## Troubleshooting

### Build Failures

- **SDK version mismatch**: Ensure your HarmonyOS SDK version matches the compileSdkVersion in build-profile.json5
- **Dependency issues**: Run `npm install` or `pnpm install` to ensure all dependencies are installed
- **Resource errors**: Verify that string.json and color.json are properly formatted

### Runtime Issues

- **App crashes on startup**: Check DevEco Studio logs for detailed error messages
- **Component rendering issues**: Verify component imports are correct
- **Navigation issues**: Ensure modal/drawer onClose callbacks are properly implemented

## References

- [HarmonyOS Developer Documentation](https://developer.harmonyos.com/)
- [ArkUI Component Library](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkui-overview-0000001478061421-V3)
- [ArkTS Language Guide](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-0000001478181149-V3)
- [Hvigor Build System](https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/hvigor-0000001417064920-V3)

## License

Same as the parent project (MIT)
