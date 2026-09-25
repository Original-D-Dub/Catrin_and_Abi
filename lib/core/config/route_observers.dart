import 'package:flutter/material.dart';

/// Lets a route detect exactly when it becomes visible again after a route
/// pushed on top of it is popped — used by `LearnBslTrailScreen` to play
/// its cloud-parting reveal only once the player is actually looking at the
/// trail again, not the moment the underlying provider state changes while
/// a game screen still covers it. Registered in `app.dart`'s
/// `navigatorObservers`.
final trailRouteObserver = RouteObserver<PageRoute<dynamic>>();
