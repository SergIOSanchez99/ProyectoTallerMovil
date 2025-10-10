import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? elevation;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacingXL),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.borderRadiusL,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.grey.withOpacity(0.1),
                spreadRadius: AppDimensions.shadowSpread,
                blurRadius: AppDimensions.shadowBlur,
                offset: const Offset(0, AppDimensions.shadowOffset),
              ),
            ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.lightBlue,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadiusM),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: AppDimensions.iconSizeL,
              color: iconColor ?? AppColors.primaryBlue,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontSizeM,
                fontWeight: FontWeight.normal,
                color: AppColors.primaryBlue,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}












