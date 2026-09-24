import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_tokens.dart';
import '../../modules/business_type.dart';
import '../../providers/business_provider.dart';
import '../business_setup/business_setup_wizard_screen.dart';
import '../main_layout_screen.dart';

/// Sector (business domain) selection screen.
///
/// Shown right after the splash screen. The layout is fully responsive:
/// phones get a single-column list, large phones / tablets in portrait get
/// two columns, and tablets in landscape, laptops and desktops get three
/// columns with a hero header.
class SectorSelectionScreen extends StatelessWidget {
  const SectorSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bizProv = context.watch<BusinessProvider>();
    final businesses = bizProv.businesses;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= AppTokens.breakpointTablet;

            // Column count adapts to available width.
            int crossAxisCount = 1;
            if (width >= 1100) {
              crossAxisCount = 3;
            } else if (width >= 640) {
              crossAxisCount = 2;
            }

            final horizontalPadding =
                (width * 0.05).clamp(16.0, isDesktop ? 48.0 : 20.0);
            final gridSpacing = horizontalPadding * 0.5;

            // Derive each card's height from its actual width so cards stay
            // well proportioned at every breakpoint instead of stretching.
            final cardWidth = (width -
                    horizontalPadding * 2 -
                    gridSpacing * (crossAxisCount - 1)) /
                crossAxisCount;
            final cardHeight = (cardWidth * 0.26).clamp(112.0, 156.0);
            final cardAspectRatio = cardWidth / cardHeight;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(width: width, horizontalPadding: horizontalPadding),
                Expanded(
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      width * 0.015,
                      horizontalPadding,
                      width * 0.04,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
                      childAspectRatio: cardAspectRatio,
                    ),
                    itemCount: BusinessType.values.length,
                    itemBuilder: (context, index) {
                      final type = BusinessType.values[index];
                      final existing =
                          businesses.where((b) => b.type == type).toList();
                      final hasExisting = existing.isNotEmpty;

                      return _SectorCard(
                        type: type,
                        hasExisting: hasExisting,
                        existingName:
                            hasExisting ? existing.first.name : '',
                        onTap: () async {
                          if (hasExisting) {
                            await bizProv.switchBusiness(existing.first);
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainLayoutScreen(),
                                ),
                                (route) => false,
                              );
                            }
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BusinessSetupWizardScreen(
                                    initialType: type),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Hero header for the sector picker.
class _Header extends StatelessWidget {
  final double width;
  final double horizontalPadding;

  const _Header({
    required this.width,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        width * 0.028,
        horizontalPadding,
        width * 0.022,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withAlpha(20),
            theme.colorScheme.secondary.withAlpha(10),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.011),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppTokens.borderMD,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(70),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: (width * 0.028).clamp(17.0, 23.0),
                ),
              ),
              SizedBox(width: width * 0.016),
              Expanded(
                child: Text(
                  'Choose Your Sector',
                  style: TextStyle(
                    fontSize: (width * 0.05).clamp(21.0, 32.0),
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.012),
          Text(
            'OminiPOS adapts its catalog, navigation and billing rules to the '
            'sector you pick. Switch sectors anytime from Settings.',
            style: TextStyle(
              fontSize: (width * 0.029).clamp(12.0, 15.0),
              color: theme.colorScheme.onSurface.withAlpha(165),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single selectable sector card.
class _SectorCard extends StatefulWidget {
  final BusinessType type;
  final bool hasExisting;
  final String existingName;
  final VoidCallback onTap;

  const _SectorCard({
    required this.type,
    required this.hasExisting,
    required this.existingName,
    required this.onTap,
  });

  @override
  State<_SectorCard> createState() => _SectorCardState();
}

class _SectorCardState extends State<_SectorCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final type = widget.type;
    final primaryColor = type.primaryColor;

    final iconTile = (width * 0.085).clamp(46.0, 58.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppTokens.durationNormal,
        transform: Transform.translate(
          offset: Offset(0, _isHovered ? -3.0 : 0.0),
        ).transform,
        child: Material(
          color: theme.cardTheme.color,
          borderRadius: AppTokens.borderLG,
          elevation: _isHovered ? 4 : 0,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: AppTokens.borderLG,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AppTokens.borderLG,
                border: Border.all(
                  color: widget.hasExisting
                      ? primaryColor.withAlpha(_isHovered ? 200 : 130)
                      : (_isHovered
                          ? primaryColor.withAlpha(160)
                          : theme.dividerColor),
                  width: widget.hasExisting ? 1.6 : 1.2,
                ),
              ),
              padding: EdgeInsets.all(width * 0.024),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sector icon tile with tinted background
                  Container(
                    width: iconTile,
                    height: iconTile,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withAlpha(38),
                          primaryColor.withAlpha(16),
                        ],
                      ),
                      borderRadius: AppTokens.borderMD,
                    ),
                    child: Icon(
                      type.icon,
                      color: primaryColor,
                      size: iconTile * 0.5,
                    ),
                  ),
                  SizedBox(width: width * 0.022),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          type.shortName,
                          style: TextStyle(
                            fontSize: (width * 0.034).clamp(15.0, 18.0),
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: width * 0.006),
                        Text(
                          widget.hasExisting
                              ? widget.existingName
                              : type.tagLine,
                          style: TextStyle(
                            fontSize: (width * 0.026).clamp(11.0, 13.0),
                            color: theme.colorScheme.onSurface.withAlpha(160),
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Trailing status chip / arrow
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: widget.hasExisting
                        ? BoxDecoration(
                            color: primaryColor.withAlpha(24),
                            borderRadius: AppTokens.borderPill,
                          )
                        : null,
                    child: widget.hasExisting
                        ? Text(
                            'READY',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: (width * 0.022).clamp(9.5, 11.0),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.7,
                            ),
                          )
                        : Icon(
                            Icons.arrow_forward_rounded,
                            color: primaryColor.withAlpha(190),
                            size: (width * 0.03).clamp(16.0, 20.0),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
