import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

/// Result of picking a location: lat, lng, and optional address parts.
class MapLocationResult {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? state;

  const MapLocationResult({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.state,
  });
}

/// Dialog to pick a location on a map with maximize/minimize and current location.
class MapLocationPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPickerDialog({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  static Future<MapLocationResult?> show(
    BuildContext context, {
    double? initialLat,
    double? initialLng,
  }) {
    return showDialog<MapLocationResult>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => MapLocationPickerDialog(
        initialLat: initialLat,
        initialLng: initialLng,
      ),
    );
  }

  @override
  State<MapLocationPickerDialog> createState() => _MapLocationPickerDialogState();
}

class _MapLocationPickerDialogState extends State<MapLocationPickerDialog> {
  final MapController _mapController = MapController();
  LatLng? _selected;
  bool _maximized = false;
  bool _loadingAddress = false;
  String? _addressText;
  String? _city;
  String? _state;
  String? _error;

  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selected = LatLng(widget.initialLat!, widget.initialLng!);
      _fetchAddress(_selected!);
    }
  }

  Future<void> _fetchAddress(LatLng point) async {
    setState(() {
      _loadingAddress = true;
      _error = null;
      _addressText = null;
      _city = null;
      _state = null;
    });
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));
      final res = await dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': point.latitude,
          'lon': point.longitude,
          'format': 'json',
          'addressdetails': 1,
        },
        options: Options(
          headers: {'User-Agent': 'BizzPass-CRM/1.0'},
        ),
      );
      if (!mounted) return;
      final data = res.data;
      String? address;
      String? city;
      String? state;
      if (data != null) {
        address = data['display_name'] as String?;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          city = (addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['municipality']) as String?;
          state = (addr['state'] ?? addr['county']) as String?;
        }
      }
      setState(() {
        _addressText = address;
        _city = city;
        _state = state;
        _loadingAddress = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingAddress = false;
          _error = 'Could not fetch address';
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _error = null);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        setState(() => _error = 'Location services disabled');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _error = 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final point = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() => _selected = point);
        _mapController.move(point, 15);
        _fetchAddress(point);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not get location');
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _selected = point);
    _fetchAddress(point);
  }

  void _confirm() {
    if (_selected == null) return;
    Navigator.of(context).pop(MapLocationResult(
      latitude: _selected!.latitude,
      longitude: _selected!.longitude,
      address: _addressText,
      city: _city,
      state: _state,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = _maximized ? size.width : (size.width * 0.9).clamp(320.0, 700.0);
    final height = _maximized ? size.height : (size.height * 0.6).clamp(300.0, 600.0);

    return Dialog(
      backgroundColor: context.cardColor,
      insetPadding: _maximized ? EdgeInsets.zero : const EdgeInsets.all(16),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Set location on map',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _maximized ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _maximized = !_maximized),
                    tooltip: _maximized ? 'Minimize' : 'Maximize',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Address / coords
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: context.dangerColor, fontSize: 12),
                ),
              ),
            if (_selected != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loadingAddress
                            ? 'Loading address…'
                            : (_addressText ?? '${_selected!.latitude.toStringAsFixed(5)}, ${_selected!.longitude.toStringAsFixed(5)}'),
                        style: TextStyle(fontSize: 12, color: context.textSecondaryColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, size: 18),
                      label: const Text('Use current'),
                    ),
                  ],
                ),
              ),
            // Map
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selected ?? _defaultCenter,
                    initialZoom: _selected != null ? 15 : 10,
                    onTap: _onMapTap,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.bizzpass.crm',
                    ),
                    if (_selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selected!,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on_rounded,
                              color: context.accentColor,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selected == null ? null : _confirm,
                    child: const Text('Use this location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
