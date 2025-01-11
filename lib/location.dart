import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPage extends StatefulWidget {
  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  TextEditingController _searchController = TextEditingController();
  GoogleMapController? mapController;
  Set<Marker> _markers = {};
  Set<Marker> _favoriteMarkers = {};
  List<Map<String, double>> _favoriteLocations = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    prefs = await SharedPreferences.getInstance();
    List<String>? favoriteData = prefs.getStringList('favorites');
    if (favoriteData != null) {
      setState(() {
        _favoriteLocations = favoriteData
            .map((e) => Map<String, double>.from(
            {"latitude": double.parse(e.split(',')[0]), "longitude": double.parse(e.split(',')[1])}))
            .toList();
        _favoriteMarkers = _favoriteLocations
            .map((loc) => Marker(
          markerId: MarkerId("${loc['latitude']},${loc['longitude']}"),
          position: LatLng(loc['latitude']!, loc['longitude']!),
          infoWindow: InfoWindow(title: 'Favorite Location'),
        ))
            .toSet();
      });
    }
  }

  void _onSearch() {
    // You can use Google Places API or any other method to get the Lat/Lng of the searched location.
    // For simplicity, assume a fixed Lat/Lng for now
    LatLng location = LatLng(37.7749, -122.4194); // Example: San Francisco
    mapController?.animateCamera(CameraUpdate.newLatLng(location));
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId('searchedLocation'),
        position: location,
        infoWindow: InfoWindow(title: 'Searched Location'),
      ));
    });
  }

  void _addToFavorites() {
    // Get the last searched location (for simplicity, using fixed coords)
    LatLng location = LatLng(37.7749, -122.4194);
    setState(() {
      _favoriteLocations.add({"latitude": location.latitude, "longitude": location.longitude});
      _favoriteMarkers.add(Marker(
        markerId: MarkerId("${location.latitude},${location.longitude}"),
        position: location,
        infoWindow: InfoWindow(title: 'Favorite Location'),
      ));
    });
    prefs.setStringList(
        'favorites',
        _favoriteLocations
            .map((loc) => "${loc['latitude']},${loc['longitude']}")
            .toList());
  }

  void _onDrawerItemTapped(Map<String, double> location) {
    mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(location['latitude']!, location['longitude']!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Map with Favorites')),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(child: Text('Favorite Locations')),
            ..._favoriteLocations.map((location) {
              return ListTile(
                title: Text(
                    'Lat: ${location['latitude']} | Lng: ${location['longitude']}'),
                onTap: () => _onDrawerItemTapped(location),
              );
            }).toList(),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _onSearch,
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194), // Default: San Francisco
                zoom: 10,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: _markers.union(_favoriteMarkers),
            ),
          ),
          ElevatedButton(
            onPressed: _addToFavorites,
            child: Text('Add to Favorites'),
          ),
        ],
      ),
    );
  }
}