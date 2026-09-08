# SESH architecture

The app uses a feature-oriented Flutter structure with Cubit state management. The presentation layer invokes Cubits, Cubits call repositories, and repositories own HTTP or SharedPreferences access. `main.dart` currently wires the small demonstrable vertical slice; larger features can be extracted into their prescribed feature folders without changing the user flows.

`NewsApiRepository` supports NewsAPI `/v2/everything` and a local fallback. `SavedCubit` and `OnboardingCubit` persist state with SharedPreferences. `ThemeCubit` and `LanguageCubit` drive the app shell and RTL-capable locale.
