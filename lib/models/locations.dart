class Location {
  String latitude;
  String longitude;
  String timestamp;
  String? title = '';
  Location({required this.latitude, required this.longitude, required this.timestamp, this.title});
}