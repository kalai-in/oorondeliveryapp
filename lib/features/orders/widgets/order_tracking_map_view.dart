import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:deliveryboy/commons/widgets/app_png_icon.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/core/configs/app_config.dart';
import 'package:deliveryboy/core/constants/app_constants.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/road_route_cubit.dart';
import 'package:deliveryboy/features/orders/widgets/order_tracking_info_card.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_radius.dart';

class OrderTrackingMapView extends StatefulWidget {
  final bool isGoogle;
  final MapController mapController;
  final ValueChanged<gmap.GoogleMapController> onGoogleMapCreated;
  final LatLng destinationLatLng;
  final LatLng? currentLatLng;
  final String orderId;
  final String customerName;
  final String customerNumber;
  final String? customerAlternateNumber;
  final String address;
  final VoidCallback? onChatCustomer;
  final VoidCallback onRecenter;

  const OrderTrackingMapView({
    super.key,
    required this.isGoogle,
    required this.mapController,
    required this.onGoogleMapCreated,
    required this.destinationLatLng,
    this.currentLatLng,
    required this.orderId,
    required this.customerName,
    required this.customerNumber,
    this.customerAlternateNumber,
    required this.address,
    required this.onChatCustomer,
    required this.onRecenter,
  });

  @override
  State<OrderTrackingMapView> createState() => _OrderTrackingMapViewState();
}

class _OrderTrackingMapViewState extends State<OrderTrackingMapView> {
  gmap.BitmapDescriptor? _deliveryBoyIcon;
  gmap.BitmapDescriptor? _destinationIcon;
  gmap.GoogleMapController? _googleController;

  /// Fit-both-points runs once, the first time the delivery boy's own
  /// location is available, so the opening frame already frames boy +
  /// destination. Left alone after that so it never fights the user's own
  /// zoom/pan.
  bool _hasFittedBounds = false;

  /// Space reserved at the bottom for [OrderTrackingInfoCard], mirroring the
  /// existing recenter-button offset (bottom: 220) used elsewhere in this
  /// screen, so a fitted marker never lands underneath the card.
  static const double _bottomCardReserve = 260;

  /// Road-snapped route points from OSRM's free public routing server, used
  /// only for the OSM (flutter_map) tracking view so the line follows actual
  /// roads instead of cutting straight through buildings. The Google view
  /// never fetches this and always shows the direct 2-point line.
  List<LatLng>? _routePoints;

  /// Location the current route was fetched from, so minor GPS jitter
  /// doesn't re-hit the routing server on every location update.
  LatLng? _routedFrom;

  /// Minimum movement (metres) before re-fetching the road route.
  static const double _routeRefreshMeters = 30;

  StreamSubscription<RoadRouteState>? _routeSub;

  @override
  void initState() {
    super.initState();
    if (widget.isGoogle) {
      _loadDeliveryBoyIcon();
      _loadDestinationIcon();
    }
    _routeSub = context.read<RoadRouteCubit>().stream.listen((state) {
      if (state is RoadRouteLoaded && state.points != null && mounted) {
        setState(() => _routePoints = state.points);
      }
    });
    final current = widget.currentLatLng;
    if (current != null) {
      _maybeFetchRoute(current);
    }
  }

  @override
  void dispose() {
    _routeSub?.cancel();
    super.dispose();
  }

  /// Re-fetches the road route only if the delivery boy moved far enough
  /// since the last fetch, so the free OSRM demo server isn't hammered on
  /// every GPS tick. Google view skips OSRM entirely and uses the direct
  /// line — no third-party routing dependency needed on that provider.
  void _maybeFetchRoute(LatLng current) {
    if (widget.isGoogle) return;
    final routedFrom = _routedFrom;
    if (routedFrom != null &&
        Geolocator.distanceBetween(
              routedFrom.latitude,
              routedFrom.longitude,
              current.latitude,
              current.longitude,
            ) <
            _routeRefreshMeters) {
      return;
    }
    _routedFrom = current;
    context.read<RoadRouteCubit>().fetchRoute(current, widget.destinationLatLng);
  }

  /// Road-snapped points when available, else the direct line as fallback.
  List<LatLng> _polylinePoints(LatLng current) =>
      _routePoints ?? [current, widget.destinationLatLng];

  Future<void> _loadDeliveryBoyIcon() async {
    final icon = await gmap.BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(40, 40)),
      AssetsConstants.deliveryBoyTrackingIcon,
    );
    if (mounted) {
      setState(() => _deliveryBoyIcon = icon);
    }
  }

  /// Rasterizes the destination SVG into a [gmap.BitmapDescriptor], since
  /// Google Maps markers only accept raster images and can't render SVG
  /// directly the way [AppSvgIcon] does for the OSM view.
  Future<void> _loadDestinationIcon() async {
    const size = 40.0;
    final pictureInfo = await vg.loadPicture(
      SvgAssetLoader(AssetsConstants.destinationLocationIcon),
      null,
    );
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scale = size / pictureInfo.size.width;
    canvas.scale(scale);
    canvas.drawPicture(pictureInfo.picture);
    final image = await recorder.endRecording().toImage(
      size.toInt(),
      (size * pictureInfo.size.height / pictureInfo.size.width).toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    pictureInfo.picture.dispose();
    if (bytes == null || !mounted) return;
    setState(
      () => _destinationIcon = gmap.BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant OrderTrackingMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasFittedBounds &&
        oldWidget.currentLatLng == null &&
        widget.currentLatLng != null) {
      _fitBounds();
    }
    final current = widget.currentLatLng;
    if (current != null) {
      _maybeFetchRoute(current);
    }
  }

  /// Frames both the delivery boy and the destination on screen together,
  /// clear of the bottom info card.
  void _fitBounds() {
    final current = widget.currentLatLng;
    if (current == null) return;
    _hasFittedBounds = true;
    if (widget.isGoogle) {
      _googleController?.moveCamera(_googleBoundsUpdate(current));
    } else {
      widget.mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(current, widget.destinationLatLng),
          padding: const EdgeInsets.only(
            top: 60,
            left: 60,
            right: 60,
            bottom: _bottomCardReserve,
          ),
        ),
      );
    }
  }

  gmap.CameraUpdate _googleBoundsUpdate(LatLng current) {
    final destination = widget.destinationLatLng;
    final south = math.min(current.latitude, destination.latitude);
    final north = math.max(current.latitude, destination.latitude);
    final west = math.min(current.longitude, destination.longitude);
    final east = math.max(current.longitude, destination.longitude);
    return gmap.CameraUpdate.newLatLngBounds(
      gmap.LatLngBounds(
        southwest: gmap.LatLng(south, west),
        northeast: gmap.LatLng(north, east),
      ),
      60,
    );
  }

  /// Compass bearing (degrees, 0-360) from [from] to [to], used to point the
  /// delivery-boy icon along the tracking line toward the destination.
  double _bearingDegrees(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLon) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  Widget _buildFlutterMap(BuildContext context) {
    final current = widget.currentLatLng;
    return FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        initialCenter: widget.destinationLatLng,
        initialZoom: 17,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onMapReady: () {
          if (current != null) {
            _fitBounds();
          } else {
            widget.mapController.move(widget.destinationLatLng, 17);
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.osmMapRenderUrl,
          userAgentPackageName: AppConfig.appPackageName,
          subdomains: AppConstants.mapTileSubdomains,
        ),
        if (current != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _polylinePoints(current),
                strokeWidth: 3.5,
                color: context.cs.primary,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.destinationLatLng,
              width: 40,
              height: 48,
              rotate: true,
              alignment: Alignment.topCenter,
              child: AppSvgIcon(
                AssetsConstants.destinationLocationIcon,
                size: 40,
              ),
            ),
            if (current != null)
              Marker(
                point: current,
                width: 40,
                height: 40,
                child: Transform.rotate(
                  angle:
                      _bearingDegrees(current, widget.destinationLatLng) *
                      math.pi /
                      180,
                  child: AppPngIcon(
                    AssetsConstants.deliveryBoyTrackingIcon,
                    size: 40,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    final current = widget.currentLatLng;
    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: gmap.LatLng(
          widget.destinationLatLng.latitude,
          widget.destinationLatLng.longitude,
        ),
        zoom: 17,
      ),
      onMapCreated: (controller) {
        widget.onGoogleMapCreated(controller);
        _googleController = controller;
        if (current != null) {
          _fitBounds();
        } else {
          controller.moveCamera(
            gmap.CameraUpdate.newLatLngZoom(
              gmap.LatLng(
                widget.destinationLatLng.latitude,
                widget.destinationLatLng.longitude,
              ),
              17,
            ),
          );
        }
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      padding: const EdgeInsets.only(bottom: _bottomCardReserve),
      markers: {
        gmap.Marker(
          markerId: const gmap.MarkerId('destination'),
          position: gmap.LatLng(
            widget.destinationLatLng.latitude,
            widget.destinationLatLng.longitude,
          ),
          infoWindow: gmap.InfoWindow(
            title: '${AppConstants.hashSymbol}${widget.orderId}',
          ),
          anchor: const Offset(0.5, 1),
          icon: _destinationIcon ?? gmap.BitmapDescriptor.defaultMarker,
        ),
        if (current != null)
          gmap.Marker(
            markerId: const gmap.MarkerId('current'),
            position: gmap.LatLng(current.latitude, current.longitude),
            rotation: _bearingDegrees(current, widget.destinationLatLng),
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon:
                _deliveryBoyIcon ??
                gmap.BitmapDescriptor.defaultMarkerWithHue(
                  gmap.BitmapDescriptor.hueAzure,
                ),
          ),
      },
      polylines: {
        if (current != null)
          gmap.Polyline(
            polylineId: const gmap.PolylineId('route'),
            points: _polylinePoints(current)
                .map((p) => gmap.LatLng(p.latitude, p.longitude))
                .toList(),
            color: context.cs.primary,
            width: 4,
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: CustomAppBar(
        title:
            '${context.translate(LanguageLabelKeys.trackOrder)} ${AppConstants.hashSymbol}${widget.orderId}',
      ),
      applyBottomInset: false,
      body: Stack(
        children: [
          widget.isGoogle ? _buildGoogleMap(context) : _buildFlutterMap(context),
          if (widget.currentLatLng != null)
            PositionedDirectional(
              end: 12,
              bottom: widget.customerAlternateNumber.isNotNullOrEmpty
                  ? 250
                  : 190,
              child: Material(
                color: context.cs.surface,
                borderRadius: AppRadius.r12,
                elevation: 4,
                shadowColor: context.cs.shadow,
                child: InkWell(
                  onTap: widget.onRecenter,
                  borderRadius: AppRadius.r12,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: AppSvgIcon(
                        AssetsConstants.enableLocationIcon,
                        color: context.cs.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: OrderTrackingInfoCard(
              customerName: widget.customerName,
              customerNumber: widget.customerNumber,
              customerAlternateNumber: widget.customerAlternateNumber,
              address: widget.address,
              onChatCustomer: widget.onChatCustomer,
            ),
          ),
        ],
      ),
    );
  }
}
