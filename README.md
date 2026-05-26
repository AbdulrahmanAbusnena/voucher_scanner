# Voucher Scanner - ماسح الكروت 

A high-speed, 100% offline mobile utility application designed specifically for the Libyan market to instantly scan, track, and dial pre-paid mobile and internet scratch card vouchers (Libyana, Al-Madar, LTT) without manual typing errors.

Built using **Flutter**, managed reactively with **Riverpod**, and powered by device-local machine learning via my beloved **Google ML Kit**.



## 📱 App Demonstration (Coming soon I just need to figure out how to record and translate it into .md)

| الرئيسية — History Dashboard | المسح السريع — Live OCR Scanner |
|:---:|:---:|
| <img src="https://via.placeholder.com/300x600.png?text=History+Dashboard+Screenshot" width="280" alt="Dashboard Screen"/> | <img src="https://via.placeholder.com/300x600.png?text=Live+OCR+Scanner+Screenshot" width="280" alt="Scanner Screen"/> |




## ✨ Features

- **Live Stream Camera OCR:** No need to take a physical photo. Point your lens at any voucher, and the local ML Kit engine parses the string dynamically in real time.
- **Smart Carrier Detection:** Automatically identifies operator parameters based on length patterns:
  - **Libyana (ليبيانا):** 14-digit sequence $\rightarrow$ Maps to `*121*<code>#`
  - **Al-Madar (المدار):** 13-digit sequence $\rightarrow$ Maps to `*112*<code>#`
  - **LTT (ليبيا للاتصالات):** 15-digit sequence $\rightarrow$ Maps to `*116*<code>#`
- **One-Click Native Dialing:** Seamlessly builds system deep links and encodes the terminal `#` character safely (`%23`) to prevent OS cellular dialer truncation bugs.
- **Offline Ledger Log:** Tracks total and carrier-specific usage counts. Vouchers can be toggled as "Used" to prevent accidental re-dialing.
- **100% Privacy Focused:** No remote servers, database tracking, or external cloud telemetry overhead. Everything runs locally on the host device.


## 🏗️ Architectural Layout

The project follows a **Feature-First Clean Architecture** approach, keeping platform adapters entirely isolated from user interface logic:

```directory
lib/
├── core/
│   ├── constants/       # Carrier USSD Dial prefixes & codes
│   └── services/        # Low-level native platform services (Storage, Intent Dialers)
├── shared/
│   └── widgets/         # Reusable app-wide visual UI components
└── features/
    ├── scanner/         # Camera hardware interface and live ML Kit frame parsing
    │   └── presentation/
    └── history/         # Offline transaction data ledger management
        ├── data/        # JSON serialization handlers
        ├── domain/      # Immutable Voucher and Carrier data models
        └── presentation/# Dashboard metrics view and Riverpod state controllers
```

## more features are coming, and wait for it to get deployed into your native store
