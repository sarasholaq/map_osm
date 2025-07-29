import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  final MapController mapController = MapController();
  LocationData? currentLocation;
  List<LatLng> routePoints = [];
  List<Marker> markers = [];
  final String orsApiKey = "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImQ2OWRlOWYzMDIwNDQwYjRiYmI5YjI2ZjNmZDc1OTI5IiwiaCI6Im11cm11cjY0In0=";


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    var location = Location();
    try{
      var userLocation = await location.getLocation();
      setState(() {
        currentLocation = userLocation;
        markers.add(
          Marker(
            width: 80,
            height: 80,
            point: LatLng(userLocation.latitude!, userLocation.longitude!),
            child: Icon(Icons.my_location, color: Colors.blue, size: 40,),
          ),
        );
      });
    }on Exception {
      currentLocation = null;
    }

    location.onLocationChanged.listen((LocationData newLocation){
      setState(() {
        currentLocation = newLocation;
      });
    });

  }


  Future<void> getRoute(LatLng destination) async {
    if(currentLocation == null) return;

    final start = LatLng(currentLocation!.latitude!, currentLocation!.longitude!);
    final response = await http.get(
      Uri.parse(
        'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${start.longitude},${start.latitude}&end=${destination.longitude},${destination.latitude}',
      ),
    );

    if(response.statusCode == 200){
      final data = json.decode(response.body);
      final List<dynamic> coords = data['features'][0]['geometry']['coordinates'];
      setState(() {
        routePoints = coords.map((coords) => LatLng(coords[1], coords[0])).toList();
        markers.add(
          Marker(
            width: 80,
            height: 80,
            point: destination,
            child: Icon(Icons.location_on, color: Colors.blue, size: 40,),
          ),
        );
      });
    }else{
      print('failed to fetch route');
    }
  }

  void addDestinationMarker (LatLng point){
    setState(() {
      markers.add(
          Marker(
            width: 80,
            height: 80,
            point: point,
            child: Icon(Icons.location_on, color: Colors.red, size: 40,),
          ),
        );
    });
    getRoute(point);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('Open Street Map on Flutter')),
      ),
      body: currentLocation == null ? CircularProgressIndicator()
          : FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
              initialZoom: 15,
              onTap: (TapPosition, point) => addDestinationMarker(point)
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.map_learn',
              ),
              MarkerLayer(markers: markers),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 4,
                    color: Colors.pink,
                  ),
                ],
              ),
            ],
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: (){
              if(currentLocation != null){
                mapController.move(
                  LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                  15,
                );
              }
            },
            child: Icon(Icons.my_location),
          ),
    );
  }
}