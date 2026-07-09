import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
	const SplashScreen({super.key});

	@override
	State<SplashScreen> createState() => _SplashScreenState();
	}


class _SplashScreenState extends State<SplashScreen> {
	@override
	void initState() {
		super.initState();
		Timer(const Duration(seconds: 2), () {
			if (!mounted) {
				return;
			}
			Navigator.of(context).pushReplacement(
				MaterialPageRoute(builder: (_) => const LoginScreen()),
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: LayoutBuilder(
					builder: (context, constraints) {
						return ClipRect(
							child: FittedBox(
								fit: BoxFit.contain,
								alignment: Alignment.center,
								child: SizedBox(
									width: 390,
									height: 844,
									child: Container(
										decoration: const BoxDecoration(
											gradient: RadialGradient(
												center: Alignment(0.0, -0.2),
												radius: 1.1,
												colors: [
													Color(0xff0d6b52),
													AppColors.primaryGreen,
													Color(0xff022b22),
												],
												stops: [0.0, 0.55, 1.0],
											),
										),
												return AnnotatedRegion<SystemUiOverlayStyle>(
													value: const SystemUiOverlayStyle(
														statusBarColor: Colors.transparent,
														statusBarIconBrightness: Brightness.light,
														statusBarBrightness: Brightness.dark,
													),
													child: Scaffold(
														body: LayoutBuilder(
															builder: (context, constraints) {
																final double width = constraints.maxWidth;
																final double height = constraints.maxHeight;

																return Stack(
																	fit: StackFit.expand,
																	children: [
																		Container(
																			decoration: const BoxDecoration(
																				gradient: RadialGradient(
																					center: Alignment(0.0, -0.2),
																					radius: 1.1,
																					colors: [
																						Color(0xff0d6b52),
																						AppColors.primaryGreen,
																						Color(0xff022b22),
																					],
																					stops: [0.0, 0.55, 1.0],
																				),
																			),
																		),
																		Positioned.fill(
																			child: Opacity(
																				opacity: 0.08,
																				child: Image.asset(
																					'lib/assets/images/Mosque Skyline.jpg',
																					fit: BoxFit.cover,
																					alignment: Alignment.center,
																				),
																			),
																		),
																		Positioned.fill(
																			child: Container(
																				decoration: const BoxDecoration(
																					gradient: LinearGradient(
																						begin: Alignment.topCenter,
																						end: Alignment.bottomCenter,
																						colors: [
																							Colors.transparent,
																							Colors.transparent,
																							Color.fromRGBO(0, 0, 0, 0.22),
																						],
																						stops: [0.0, 0.7, 1.0],
																					),
																				),
																		),
																		Column(
																			children: [
																				SizedBox(height: height * 0.08),
																				Center(
																					child: Column(
																						mainAxisSize: MainAxisSize.min,
																						children: [
																							Image.asset(
																								'lib/assets/images/nikah_link_icon.png',
																								width: width * 0.30,
																								height: width * 0.30,
																							),
																							SizedBox(height: height * 0.02),
																							RichText(
																								text: TextSpan(
																									children: [
																										const TextSpan(
																											text: 'Nikah ',
																											style: TextStyle(
																												fontSize: 42,
																												fontWeight: FontWeight.w700,
																												color: Colors.white,
																												letterSpacing: -1,
																											),
																										),
																										TextSpan(
																											text: 'Link',
																											style: TextStyle(
																												fontSize: 42,
																												fontWeight: FontWeight.w700,
																												color: AppColors.gold,
																												letterSpacing: -1,
																											),
																										),
																									],
																								),
																							),
																							SizedBox(height: height * 0.012),
																							Row(
																								mainAxisAlignment: MainAxisAlignment.center,
																								children: [
																									Container(width: width * 0.08, height: 1.5, color: const Color.fromRGBO(200, 155, 36, 0.85)),
																									SizedBox(width: width * 0.02),
																									const Text(
																										'Halal Connections. Lifelong Commitment.',
																										style: TextStyle(
																											color: Colors.white,
																											fontSize: 13,
																											fontWeight: FontWeight.w400,
																										),
																									),
																									SizedBox(width: width * 0.02),
																									Container(width: width * 0.08, height: 1.5, color: const Color.fromRGBO(200, 155, 36, 0.85)),
																								],
																							),
																						],
																					),
																				),
																				const Spacer(flex: 2),
																				Align(
																					alignment: Alignment.bottomCenter,
																					child: Column(
																						mainAxisSize: MainAxisSize.min,
																						children: [
																							Padding(
																								padding: EdgeInsets.symmetric(horizontal: width * 0.05),
																								child: Image.asset(
																									'lib/assets/images/Masjid.png',
																									fit: BoxFit.fitWidth,
																									width: double.infinity,
																									opacity: const AlwaysStoppedAnimation(0.92),
																								),
																							),
																							SizedBox(height: height * 0.015),
																							const Icon(Icons.favorite, color: AppColors.gold, size: 18),
																							const SizedBox(height: 8),
																							const Text(
																								'Connecting hearts.',
																								style: TextStyle(
																									color: Colors.white,
																									fontSize: 16,
																									fontWeight: FontWeight.w400,
																								),
																							),
																							const SizedBox(height: 2),
																							Text(
																								'Building halal marriages.',
																								style: TextStyle(
																									color: AppColors.gold,
																									fontSize: 16,
																									fontWeight: FontWeight.w700,
																								),
																							),
																							SizedBox(height: height * 0.015),
																							Row(
																								mainAxisAlignment: MainAxisAlignment.center,
																								children: [
																									Container(
																										width: width * 0.08,
																										height: 3,
																										decoration: BoxDecoration(
																											color: const Color.fromRGBO(1, 68, 51, 0.9),
																											borderRadius: BorderRadius.circular(999),
																										),
																									),
																									SizedBox(width: width * 0.02),
																									Container(
																										width: width * 0.09,
																										height: 3,
																										decoration: BoxDecoration(
																											color: AppColors.gold,
																											borderRadius: BorderRadius.circular(999),
																										),
																									),
																									SizedBox(width: width * 0.02),
																									Container(
																										width: width * 0.08,
																										height: 3,
																										decoration: BoxDecoration(
																											color: const Color.fromRGBO(255, 255, 255, 0.35),
																											borderRadius: BorderRadius.circular(999),
																										),
																									),
																								],
																							),
																							SizedBox(height: height * 0.015),
																						],
																					),
																				),
																			],
																		),
																	],
																);
															},
														),
													),
												);