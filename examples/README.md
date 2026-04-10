# Example apps

| Directory | Stack |
| --------- | ----- |
| [`static_app`](static_app) | `FlexTrack.quickSetup` / `FlexTrack.track` only |
| [`riverpod_app`](riverpod_app) | `FlexTrack.setup` + `FlexTrack.instance.client` via Riverpod |
| [`bloc_getit_app`](bloc_getit_app) | Same client registered in GetIt; `Cubit` calls `client.track` |

The full demo lives in [`../example/`](../example/). Run any app with `flutter pub get && flutter run` inside its folder.
