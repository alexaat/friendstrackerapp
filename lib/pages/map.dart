import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:friendstrackerapp/models/user.dart';

class Map extends StatefulWidget {
  final User friend;
  const Map(this.friend, {super.key});
  @override
  State<Map> createState() => _MapState();
}
class _MapState extends State<Map> {
  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();
  static const CameraPosition cameraPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  final Set<Marker> _markers = {};
  void createMarker(){
    final loc = widget.friend.location;
    Marker marker = Marker(
        markerId: MarkerId(widget.friend.id.toString()),
        position: LatLng(double.parse(loc!.latitude), double.parse(loc.longitude)),
        infoWindow: InfoWindow(title: loc.title ?? '${loc.latitude}, ${loc.latitude}')
    );
    setState(() {
      _markers.add(marker);
    });
    CameraPosition newCameraPosition = CameraPosition(
      target: LatLng(double.parse(loc.latitude),  double.parse(loc.longitude)),
      zoom: 15,
    );
    _controller.future.then((controller) => controller.animateCamera(CameraUpdate.newCameraPosition(newCameraPosition)));
  }
  @override
  Widget build(BuildContext context) {
    createMarker();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade600,
        title: Text(widget.friend.name ?? 'Map'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: cameraPosition,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: _markers,
      ),
    );
  }
}