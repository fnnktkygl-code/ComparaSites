# ComparaSites ◈

[![License: MIT](https://img.shields.io/badge/License-MIT-indigo.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.22+-blue.svg)](https://flutter.dev)
[![Web Demo](https://img.shields.io/badge/Demo-Live-green.svg)](https://fnnktkygl-code.github.io/ComparaSites/)

ComparaSites is a premium cross-platform price comparison application designed to help users find the best deals for their favorite brands across **12 European countries**. 

By aggregating real-time product prices directly from official online stores, ComparaSites automatically converts local currencies to Euro (€), highlights the cheapest country, and calculates exactly how much you save compared to shopping in France.

---

## 🔗 Live Demo Links

*   **Landing Page (Website):** [https://fnnktkygl-code.github.io/ComparaSites/](https://fnnktkygl-code.github.io/ComparaSites/)
*   **Web Application:** [https://fnnktkygl-code.github.io/ComparaSites/app/](https://fnnktkygl-code.github.io/ComparaSites/app/)

---

## ✨ Key Features

*   🌍 **Multi-Country Scan:** Scan up to 12 European countries simultaneously (France, Germany, Spain, Italy, United Kingdom, Poland, Belgium, Portugal, Netherlands, Romania, Czech Republic, Hungary).
*   🪙 **Auto-Currency Conversion:** Instantly converts non-Euro currencies (PLN, GBP, RON, HUF, CZK) using daily updated exchange rates.
*   🔍 **Smart Variant Search:** Handles multi-color sale items (e.g., matching Zara sale variants that are not visible through standard store listings).
*   ⚙️ **System-Aware Theme:** Premium, modern glassmorphic interface with Light & Dark modes that sync automatically with your system settings or can be toggled manually.
*   🌐 **Multilingual Support:** Fully translated into **French**, **English**, and **Spanish** via an in-app settings panel.
*   📜 **Scan History:** Persistent offline history repository to restore and re-run previous product scans with one click.
*   ⚡ **Single-Country Refresh:** Scan individual countries independently to save bandwidth and update specific prices quickly.

---

## 🛍️ Supported Stores & Brands

| Brand | Categories |
| :--- | :--- |
| **Decathlon** | Sports & Outdoor Gear |
| **Zara** | Apparel & Fashion |
| **JD Sports** | Sneakers & Athletic Wear |
| **Amazon** | Retail General Catalog |
| **IKEA** | Furniture & Home Decor |
| **Sephora** | Cosmetics & Beauty |

---

## 🛠️ Architecture & Technology Stack

The project is split into two primary folders:
1.  **Flutter Application (App):** Built using Dart & Flutter. State management is powered by `Provider`. Native scrapers utilize headless webviews on mobile/desktop and a fallback CORS proxy (`corsproxy.io`) on Web.
2.  **Landing Page:** A premium, lightweight, responsive static website written in clean semantic HTML5 and Vanilla CSS, using `IntersectionObserver` scroll-reveal animations.

---

## 🚀 Getting Started

### Prerequisites
*   Flutter SDK (`>=3.2.0`)
*   Dart SDK

### Run the App Locally

1.  Clone this repository:
    ```bash
    git clone https://github.com/fnnktkygl-code/ComparaSites.git
    cd ComparaSites
    ```

2.  Install all Flutter dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the application on your preferred platform:
    ```bash
    # Run on macOS (Desktop)
    flutter run -d macos

    # Run on Web (Development server)
    flutter run -d chrome
    ```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
