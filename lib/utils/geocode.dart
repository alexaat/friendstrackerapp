import 'package:geocoding/geocoding.dart';
class GeoCode {
  static void coordinatesToPlace(double latitude, double longitude, Function(Placemark placeMark) callback) async{
    List<Placemark> placeMarks = await placemarkFromCoordinates(latitude, longitude);
    callback(placeMarks.first);
  }
  static String parsePlace(Placemark placeMark){
    String place = '';
    if(placeMark.street != null && placeMark.street!.isNotEmpty) {
      place += placeMark.street!;
    }
    if(placeMark.subLocality != null && placeMark.subLocality!.isNotEmpty) {
      place += ', ';
      place += placeMark.subLocality!;
    }
    if(placeMark.locality != null && placeMark.locality!.isNotEmpty) {
      place += ', ';
      place += placeMark.locality!;
    }
    if(placeMark.subAdministrativeArea != null && placeMark.subAdministrativeArea!.isNotEmpty) {
      place += ', ';
      place += placeMark.subAdministrativeArea!;
    }
    if(placeMark.administrativeArea != null && placeMark.administrativeArea!.isNotEmpty) {
      place += ', ';
      place += placeMark.administrativeArea!;
    }
    return place;
  }
}

