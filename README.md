<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="./FlyMe/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png">
    <img src="./FlyMe/Assets.xcassets/AppIcon.appiconset/AppIcon-Light.png" alt="FlyMe icon" width="112">
  </picture>
  <h1>FlyMe</h1>
  <p>A private and thoughtfully designed self-awareness tracker for iPhone.</p>
  <p>
    <img src="https://img.shields.io/badge/platform-iOS%2026%2B-lightgrey?logo=apple" alt="Platform iOS 26+">
    <img src="https://img.shields.io/badge/built%20with-SwiftUI-F05138?logo=swift&logoColor=white" alt="Built with SwiftUI">
    <img src="https://img.shields.io/badge/interface-Liquid%20Glass-8B5CF6" alt="Liquid Glass interface">
    <img src="https://img.shields.io/badge/data-local%20first-22C55E" alt="Local-first data">
  </p>
  <p>
    English | <a href="README.zh-CN.md">简体中文</a>
  </p>
</div>

FlyMe, displayed in-app as **清醒**, helps users recognize behavioral patterns, understand personal rhythms, and record each more intentional choice. It combines a calm Liquid Glass interface with focused tracking, history, and trend views.

## Interface Preview

### Home and Quick Check-ins

<p align="center">
  <img src="./photos/home.png" alt="FlyMe home screen" width="45%">
  <img src="./photos/quick-checkin.png" alt="FlyMe quick check-in screen" width="45%">
</p>

The home screen keeps the current score, recent records, and the primary check-in action close at hand. Quick Check-in presents all six record types in one focused sheet.

### Animated Success Feedback

<p align="center">
  <img src="./photos/success-urge.png" alt="Urge success animation" width="45%">
  <img src="./photos/success-masturbation.png" alt="Masturbation success animation" width="45%">
</p>

Each category receives its own full-screen color treatment, symbol, message, animation, sound, and haptic feedback.

### Trends and Score Insights

<p align="center">
  <img src="./photos/trends-metrics.png" alt="Metric trends" width="45%">
  <img src="./photos/trends-score.png" alt="Score trend and weekly insights" width="45%">
</p>

<p align="center">
  <img src="./photos/score-details.png" alt="Self-discipline score details" width="45%">
</p>

Compare selected behavior metrics, follow the separate score trend, and open the score explanation to understand exactly how the current result is calculated.

### History and Settings

<p align="center">
  <img src="./photos/history-matrix.png" alt="35-day history matrix" width="45%">
  <img src="./photos/history-day.png" alt="Date-based history browser" width="45%">
</p>

<p align="center">
  <img src="./photos/settings.png" alt="FlyMe settings" width="45%">
</p>

History combines a switchable 35-day metric matrix with calendar-based browsing. Settings keeps privacy controls, feedback preferences, and manual backup together.

## Quick Check-ins

- Record six types of moments: urges, successful redirections, masturbation, intimacy, explicit content, and nocturnal emissions
- Add a record immediately from the home screen or backdate it from History
- Receive a distinct full-screen success animation, gentle sound effect, and haptic response after every check-in
- Add optional notes to preserve useful context

## Self-Discipline Score

- View a continuously updated self-discipline score on the home screen
- Understand how recent behavior, stable days, and successful redirections affect the score
- Open the score card to see the complete scoring explanation
- Follow a separate score trend chart to understand changes over time

## Trends and Insights

- Compare the occurrence counts of all six metrics in a single trend chart
- Select exactly which metrics should appear together
- Switch smoothly between one week, one month, six months, and one year
- Review category distribution and overall recording patterns

## History

- Browse past records using a Chinese-localized calendar
- Inspect any selected day's complete activity
- Switch the 35-day matrix between all six metrics to see daily frequency
- Add past records with the same animated success feedback
- Select, manage, and delete multiple historical records at once

## Privacy and Personalization

- Keep records on the device by default
- Hide sensitive category names throughout the app with Discreet Mode
- Enable or disable success sounds and haptic feedback independently
- Manually back up and restore records through a user-selected location, including iCloud Drive

## Design

- Native SwiftUI interface built for iOS 26
- Liquid Glass surfaces, soft aurora colors, and restrained visual depth
- Fluid transitions, scroll-driven motion, and animated chart switching
- Dedicated light and dark mode app icons
- Portrait-focused iPhone experience
