import 'package:timeago/timeago.dart' as timeago;

class Time{
   static String timeToPeriod(String? currentTime) {
     if(currentTime == null){
       return '';
     }
     final current =  DateTime.parse(currentTime);
     return timeago.format(current);

   }
}