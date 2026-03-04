import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/cake_room/presentation/cake_room_dashboard_screen.dart';
import '../features/cake_room/presentation/cake_room_order_detail_screen.dart';
import '../features/gallery/presentation/cake_detail_screen.dart';
import '../features/gallery/presentation/counter_home_screen.dart';
import '../features/orders/presentation/my_orders_screen.dart';
import '../features/orders/presentation/order_confirmation_screen.dart';
import '../features/orders/presentation/order_detail_screen.dart';
import '../features/orders/presentation/place_order_screen.dart';
import '../shared/models/app_user.dart';
import '../shared/models/cake.dart';
import '../shared/models/order.dart';
import '../shared/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider).state;

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final user = auth.user;

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      final counterLocations = <String>{
        '/counter',
        '/cake-detail',
        '/place-order',
        '/order-confirmation',
        '/my-orders',
        '/order-detail',
      };
      final cakeRoomLocations = <String>{
        '/cake-room',
        '/cake-room/order-detail',
      };

      if (isLoggingIn) {
        return user.role == UserRole.counter ? '/counter' : '/cake-room';
      }

      if (user.role == UserRole.counter &&
          !counterLocations.contains(state.matchedLocation)) {
        return '/counter';
      }

      if (user.role == UserRole.cakeRoom &&
          !cakeRoomLocations.contains(state.matchedLocation)) {
        return '/cake-room';
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/counter',
        builder: (context, state) => const CounterHomeScreen(),
      ),
      GoRoute(
        path: '/cake-detail',
        builder: (context, state) => CakeDetailScreen(cake: state.extra! as Cake),
      ),
      GoRoute(
        path: '/place-order',
        builder: (context, state) => PlaceOrderScreen(cake: state.extra! as Cake),
      ),
      GoRoute(
        path: '/order-confirmation',
        builder: (context, state) {
          final order = state.extra! as Order;
          return OrderConfirmationScreen(order: order);
        },
      ),
      GoRoute(
        path: '/my-orders',
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/order-detail',
        builder: (context, state) {
          return OrderDetailScreen(order: state.extra! as Order);
        },
      ),
      GoRoute(
        path: '/cake-room',
        builder: (context, state) => const CakeRoomDashboardScreen(),
      ),
      GoRoute(
        path: '/cake-room/order-detail',
        builder: (context, state) {
          return CakeRoomOrderDetailScreen(order: state.extra! as Order);
        },
      ),
    ],
  );
});
