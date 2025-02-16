import 'package:flutter/material.dart';
import 'package:startup_app/common/styles/spacing_styles.dart';

import '../../../utils/constants/sizes.dart';
import '../../../utils/constants/texts.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.title, required this.subTitle, required this.onPressed});

  final String title,subTitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHeight(context) * 2,
          child: Column(
            children: [
              ///Title & SubTitle
              Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center,),
              SizedBox(height: TSizes.spaceBtwItems(context)),
              Text(subTitle, style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.center,),
              SizedBox(height: TSizes.spaceBtwSections(context)),
              ///Buttons
              ///
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: onPressed, child: const Text(TTexts.tContinue))), // TODO Implement on pressed

            ],
          ),
        ),
      ),
    );
  }
}
