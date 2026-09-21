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

abstract class Beneficiary
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  Beneficiary._({
    this.id,
    required this.userId,
    required this.serviceType,
    required this.networkProvider,
    required this.recipientIdentifier,
    required this.name,
    required this.createdAt,
  });

  factory Beneficiary({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
    required DateTime createdAt,
  }) = _BeneficiaryImpl;

  factory Beneficiary.fromJson(Map<String, dynamic> jsonSerialization) {
    return Beneficiary(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int,
      serviceType: jsonSerialization['serviceType'] as String,
      networkProvider: jsonSerialization['networkProvider'] as String,
      recipientIdentifier: jsonSerialization['recipientIdentifier'] as String,
      name: jsonSerialization['name'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = BeneficiaryTable();

  static const db = BeneficiaryRepository._();

  @override
  int? id;

  int userId;

  String serviceType;

  String networkProvider;

  String recipientIdentifier;

  String name;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Beneficiary copyWith({
    int? id,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    String? name,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Beneficiary',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Beneficiary',
      if (id != null) 'id': id,
      'userId': userId,
      'serviceType': serviceType,
      'networkProvider': networkProvider,
      'recipientIdentifier': recipientIdentifier,
      'name': name,
      'createdAt': createdAt.toJson(),
    };
  }

  static BeneficiaryInclude include() {
    return BeneficiaryInclude._();
  }

  static BeneficiaryIncludeList includeList({
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    BeneficiaryInclude? include,
  }) {
    return BeneficiaryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Beneficiary.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Beneficiary.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BeneficiaryImpl extends Beneficiary {
  _BeneficiaryImpl({
    int? id,
    required int userId,
    required String serviceType,
    required String networkProvider,
    required String recipientIdentifier,
    required String name,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         serviceType: serviceType,
         networkProvider: networkProvider,
         recipientIdentifier: recipientIdentifier,
         name: name,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Beneficiary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Beneficiary copyWith({
    Object? id = _Undefined,
    int? userId,
    String? serviceType,
    String? networkProvider,
    String? recipientIdentifier,
    String? name,
    DateTime? createdAt,
  }) {
    return Beneficiary(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      serviceType: serviceType ?? this.serviceType,
      networkProvider: networkProvider ?? this.networkProvider,
      recipientIdentifier: recipientIdentifier ?? this.recipientIdentifier,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class BeneficiaryUpdateTable extends _i1.UpdateTable<BeneficiaryTable> {
  BeneficiaryUpdateTable(super.table);

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

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class BeneficiaryTable extends _i1.Table<int?> {
  BeneficiaryTable({super.tableRelation}) : super(tableName: 'beneficiaries') {
    updateTable = BeneficiaryUpdateTable(this);
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
    name = _i1.ColumnString(
      'name',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final BeneficiaryUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString serviceType;

  late final _i1.ColumnString networkProvider;

  late final _i1.ColumnString recipientIdentifier;

  late final _i1.ColumnString name;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    serviceType,
    networkProvider,
    recipientIdentifier,
    name,
    createdAt,
  ];
}

class BeneficiaryInclude extends _i1.IncludeObject {
  BeneficiaryInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Beneficiary.t;
}

class BeneficiaryIncludeList extends _i1.IncludeList {
  BeneficiaryIncludeList._({
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Beneficiary.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Beneficiary.t;
}

class BeneficiaryRepository {
  const BeneficiaryRepository._();

  /// Returns a list of [Beneficiary]s matching the given query parameters.
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
  Future<List<Beneficiary>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Beneficiary>(
      where: where?.call(Beneficiary.t),
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Beneficiary] matching the given query parameters.
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
  Future<Beneficiary?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Beneficiary>(
      where: where?.call(Beneficiary.t),
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Beneficiary] by its [id] or null if no such row exists.
  Future<Beneficiary?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Beneficiary>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Beneficiary]s in the list and returns the inserted rows.
  ///
  /// The returned [Beneficiary]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Beneficiary>> insert(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Beneficiary>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Beneficiary] and returns the inserted row.
  ///
  /// The returned [Beneficiary] will have its `id` field set.
  Future<Beneficiary> insertRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Beneficiary>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Beneficiary]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Beneficiary>> update(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.ColumnSelections<BeneficiaryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Beneficiary>(
      rows,
      columns: columns?.call(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Beneficiary]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Beneficiary> updateRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.ColumnSelections<BeneficiaryTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Beneficiary>(
      row,
      columns: columns?.call(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Beneficiary] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Beneficiary?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<BeneficiaryUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Beneficiary>(
      id,
      columnValues: columnValues(Beneficiary.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Beneficiary]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Beneficiary>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<BeneficiaryUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<BeneficiaryTable>? orderBy,
    _i1.OrderByListBuilder<BeneficiaryTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Beneficiary>(
      columnValues: columnValues(Beneficiary.t.updateTable),
      where: where(Beneficiary.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Beneficiary.t),
      orderByList: orderByList?.call(Beneficiary.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Beneficiary]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Beneficiary>> delete(
    _i1.DatabaseSession session,
    List<Beneficiary> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Beneficiary>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Beneficiary].
  Future<Beneficiary> deleteRow(
    _i1.DatabaseSession session,
    Beneficiary row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Beneficiary>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Beneficiary>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Beneficiary>(
      where: where(Beneficiary.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<BeneficiaryTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Beneficiary>(
      where: where?.call(Beneficiary.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Beneficiary] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<BeneficiaryTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Beneficiary>(
      where: where(Beneficiary.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
