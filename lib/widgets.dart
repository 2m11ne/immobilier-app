import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'models.dart';
import 'details_screen.dart';

void showMsg(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: kNavy,
    behavior: SnackBarBehavior.floating,
    shape: const RoundedRectangleBorder(),
  ));
}

String money(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

String formatTime(DateTime d) {
  final now = DateTime.now();
  if (d.year == now.year && d.month == now.month && d.day == now.day) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

Future<bool> confirmDialog(
    BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      title: Text(title,
          style: const TextStyle(color: kNavy, fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: kGrey))),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm', style: TextStyle(color: kTeal))),
      ],
    ),
  );
  return result ?? false;
}

class NetImg extends StatelessWidget {
  final String url;
  final BoxFit fit;
  const NetImg(this.url, {super.key, this.fit = BoxFit.cover});

  Widget _placeholder() => Container(
        color: kTealLight,
        child: const Center(child: Icon(Icons.apartment, color: kTeal)),
      );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: kTealLight,
          child: const Center(
              child: CircularProgressIndicator(color: kTeal, strokeWidth: 2)),
        );
      },
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }
}

class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final double radius;
  const Avatar({super.key, this.url, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(url!),
        backgroundColor: kTealLight,
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: kTeal,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.8,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

class TealButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double? width;
  final bool loading;
  final Color color;
  const TealButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width,
    this.loading = false,
    this.color = kTeal,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 40),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : Text(label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    const none = OutlineInputBorder(
        borderRadius: BorderRadius.zero, borderSide: BorderSide.none);
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: kNavy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: kGrey),
        prefixIcon: icon == null ? null : Icon(icon, color: kGrey),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: none,
        enabledBorder: none,
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: kTeal, width: 1.5)),
        errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: kRed)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.zero,
            borderSide: BorderSide(color: kRed, width: 1.5)),
      ),
    );
  }
}

class BackBtn extends StatelessWidget {
  const BackBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: kNavy, size: 22),
        onPressed: () => Navigator.maybePop(context),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  const PageHeader({super.key, required this.title, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      showBack ? const BackBtn() : const SizedBox(width: 46),
      Expanded(
        child: Center(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
        ),
      ),
      const SizedBox(width: 46),
    ]);
  }
}

class IconTile extends StatelessWidget {
  final IconData icon;
  final bool selected;
  const IconTile({super.key, required this.icon, this.selected = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        color: selected ? Colors.white.withAlpha(51) : kTealLight,
        child: Icon(icon, size: 18, color: selected ? Colors.white : kTeal),
      );
}

class SpecBox extends StatelessWidget {
  final IconData icon;
  final String label;
  const SpecBox({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconTile(icon: icon),
            FittedBox(
              child: Text(label,
                  style: const TextStyle(color: kGrey, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              color: kTealLight,
              child: Icon(icon, size: 36, color: kTeal),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kNavy)),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kGrey, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: kTeal),
        ),
      );
}

class PropertyCard extends StatefulWidget {
  final Property property;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const PropertyCard({
    super.key,
    required this.property,
    this.width = double.infinity,
    this.margin,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool isFavorite = false;
  bool loadingFav = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loadingFav = false);
      return;
    }
    try {
      final res = await Supabase.instance.client
          .from('favorites')
          .select()
          .eq('user_id', user.id)
          .eq('property_id', widget.property.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          isFavorite = res != null;
          loadingFav = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => loadingFav = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      showMsg(context, 'Please login to add to favorites.');
      return;
    }
    
    setState(() => isFavorite = !isFavorite);

    try {
      if (isFavorite) {
        await Supabase.instance.client
            .from('favorites')
            .insert({'user_id': user.id, 'property_id': widget.property.id});
        if (mounted) showMsg(context, 'Added to favorites ❤️');
      } else {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('property_id', widget.property.id);
        if (mounted) showMsg(context, 'Removed from favorites.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => isFavorite = !isFavorite);
        showMsg(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailsScreen(property: p))),
      child: Container(
        width: widget.width,
        margin: widget.margin ?? const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: NetImg(p.imageUrl),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: loadingFav
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: _toggleFavorite,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(220),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? kRed : kNavy,
                              size: 20,
                            ),
                          ),
                        ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700, color: kNavy)),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.square_foot, size: 16, color: kTeal),
                    const SizedBox(width: 6),
                    Text('${p.sqft} sqft', style: const TextStyle(color: kGrey)),
                    const SizedBox(width: 14),
                    const Icon(Icons.monetization_on_outlined,
                        size: 16, color: kTeal),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('${money(p.price)} TND/Month',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kGrey)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: kTeal),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(p.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: kGrey, fontSize: 13)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}