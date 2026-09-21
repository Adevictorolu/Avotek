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

import 'package:serverpod/serverpod.dart' as _i1;

abstract class ServiceCatalog
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = ServiceCatalogTable();

  static const db = ServiceCatalogRepository._();

  @override
  int? id;

  String serviceType;

  String provider;

  String variationCode;

  String name;

  double costPrice;

  double defaultMarkup;

  bool active;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static ServiceCatalogInclude include() {
    return ServiceCatalogInclude._();
  }

  static ServiceCatalogIncludeList includeList({
    _i1.WhereExpressionBuilder<ServiceCatalogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ServiceCatalogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ServiceCatalogTable>? orderByList,
    ServiceCatalogInclude? include,
  }) {
    return ServiceCatalogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ServiceCatalog.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(ServiceCatalog.t),
      include: include,
    );
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

class ServiceCatalogUpdateTable extends _i1.UpdateTable<ServiceCatalogTable> {
  ServiceCatalogUpdateTable(super.table);

  _i1.ColumnValue<String, String> serviceType(String value) => _i1.ColumnValue(
    table.serviceType,
    value,
  );

  _i1.ColumnValue<String, String> provider(String value) => _i1.ColumnValue(
    table.provider,
    value,
  );

  _i1.ColumnValue<String, String> variationCode(String value) =>
      _i1.ColumnValue(
        table.variationCode,
        value,
      );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<double, double> costPrice(double value) => _i1.ColumnValue(
    table.costPrice,
    value,
  );

  _i1.ColumnValue<double, double> defaultMarkup(double value) =>
      _i1.ColumnValue(
        table.defaultMarkup,
        value,
      );

  _i1.ColumnValue<bool, bool> active(bool value) => _i1.ColumnValue(
    table.active,
    value,
  );
}

class ServiceCatalogTable extends _i1.Table<int?> {
  ServiceCatalogTable({super.tableRelation})
    : super(tableName: 'service_catalog') {
    updateTable = ServiceCatalogUpdateTable(this);
    serviceType = _i1.ColumnString(
      'serviceType',
      this,
    );
    provider = _i1.ColumnString(
      'provider',
      this,
    );
    variationCode = _i1.ColumnString(
      'variationCode',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    costPrice = _i1.ColumnDouble(
      'costPrice',
      this,
    );
    defaultMarkup = _i1.ColumnDouble(
      'defaultMarkup',
      this,
    );
    active = _i1.ColumnBool(
      'active',
      this,
    );
  }

  late final ServiceCatalogUpdateTable updateTable;

  late final _i1.ColumnString serviceType;

  late final _i1.ColumnString provider;

  late final _i1.ColumnString variationCode;

  late final _i1.ColumnString name;

  late final _i1.ColumnDouble costPrice;

  late final _i1.ColumnDouble defaultMarkup;

  late final _i1.ColumnBool active;

  @override
  List<_i1.Column> get columns => [
    id,
    serviceType,
    provider,
    variationCode,
    name,
    costPrice,
    defaultMarkup,
    active,
  ];
}

class ServiceCatalogInclude extends _i1.IncludeObject {
  ServiceCatalogInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => ServiceCatalog.t;
}

class ServiceCatalogIncludeList extends _i1.IncludeList {
  ServiceCatalogIncludeList._({
    _i1.WhereExpressionBuilder<ServiceCatalogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(ServiceCatalog.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => ServiceCatalog.t;
}

class ServiceCatalogRepository {
  const ServiceCatalogRepository._();

  /// Returns a list of [ServiceCatalog]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<ServiceCatalog>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ServiceCatalogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ServiceCatalogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ServiceCatalogTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<ServiceCatalog>(
      where: where?.call(ServiceCatalog.t),
      orderBy: orderBy?.call(ServiceCatalog.t),
      orderByList: orderByList?.call(ServiceCatalog.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [ServiceCatalog] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<ServiceCatalog?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ServiceCatalogTable>? where,
    int? offset,
    _i1.OrderByBuilder<ServiceCatalogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<ServiceCatalogTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<ServiceCatalog>(
      where: where?.call(ServiceCatalog.t),
      orderBy: orderBy?.call(ServiceCatalog.t),
      orderByList: orderByList?.call(ServiceCatalog.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [ServiceCatalog] by its [id] or null if no such row exists.
  Future<ServiceCatalog?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<ServiceCatalog>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [ServiceCatalog]s in the list and returns the inserted rows.
  ///
  /// The returned [ServiceCatalog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<ServiceCatalog>> insert(
    _i1.DatabaseSession session,
    List<ServiceCatalog> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<ServiceCatalog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [ServiceCatalog] and returns the inserted row.
  ///
  /// The returned [ServiceCatalog] will have its `id` field set.
  Future<ServiceCatalog> insertRow(
    _i1.DatabaseSession session,
    ServiceCatalog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<ServiceCatalog>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [ServiceCatalog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<ServiceCatalog>> update(
    _i1.DatabaseSession session,
    List<ServiceCatalog> rows, {
    _i1.ColumnSelections<ServiceCatalogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<ServiceCatalog>(
      rows,
      columns: columns?.call(ServiceCatalog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ServiceCatalog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<ServiceCatalog> updateRow(
    _i1.DatabaseSession session,
    ServiceCatalog row, {
    _i1.ColumnSelections<ServiceCatalogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<ServiceCatalog>(
      row,
      columns: columns?.call(ServiceCatalog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [ServiceCatalog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<ServiceCatalog?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<ServiceCatalogUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<ServiceCatalog>(
      id,
      columnValues: columnValues(ServiceCatalog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [ServiceCatalog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<ServiceCatalog>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<ServiceCatalogUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<ServiceCatalogTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<ServiceCatalogTable>? orderBy,
    _i1.OrderByListBuilder<ServiceCatalogTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<ServiceCatalog>(
      columnValues: columnValues(ServiceCatalog.t.updateTable),
      where: where(ServiceCatalog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(ServiceCatalog.t),
      orderByList: orderByList?.call(ServiceCatalog.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [ServiceCatalog]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<ServiceCatalog>> delete(
    _i1.DatabaseSession session,
    List<ServiceCatalog> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<ServiceCatalog>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [ServiceCatalog].
  Future<ServiceCatalog> deleteRow(
    _i1.DatabaseSession session,
    ServiceCatalog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<ServiceCatalog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<ServiceCatalog>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ServiceCatalogTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<ServiceCatalog>(
      where: where(ServiceCatalog.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<ServiceCatalogTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<ServiceCatalog>(
      where: where?.call(ServiceCatalog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [ServiceCatalog] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<ServiceCatalogTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<ServiceCatalog>(
      where: where(ServiceCatalog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
