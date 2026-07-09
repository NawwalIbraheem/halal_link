import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';


void main(){

runApp(
NikahLinkApp()
);

}



class NikahLinkApp extends StatelessWidget{

	const NikahLinkApp({super.key});


@override
Widget build(BuildContext context){


return MaterialApp(

debugShowCheckedModeBanner:false,


title:"Nikah Link",


theme:ThemeData(

fontFamily:"Poppins",

),


		home:SplashScreen(),


);


}


}