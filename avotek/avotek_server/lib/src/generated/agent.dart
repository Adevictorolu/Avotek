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

abstract class Agent implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Agent._({
    this.id,
    required this.userId,
    required this.tier,
    required this.commissionRate,
    required this.updatedAt,
  });

  factory Agent({
    int? id,
    required int userId,
    required String tier,
    required double commissionRate,
    required DateTime updatedAt,
  }) = _AgentImpl;

  factory Agent.fromJson(Map<String, dynamic> jsonSerialization) {
    return Agent(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      tier: jsonSerialization['tier'] as String,
      commissionRate: (jsonSerialization['commissionRate'] as num).toDouble(),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = AgentTable();

  static const db = AgentRepository._();

  @override
  int? id;

  int userId;

  String tier;

  double commissionRate;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Agent copyWith({
    int? id,
    int? userId,
    String? tier,
    double? commissionRate,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Agent',
      if (id != null) 'id': id,
      'userId': userId,
      'tier': tier,
      'commissionRate': commissionRate,
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Agent',
      if (id != null) 'id': id,
      'userId': userId,
      'tier': tier,
      'commissionRate': commissionRate,
      'updatedAt': updatedAt.toJson(),
    };
  }

  static AgentInclude include() {
    return AgentInclude._();
  }

  static AgentIncludeList includeList({
    _i1.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentTable>? orderByList,
    AgentInclude? include,
  }) {
    return AgentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Agent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Agent.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AgentImpl extends Agent {
  _AgentImpl({
    int? id,
    required int userId,
    required String tier,
    required double commissionRate,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         userId: userId,
         tier: tier,
         commissionRate: commissionRate,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Agent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Agent copyWith({
    Object? id = _Undefined,
    int? userId,
    String? tier,
    double? commissionRate,
    DateTime? updatedAt,
  }) {
    return Agent(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      commissionRate: commissionRate ?? this.commissionRate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AgentUpdateTable extends _i1.UpdateTable<AgentTable> {
  AgentUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> tier(String value) => _i1.ColumnValue(
    table.tier,
    value,
  );

  _i1.ColumnValue<double, double> commissionRate(double value) =>
      _i1.ColumnValue(
        table.commissionRate,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class AgentTable extends _i1.Table<int?> {
  AgentTable({super.tableRelation}) : super(tableName: 'agents') {
    updateTable = AgentUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    tier = _i1.ColumnString(
      'tier',
      this,
    );
    commissionRate = _i1.ColumnDouble(
      'commissionRate',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final AgentUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString tier;

  late final _i1.ColumnDouble commissionRate;

  late final _i1.ColumnDateTime updatedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    tier,
    commissionRate,
    updatedAt,
  ];
}

class AgentInclude extends _i1.IncludeObject {
  AgentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Agent.t;
}

class AgentIncludeList extends _i1.IncludeList {
  AgentIncludeList._({
    _i1.WhereExpressionBuilder<AgentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Agent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Agent.t;
}

class AgentRepository {
  const AgentRepository._();

  /// Returns a list of [Agent]s matching the given query parameters.
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
  Future<List<Agent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Agent>(
      where: where?.call(Agent.t),
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Agent] matching the given query parameters.
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
  Future<Agent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AgentTable>? where,
    int? offset,
    _i1.OrderByBuilder<AgentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AgentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Agent>(
      where: where?.call(Agent.t),
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Agent] by its [id] or null if no such row exists.
  Future<Agent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Agent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Agent]s in the list and returns the inserted rows.
  ///
  /// The returned [Agent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Agent>> insert(
    _i1.DatabaseSession session,
    List<Agent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Agent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Agent] and returns the inserted row.
  ///
  /// The returned [Agent] will have its `id` field set.
  Future<Agent> insertRow(
    _i1.DatabaseSession session,
    Agent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Agent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Agent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Agent>> update(
    _i1.DatabaseSession session,
    List<Agent> rows, {
    _i1.ColumnSelections<AgentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Agent>(
      rows,
      columns: columns?.call(Agent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Agent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Agent> updateRow(
    _i1.DatabaseSession session,
    Agent row, {
    _i1.ColumnSelections<AgentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Agent>(
      row,
      columns: columns?.call(Agent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Agent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Agent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AgentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Agent>(
      id,
      columnValues: columnValues(Agent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Agent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Agent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AgentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AgentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AgentTable>? orderBy,
    _i1.OrderByListBuilder<AgentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Agent>(
      columnValues: columnValues(Agent.t.updateTable),
      where: where(Agent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Agent.t),
      orderByList: orderByList?.call(Agent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Agent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Agent>> delete(
    _i1.DatabaseSession session,
    List<Agent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Agent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Agent].
  Future<Agent> deleteRow(
    _i1.DatabaseSession session,
    Agent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Agent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Agent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AgentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Agent>(
      where: where(Agent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AgentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Agent>(
      where: where?.call(Agent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Agent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AgentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Agent>(
      where: where(Agent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
