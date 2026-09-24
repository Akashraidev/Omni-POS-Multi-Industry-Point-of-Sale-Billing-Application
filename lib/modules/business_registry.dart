import 'base/business_module_interface.dart';
import 'business_type.dart';

export 'base/business_module_interface.dart';
export 'business_type.dart';
import 'electronics/electronics_module.dart';
import 'garment/garment_module.dart';
import 'grocery/grocery_module.dart';
import 'medical/medical_module.dart';
import 'restaurant/restaurant_module.dart';
import 'supermarket/supermarket_module.dart';

class BusinessModuleRegistry {
  static final Map<BusinessType, BusinessModuleInterface> _modules = {};

  static void init() {
    register(MedicalBusinessModule());
    register(RestaurantBusinessModule());
    register(GroceryBusinessModule());
    register(SupermarketBusinessModule());
    register(ElectronicsBusinessModule());
    register(GarmentBusinessModule());
  }

  static void register(BusinessModuleInterface module) {
    _modules[module.type] = module;
  }

  static BusinessModuleInterface getModule(BusinessType type) {
    final module = _modules[type];
    if (module == null) {
      // Fallback to Grocery if not found
      return _modules[BusinessType.grocery] ?? GroceryBusinessModule();
    }
    return module;
  }

  static List<BusinessModuleInterface> getAllModules() {
    return _modules.values.toList();
  }
}
