# Dermavision Project Structure

This project is organized into two main parts: the mobile application and the machine learning & federated learning research.

## Directory Structure

- `mobile_app/`: The Flutter application source code.
  - `lib/`: Dart source code.
  - `assets/`: App assets, including the TFLite model and labels.
  - `android/`: Android-specific configuration.
- `ml/`: Machine learning research and model development.
  - `notebooks/`: Jupyter notebooks for data setup, training, and optimization.
  - `scripts/`: Python scripts for model conversion, inspection, and testing.
  - `models/`: Keras (.keras) and TFLite (.tflite) model files.
  - `data/`: Processed data files (.npy) and dataset files.
  - `results/`: Evaluation results, figures, and plots.
  - `logs/`: Training and inspection logs.
  - `misc/`: Miscellaneous files and backups.
- `requirements.txt`: Python dependencies for the ML scripts.

## Development Environment

This project uses **Flutter 3.35.7**. We recommend using [FVM](https://fvm.app/) to manage Flutter versions.

### Prerequisites

- **Flutter SDK**: 3.35.7
- **Dart SDK**: 3.9.2
- **Android Studio / Xcode**: For mobile development.
- **Python 3.9+**: For ML research and model optimization.

### Quick Start (Windows)

To set up the entire project (dependencies + native libraries):

1.  Open PowerShell as Administrator.
2.  Run the setup script:
    ```powershell
    .\setup.ps1
    ```

### Manual Setup

#### Mobile App
1.  Navigate to `mobile_app/`.
2.  Install Flutter dependencies: `flutter pub get`.
3.  Install native TFLite libraries (Required for Android):
    ```powershell
    cd mobile_app
    .\download_tflite_libs.ps1
    ```
4.  Run the app: `flutter run`.

#### ML Research
1.  Install Python dependencies:
    ```bash
    pip install -r requirements.txt
    ```
2.  Explore the `ml/notebooks/` directory.

## Best Practices

- **Linting**: We use strict linting rules. Run `flutter analyze` before committing.
- **Formatting**: Format on save is enabled in VS Code settings.
- **Dependencies**: Always check `pubspec.lock` when merging to avoid version drift.

