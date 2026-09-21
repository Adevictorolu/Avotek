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

abstract class WebhookLog
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  WebhookLog._({
    this.id,
    required this.source,
    required this.payload,
    required this.processed,
    required this.createdAt,
  });

  factory WebhookLog({
    int? id,
    required String source,
    required String payload,
    required bool processed,
    required DateTime createdAt,
  }) = _WebhookLogImpl;

  factory WebhookLog.fromJson(Map<String, dynamic> jsonSerialization) {
    return WebhookLog(
      id: jsonSerialization['id'] as int?,
      source: jsonSerialization['source'] as String,
      payload: jsonSerialization['payload'] as String,
      processed: _i1.BoolJsonExtension.fromJson(jsonSerialization['processed']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WebhookLogTable();

  static const db = WebhookLogRepository._();

  @override
  int? id;

  String source;

  String payload;

  bool processed;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [WebhookLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WebhookLog copyWith({
    int? id,
    String? source,
    String? payload,
    bool? processed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WebhookLog',
      if (id != null) 'id': id,
      'source': source,
      'payload': payload,
      'processed': processed,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WebhookLog',
      if (id != null) 'id': id,
      'source': source,
      'payload': payload,
      'processed': processed,
      'createdAt': createdAt.toJson(),
    };
  }

  static WebhookLogInclude include() {
    return WebhookLogInclude._();
  }

  static WebhookLogIncludeList includeList({
    _i1.WhereExpressionBuilder<WebhookLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WebhookLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WebhookLogTable>? orderByList,
    WebhookLogInclude? include,
  }) {
    return WebhookLogIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebhookLog.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(WebhookLog.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WebhookLogImpl extends WebhookLog {
  _WebhookLogImpl({
    int? id,
    required String source,
    required String payload,
    required bool processed,
    required DateTime createdAt,
  }) : super._(
         id: id,
         source: source,
         payload: payload,
         processed: processed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WebhookLog]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WebhookLog copyWith({
    Object? id = _Undefined,
    String? source,
    String? payload,
    bool? processed,
    DateTime? createdAt,
  }) {
    return WebhookLog(
      id: id is int? ? id : this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
      processed: processed ?? this.processed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WebhookLogUpdateTable extends _i1.UpdateTable<WebhookLogTable> {
  WebhookLogUpdateTable(super.table);

  _i1.ColumnValue<String, String> source(String value) => _i1.ColumnValue(
    table.source,
    value,
  );

  _i1.ColumnValue<String, String> payload(String value) => _i1.ColumnValue(
    table.payload,
    value,
  );

  _i1.ColumnValue<bool, bool> processed(bool value) => _i1.ColumnValue(
    table.processed,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class WebhookLogTable extends _i1.Table<int?> {
  WebhookLogTable({super.tableRelation}) : super(tableName: 'webhooks_log') {
    updateTable = WebhookLogUpdateTable(this);
    source = _i1.ColumnString(
      'source',
      this,
    );
    payload = _i1.ColumnString(
      'payload',
      this,
    );
    processed = _i1.ColumnBool(
      'processed',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WebhookLogUpdateTable updateTable;

  late final _i1.ColumnString source;

  late final _i1.ColumnString payload;

  late final _i1.ColumnBool processed;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    source,
    payload,
    processed,
    createdAt,
  ];
}

class WebhookLogInclude extends _i1.IncludeObject {
  WebhookLogInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => WebhookLog.t;
}

class WebhookLogIncludeList extends _i1.IncludeList {
  WebhookLogIncludeList._({
    _i1.WhereExpressionBuilder<WebhookLogTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WebhookLog.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => WebhookLog.t;
}

class WebhookLogRepository {
  const WebhookLogRepository._();

  /// Returns a list of [WebhookLog]s matching the given query parameters.
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
  Future<List<WebhookLog>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WebhookLogTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WebhookLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WebhookLogTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WebhookLog>(
      where: where?.call(WebhookLog.t),
      orderBy: orderBy?.call(WebhookLog.t),
      orderByList: orderByList?.call(WebhookLog.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WebhookLog] matching the given query parameters.
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
  Future<WebhookLog?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WebhookLogTable>? where,
    int? offset,
    _i1.OrderByBuilder<WebhookLogTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<WebhookLogTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WebhookLog>(
      where: where?.call(WebhookLog.t),
      orderBy: orderBy?.call(WebhookLog.t),
      orderByList: orderByList?.call(WebhookLog.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WebhookLog] by its [id] or null if no such row exists.
  Future<WebhookLog?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WebhookLog>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WebhookLog]s in the list and returns the inserted rows.
  ///
  /// The returned [WebhookLog]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<WebhookLog>> insert(
    _i1.DatabaseSession session,
    List<WebhookLog> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<WebhookLog>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [WebhookLog] and returns the inserted row.
  ///
  /// The returned [WebhookLog] will have its `id` field set.
  Future<WebhookLog> insertRow(
    _i1.DatabaseSession session,
    WebhookLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<WebhookLog>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [WebhookLog]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<WebhookLog>> update(
    _i1.DatabaseSession session,
    List<WebhookLog> rows, {
    _i1.ColumnSelections<WebhookLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<WebhookLog>(
      rows,
      columns: columns?.call(WebhookLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WebhookLog]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WebhookLog> updateRow(
    _i1.DatabaseSession session,
    WebhookLog row, {
    _i1.ColumnSelections<WebhookLogTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<WebhookLog>(
      row,
      columns: columns?.call(WebhookLog.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WebhookLog] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WebhookLog?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<WebhookLogUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<WebhookLog>(
      id,
      columnValues: columnValues(WebhookLog.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WebhookLog]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<WebhookLog>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<WebhookLogUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<WebhookLogTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<WebhookLogTable>? orderBy,
    _i1.OrderByListBuilder<WebhookLogTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<WebhookLog>(
      columnValues: columnValues(WebhookLog.t.updateTable),
      where: where(WebhookLog.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WebhookLog.t),
      orderByList: orderByList?.call(WebhookLog.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [WebhookLog]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<WebhookLog>> delete(
    _i1.DatabaseSession session,
    List<WebhookLog> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<WebhookLog>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [WebhookLog].
  Future<WebhookLog> deleteRow(
    _i1.DatabaseSession session,
    WebhookLog row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WebhookLog>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<WebhookLog>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WebhookLogTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<WebhookLog>(
      where: where(WebhookLog.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<WebhookLogTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<WebhookLog>(
      where: where?.call(WebhookLog.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WebhookLog] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<WebhookLogTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WebhookLog>(
      where: where(WebhookLog.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
