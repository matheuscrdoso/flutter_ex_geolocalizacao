import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geolocalização e Mapa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool? isWithinRadius;
  double distance = 0.0;
  LatLng userLocation = LatLng(0, 0);

  // Coordenadas da escola
  final LatLng escolaLocation = const LatLng(-2.5409266372299237, -44.2892850282645);

  // Raio em metros
  final double raio = 40;

  @override
  void initState() {
    super.initState();
    _checkUserLocation();
  }

  Future<void> _checkUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica se os serviços de localização estão habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Serviços de localização não estão habilitados.
      return Future.error('Os serviços de localização estão desativados.');
    }

    // Verifica as permissões de localização.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('As permissões de localização foram negadas.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissões foram negadas permanentemente, então não é possível pedir permissões novamente.
      return Future.error('As permissões de localização foram negadas permanentemente.');
    }

    // Obtém a localização atual do usuário.
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    // Atualiza a localização do usuário
    userLocation = LatLng(position.latitude, position.longitude);

    // Calcula a distância do usuário até a escola.
    distance = _calculateDistance(escolaLocation.latitude, escolaLocation.longitude, position.latitude, position.longitude);

    setState(() {
      isWithinRadius = distance <= raio;
    });
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // PI / 180
    final double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000; R = 6371 km; convert km to meters
  }

  @override
  Widget build(BuildContext context) {
    debugDisableShadows;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de Localização com Mapa'),
      ),
      
      body: isWithinRadius == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      center: userLocation,
                      zoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: escolaLocation,
                            color: Colors.blue.withOpacity(0.3),
                            borderStrokeWidth: 2.0,
                            borderColor: Colors.blue,
                            useRadiusInMeter: true, // Especifica o uso de metros
                            radius: raio, // Em metros
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: escolaLocation,
                            width: 80.0,
                            height: 80.0,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40.0,
                            ),
                          ),
                          Marker(
                            point: userLocation,
                            width: 80.0,
                            height: 80.0,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.blue,
                              size: 40.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    isWithinRadius! ? 'Você está dentro do círculo.' : 'Você está fora do círculo.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }
}
