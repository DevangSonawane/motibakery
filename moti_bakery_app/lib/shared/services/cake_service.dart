import '../models/cake.dart';
import 'mock_data.dart';

class CakeService {
  Future<List<Cake>> fetchCakes() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return mockCakes.where((cake) => cake.isActive).toList(growable: false);
  }
}
