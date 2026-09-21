/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class ServiceCatalog implements _i1.SerializableModel {
  ServiceCatalog._({
    this.id,
    required this.serviceType,
    required this.provider,
    required this.variationCode,
    required this.name,
    required this.costPrice,
    required this.defaultMarkup,
    required this.active,
  });

  factory ServiceCatalog({
    int? id,
    required String serviceType,
    required String provider,
    required String variationCode,
    required String name,
    required double costPrice,
    required double defaultMarkup,
    required bool active,
  }) = _ServiceCatalogImpl;

  factory ServiceCatalog.fromJson(Map<String, dynamic> jsonSerialization) {
    return ServiceCatalog(
      id: jsonSerialization['id'] as int?,
      serviceType: jsonSerialization['serviceType'] as String,
      provider: jsonSerialization['provider'] as String,
      variationCode: jsonSerialization['variationCode'] as String,
      name: jsonSerialization['name'] as String,
      costPrice: (jsonSerialization['costPrice'] as num).toDouble(),
      defaultMarkup: (jsonSerialization['defaultMarkup'] as num).toDouble(),
      active: _i1.BoolJsonExtension.fromJson(jsonSerialization['active']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String serviceType;

  String provider;

  String variationCode;

  String name;

  double costPrice;

  double defaultMarkup;

  bool active;

  /// Returns a shallow copy of this [ServiceCatalog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ServiceCatalog copyWith({
    int? id,
    String? serviceType,
    String? provider,
    String? variationCode,
    String? name,
    double? costPrice,
    double? defaultMarkup,
    bool? active,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ServiceCatalog',
      if (id != null) 'id': id,
      'serviceType': serviceType,
      'provider': provider,
      'variationCode': variationCode,
      'name': name,
      'costPrice': costPrice,
      'defaultMarkup': defaultMarkup,
      'active': active,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ServiceCatalogImpl extends ServiceCatalog {
  _ServiceCatalogImpl({
    int? id,
    required String serviceType,
    required String provider,
    required String variationCode,
    required String name,
    required double costPrice,
    required double defaultMarkup,
    required bool active,
  }) : super._(
         id: id,
         serviceType: serviceType,
         provider: provider,
         variationCode: variationCode,
         name: name,
         costPrice: costPrice,
         defaultMarkup: defaultMarkup,
         active: active,
       );

  /// Returns a shallow copy of this [ServiceCatalog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ServiceCatalog copyWith({
    Object? id = _Undefined,
    String? serviceType,
    String? provider,
    String? variationCode,
    String? name,
    double? costPrice,
    double? defaultMarkup,
    bool? active,
  }) {
    return ServiceCatalog(
      id: id is int? ? id : this.id,
      serviceType: serviceType ?? this.serviceType,
      provider: provider ?? this.provider,
      variationCode: variationCode ?? this.variationCode,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      defaultMarkup: defaultMarkup ?? this.defaultMarkup,
      active: active ?? this.active,
    );
  }
}
