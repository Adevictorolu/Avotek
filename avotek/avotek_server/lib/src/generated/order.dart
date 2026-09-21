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

abstract class Order implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Order._({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.networkProvider,
    required this.recipientIdentifier,
    required this.amount,
    required this.costPrice,
    required this.sellPrice,
    this.providerReference,
    required this.status,
    required this.channel,
    required this.idempotencyKey,
    this.metadata,
    required this.createdAt,
  });

  factory Order({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required double amount,
    required double costPrice,
    required double sellPrice,
    String? providerReference,
    required String status,
    required String channel,
    required String idempotencyKey,
    String? metadata,
    required DateTime createdAt,
  }) = _OrderImpl;

  factory Order.fromJson(Map<String, dynamic> jsonSerialization) {
    return Order(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      serviceType: jsonSerialization['serviceType'] as String,
      networkProvider: jsonSerialization['networkProvider'] as String,
      recipientIdentifier: jsonSerialization['recipientIdentifier'] as String,
      amount: (jsonSerialization['amount'] as num).toDouble(),
      costPrice: (jsonSerialization['costPrice'] as num).toDouble(),
      sellPrice: (jsonSerialization['sellPrice'] as num).toDouble(),
      providerReference: jsonSerialization['providerReference'] as String?,
      status: jsonSerialization['status'] as String,
      channel: jsonSerialization['channel'] as String,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      metadata: jsonSerialization['metadata'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = OrderTable();

  static const db = OrderRepository._();

  @override
  int? id;

  int userId;

  String serviceType;

  String networkProvider;

  String recipientIdentifier;

  double amount;

  double costPrice;

  double sellPrice;

  String? providerReference;

  String status;

  String channel;

  String idempotencyKey;

  String? metadata;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Order copyWith({
    int? id,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    double? amount,
    double? costPrice,
    double? sellPrice,
    String? providerReference,
    String? status,
    String? channel,
    String? idempotencyKey,
    String? metadata,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'amount': amount,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      if (providerReference != null) 'providerReference': providerReference,
      'status': status,
      'channel': channel,
      'idempotencyKey': idempotencyKey,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Order',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'amount': amount,
      'costPrice': costPrice,
      'sellPrice': sellPrice,
      if (providerReference != null) 'providerReference': providerReference,
      'status': status,
      'channel': channel,
      'idempotencyKey': idempotencyKey,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toJson(),
    };
  }

  static OrderInclude include() {
    return OrderInclude._();
  }

  static OrderIncludeList includeList({
    _i1.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OrderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrderTable>? orderByList,
    OrderInclude? include,
  }) {
    return OrderIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Order.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Order.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _OrderImpl extends Order {
  _OrderImpl({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required double amount,
    required double costPrice,
    required double sellPrice,
    String? providerReference,
    required String status,
    required String channel,
    required String idempotencyKey,
    String? metadata,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         serviceType: serviceType,
         networkProvider: networkProvider,
         recipientIdentifier: recipientIdentifier,
         amount: amount,
         costPrice: costPrice,
         sellPrice: sellPrice,
         providerReference: providerReference,
         status: status,
         channel: channel,
         idempotencyKey: idempotencyKey,
         metadata: metadata,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Order]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Order copyWith({
    Object? id = _Undefined,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    double? amount,
    double? costPrice,
    double? sellPrice,
    Object? providerReference = _Undefined,
    String? status,
    String? channel,
    String? idempotencyKey,
    Object? metadata = _Undefined,
    DateTime? createdAt,
  }) {
    return Order(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      networkProvider: networkProvider ?? this.networkProvider,
      recipientIdentifier: recipientIdentifier ?? this.recipientIdentifier,
      amount: amount ?? this.amount,
      costPrice: costPrice ?? this.costPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      providerReference: providerReference is String?
          ? providerReference
          : this.providerReference,
      status: status ?? this.status,
      channel: channel ?? this.channel,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      metadata: metadata is String? ? metadata : this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OrderUpdateTable extends _i1.UpdateTable<OrderTable> {
  OrderUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> serviceType(String value) => _i1.ColumnValue(
    table.serviceType,
    value,
  );

  _i1.ColumnValue<String, String> networkProvider(String value) =>
      _i1.ColumnValue(
        table.networkProvider,
        value,
      );

  _i1.ColumnValue<String, String> recipientIdentifier(String value) =>
      _i1.ColumnValue(
        table.recipientIdentifier,
        value,
      );

  _i1.ColumnValue<double, double> amount(double value) => _i1.ColumnValue(
    table.amount,
    value,
  );

  _i1.ColumnValue<double, double> costPrice(double value) => _i1.ColumnValue(
    table.costPrice,
    value,
  );

  _i1.ColumnValue<double, double> sellPrice(double value) => _i1.ColumnValue(
    table.sellPrice,
    value,
  );

  _i1.ColumnValue<String, String> providerReference(String? value) =>
      _i1.ColumnValue(
        table.providerReference,
        value,
      );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> channel(String value) => _i1.ColumnValue(
    table.channel,
    value,
  );

  _i1.ColumnValue<String, String> idempotencyKey(String value) =>
      _i1.ColumnValue(
        table.idempotencyKey,
        value,
      );

  _i1.ColumnValue<String, String> metadata(String? value) => _i1.ColumnValue(
    table.metadata,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class OrderTable extends _i1.Table<int?> {
  OrderTable({super.tableRelation}) : super(tableName: 'orders') {
    updateTable = OrderUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    serviceType = _i1.ColumnString(
      'serviceType',
      this,
    );
    networkProvider = _i1.ColumnString(
      'networkProvider',
      this,
    );
    recipientIdentifier = _i1.ColumnString(
      'recipientIdentifier',
      this,
    );
    amount = _i1.ColumnDouble(
      'amount',
      this,
    );
    costPrice = _i1.ColumnDouble(
      'costPrice',
      this,
    );
    sellPrice = _i1.ColumnDouble(
      'sellPrice',
      this,
    );
    providerReference = _i1.ColumnString(
      'providerReference',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    channel = _i1.ColumnString(
      'channel',
      this,
    );
    idempotencyKey = _i1.ColumnString(
      'idempotencyKey',
      this,
    );
    metadata = _i1.ColumnString(
      'metadata',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final OrderUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString serviceType;

  late final _i1.ColumnString networkProvider;

  late final _i1.ColumnString recipientIdentifier;

  late final _i1.ColumnDouble amount;

  late final _i1.ColumnDouble costPrice;

  late final _i1.ColumnDouble sellPrice;

  late final _i1.ColumnString providerReference;

  late final _i1.ColumnString status;

  late final _i1.ColumnString channel;

  late final _i1.ColumnString idempotencyKey;

  late final _i1.ColumnString metadata;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    serviceType,
    networkProvider,
    recipientIdentifier,
    amount,
    costPrice,
    sellPrice,
    providerReference,
    status,
    channel,
    idempotencyKey,
    metadata,
    createdAt,
  ];
}

class OrderInclude extends _i1.IncludeObject {
  OrderInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Order.t;
}

class OrderIncludeList extends _i1.IncludeList {
  OrderIncludeList._({
    _i1.WhereExpressionBuilder<OrderTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Order.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Order.t;
}

class OrderRepository {
  const OrderRepository._();

  /// Returns a list of [Order]s matching the given query parameters.
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
  Future<List<Order>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OrderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrderTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Order>(
      where: where?.call(Order.t),
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Order] matching the given query parameters.
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
  Future<Order?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OrderTable>? where,
    int? offset,
    _i1.OrderByBuilder<OrderTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<OrderTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Order>(
      where: where?.call(Order.t),
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Order] by its [id] or null if no such row exists.
  Future<Order?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Order>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Order]s in the list and returns the inserted rows.
  ///
  /// The returned [Order]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Order>> insert(
    _i1.DatabaseSession session,
    List<Order> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Order>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Order] and returns the inserted row.
  ///
  /// The returned [Order] will have its `id` field set.
  Future<Order> insertRow(
    _i1.DatabaseSession session,
    Order row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Order>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Order]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Order>> update(
    _i1.DatabaseSession session,
    List<Order> rows, {
    _i1.ColumnSelections<OrderTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Order>(
      rows,
      columns: columns?.call(Order.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Order]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Order> updateRow(
    _i1.DatabaseSession session,
    Order row, {
    _i1.ColumnSelections<OrderTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Order>(
      row,
      columns: columns?.call(Order.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Order] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Order?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<OrderUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Order>(
      id,
      columnValues: columnValues(Order.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Order]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Order>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<OrderUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<OrderTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<OrderTable>? orderBy,
    _i1.OrderByListBuilder<OrderTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Order>(
      columnValues: columnValues(Order.t.updateTable),
      where: where(Order.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Order.t),
      orderByList: orderByList?.call(Order.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Order]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Order>> delete(
    _i1.DatabaseSession session,
    List<Order> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Order>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Order].
  Future<Order> deleteRow(
    _i1.DatabaseSession session,
    Order row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Order>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Order>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OrderTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Order>(
      where: where(Order.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<OrderTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Order>(
      where: where?.call(Order.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Order] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<OrderTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Order>(
      where: where(Order.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
