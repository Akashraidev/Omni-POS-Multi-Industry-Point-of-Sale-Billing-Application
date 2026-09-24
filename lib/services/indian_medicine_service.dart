import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Singleton service that fetches and caches the Indian medicine dataset
/// from the GitHub repository for instant autocomplete when adding medicines.
class IndianMedicineService {
  static final IndianMedicineService instance = IndianMedicineService._();
  IndianMedicineService._();

  static const String _url =
      'https://raw.githubusercontent.com/junioralive/Indian-Medicine-Dataset/refs/heads/main/DATA/indian_medicine_data.json';

  List<Map<String, dynamic>> _medicines = [];
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  int get count => _medicines.length;

  /// Top commonly prescribed Indian medicines bundled for zero-latency offline suggestions.
  static final List<Map<String, dynamic>> _offlineFallback = [
    {
      'name': 'Dolo 650 Tablet',
      'manufacturer_name': 'Micro Labs Ltd',
      'short_composition1': 'Paracetamol (650mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 15 tablets',
      'price(₹)': 33.60,
    },
    {
      'name': 'Augmentin 625 Duo Tablet',
      'manufacturer_name': 'Glaxo SmithKline Pharmaceuticals Ltd',
      'short_composition1': 'Amoxycillin (500mg)',
      'short_composition2': 'Clavulanic Acid (125mg)',
      'pack_size_label': 'strip of 10 tablets',
      'price(₹)': 204.50,
    },
    {
      'name': 'Azithral 500 Tablet',
      'manufacturer_name': 'Alembic Pharmaceuticals Ltd',
      'short_composition1': 'Azithromycin (500mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 5 tablets',
      'price(₹)': 122.00,
    },
    {
      'name': 'Pan 40 Tablet',
      'manufacturer_name': 'Alkem Laboratories Ltd',
      'short_composition1': 'Pantoprazole (40mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 15 tablets',
      'price(₹)': 155.00,
    },
    {
      'name': 'Benadryl Cough Formula Syrup',
      'manufacturer_name': 'Johnson & Johnson Ltd',
      'short_composition1': 'Diphenhydramine (14.08mg/5ml)',
      'short_composition2': 'Ammonium Chloride (138mg/5ml)',
      'pack_size_label': 'bottle of 100ml syrup',
      'price(₹)': 115.00,
    },
    {
      'name': 'Betadine 10% Ointment',
      'manufacturer_name': 'Win-Medicare Pvt Ltd',
      'short_composition1': 'Povidone Iodine (10% w/w)',
      'short_composition2': '',
      'pack_size_label': 'tube of 15 gm ointment',
      'price(₹)': 98.00,
    },
    {
      'name': 'Asthalin 100mcg Inhaler',
      'manufacturer_name': 'Cipla Ltd',
      'short_composition1': 'Salbutamol (100mcg)',
      'short_composition2': '',
      'pack_size_label': 'inhaler of 200 metered doses',
      'price(₹)': 165.00,
    },
    {
      'name': 'Becosules Z Capsule',
      'manufacturer_name': 'Pfizer Ltd',
      'short_composition1': 'Vitamin B Complex',
      'short_composition2': 'Vitamin C (50mg) + Zinc (41.4mg)',
      'pack_size_label': 'strip of 20 capsules',
      'price(₹)': 48.50,
    },
    {
      'name': 'Combiflam Tablet',
      'manufacturer_name': 'Sanofi India Ltd',
      'short_composition1': 'Ibuprofen (400mg)',
      'short_composition2': 'Paracetamol (325mg)',
      'pack_size_label': 'strip of 20 tablets',
      'price(₹)': 46.00,
    },
    {
      'name': 'Allegra 120mg Tablet',
      'manufacturer_name': 'Sanofi India Ltd',
      'short_composition1': 'Fexofenadine (120mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 10 tablets',
      'price(₹)': 215.00,
    },
    {
      'name': 'Montair LC Tablet',
      'manufacturer_name': 'Cipla Ltd',
      'short_composition1': 'Montelukast (10mg)',
      'short_composition2': 'Levocetirizine (5mg)',
      'pack_size_label': 'strip of 15 tablets',
      'price(₹)': 320.00,
    },
    {
      'name': 'Telma 40 Tablet',
      'manufacturer_name': 'Glenmark Pharmaceuticals Ltd',
      'short_composition1': 'Telmisartan (40mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 30 tablets',
      'price(₹)': 245.00,
    },
    {
      'name': 'Glycomet 500 SR Tablet',
      'manufacturer_name': 'USV Ltd',
      'short_composition1': 'Metformin (500mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 20 tablets',
      'price(₹)': 45.00,
    },
    {
      'name': 'Shelcal 500 Tablet',
      'manufacturer_name': 'Torrent Pharmaceuticals Ltd',
      'short_composition1': 'Calcium (500mg)',
      'short_composition2': 'Vitamin D3 (250 IU)',
      'pack_size_label': 'strip of 15 tablets',
      'price(₹)': 135.00,
    },
    {
      'name': 'Liv 52 Syrup',
      'manufacturer_name': 'Himalaya Wellness Company',
      'short_composition1': 'Ayurvedic Herbal Blend',
      'short_composition2': '',
      'pack_size_label': 'bottle of 200ml syrup',
      'price(₹)': 170.00,
    },
    {
      'name': 'Ascoril D Plus Syrup',
      'manufacturer_name': 'Glenmark Pharmaceuticals Ltd',
      'short_composition1': 'Dextromethorphan (10mg)',
      'short_composition2': 'Chlorpheniramine (2mg) + Phenylephrine (5mg)',
      'pack_size_label': 'bottle of 100ml syrup',
      'price(₹)': 138.00,
    },
    {
      'name': 'Lantus 100IU/ml Solostar Pen',
      'manufacturer_name': 'Sanofi India Ltd',
      'short_composition1': 'Insulin Glargine (100IU/ml)',
      'short_composition2': '',
      'pack_size_label': 'prefilled pen of 3ml injection',
      'price(₹)': 680.00,
    },
    {
      'name': 'Ciplox 500mg Tablet',
      'manufacturer_name': 'Cipla Ltd',
      'short_composition1': 'Ciprofloxacin (500mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 10 tablets',
      'price(₹)': 42.00,
    },
    {
      'name': 'Zifi 200 Tablet',
      'manufacturer_name': 'FDC Ltd',
      'short_composition1': 'Cefixime (200mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 10 tablets',
      'price(₹)': 110.00,
    },
    {
      'name': 'Neurobion Forte Tablet',
      'manufacturer_name': 'Procter & Gamble Health Ltd',
      'short_composition1': 'Vitamin B Complex',
      'short_composition2': 'Vitamin B12 (15mcg)',
      'pack_size_label': 'strip of 30 tablets',
      'price(₹)': 40.00,
    },
    {
      'name': 'Omez 20 Capsule',
      'manufacturer_name': 'Dr Reddys Laboratories Ltd',
      'short_composition1': 'Omeprazole (20mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 20 capsules',
      'price(₹)': 62.00,
    },
    {
      'name': 'Crestor 10mg Tablet',
      'manufacturer_name': 'AstraZeneca Pharma India Ltd',
      'short_composition1': 'Rosuvastatin (10mg)',
      'short_composition2': '',
      'pack_size_label': 'strip of 15 tablets',
      'price(₹)': 325.00,
    },
    {
      'name': 'Volini Pain Relief Gel',
      'manufacturer_name': 'Sun Pharma Laboratories Ltd',
      'short_composition1': 'Diclofenac Diethylamine (1.16% w/w)',
      'short_composition2': 'Linseed Oil + Methyl Salicylate + Menthol',
      'pack_size_label': 'tube of 30 gm gel',
      'price(₹)': 145.00,
    },
    {
      'name': 'Otrivin Oxy Fast Relief Nasal Spray',
      'manufacturer_name': 'Glaxo SmithKline Consumer Healthcare',
      'short_composition1': 'Oxymetazoline (0.05% w/v)',
      'short_composition2': '',
      'pack_size_label': 'bottle of 10ml nasal drops',
      'price(₹)': 108.00,
    },
  ];

  /// Initialize and preload dataset. Starts with bundled fallback, then loads online.
  Future<void> loadIfNeeded() async {
    if (_loaded || _loading) return;

    // Load offline fallback immediately so autocomplete works with 0 delay
    if (_medicines.isEmpty) {
      _medicines = List.from(_offlineFallback);
    }

    _loading = true;
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 12);
      final request = await client.getUrl(Uri.parse(_url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final List<dynamic> data = jsonDecode(responseBody);
        final parsed = data.cast<Map<String, dynamic>>();

        if (parsed.isNotEmpty) {
          _medicines = parsed;
          _loaded = true;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('IndianMedicineService: Using bundled database ($e)');
      _loaded = true; // Fallback is active
    } finally {
      _loading = false;
    }
  }

  /// Search medicines by name, brand, or generic salt.
  List<Map<String, dynamic>> search(String query, {int limit = 25}) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return [];

    final list = _medicines.isNotEmpty ? _medicines : _offlineFallback;

    // Priority 1: name starts with query
    final startsWithName = list.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      return name.startsWith(q);
    }).take(limit).toList();

    if (startsWithName.length >= limit) return startsWithName;

    // Priority 2: generic salt / composition starts with query
    final startsWithComp = list.where((m) {
      final comp1 = (m['short_composition1'] ?? '').toString().toLowerCase();
      final comp2 = (m['short_composition2'] ?? '').toString().toLowerCase();
      return comp1.startsWith(q) || comp2.startsWith(q);
    }).take(limit - startsWithName.length).toList();

    final combined = {...startsWithName, ...startsWithComp}.toList();
    if (combined.length >= limit) return combined;

    // Priority 3: name or brand contains query
    final contains = list.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final brand = (m['manufacturer_name'] ?? '').toString().toLowerCase();
      return name.contains(q) || brand.contains(q);
    }).take(limit - combined.length).toList();

    return {...combined, ...contains}.toList();
  }
}
