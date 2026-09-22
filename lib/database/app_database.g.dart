// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $VouchersTableTable extends VouchersTable
    with TableInfo<$VouchersTableTable, VouchersTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VouchersTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcTimestampMeta = const VerificationMeta(
    'hlcTimestamp',
  );
  @override
  late final GeneratedColumn<String> hlcTimestamp = GeneratedColumn<String>(
    'hlc_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('0:0:origin'),
  );
  static const VerificationMeta _originNodeIdMeta = const VerificationMeta(
    'originNodeId',
  );
  @override
  late final GeneratedColumn<String> originNodeId = GeneratedColumn<String>(
    'origin_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('primary'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _voucherNumberMeta = const VerificationMeta(
    'voucherNumber',
  );
  @override
  late final GeneratedColumn<String> voucherNumber = GeneratedColumn<String>(
    'voucher_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voucherTypeMeta = const VerificationMeta(
    'voucherType',
  );
  @override
  late final GeneratedColumn<String> voucherType = GeneratedColumn<String>(
    'voucher_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Main'),
  );
  static const VerificationMeta _partyNameMeta = const VerificationMeta(
    'partyName',
  );
  @override
  late final GeneratedColumn<String> partyName = GeneratedColumn<String>(
    'party_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grandTotalMeta = const VerificationMeta(
    'grandTotal',
  );
  @override
  late final GeneratedColumn<double> grandTotal = GeneratedColumn<double>(
    'grand_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subTotalMeta = const VerificationMeta(
    'subTotal',
  );
  @override
  late final GeneratedColumn<double> subTotal = GeneratedColumn<double>(
    'sub_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalTaxMeta = const VerificationMeta(
    'totalTax',
  );
  @override
  late final GeneratedColumn<double> totalTax = GeneratedColumn<double>(
    'total_tax',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _irnMeta = const VerificationMeta('irn');
  @override
  late final GeneratedColumn<String> irn = GeneratedColumn<String>(
    'irn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ackNoMeta = const VerificationMeta('ackNo');
  @override
  late final GeneratedColumn<String> ackNo = GeneratedColumn<String>(
    'ack_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _signedQrCodeMeta = const VerificationMeta(
    'signedQrCode',
  );
  @override
  late final GeneratedColumn<String> signedQrCode = GeneratedColumn<String>(
    'signed_qr_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    hlcTimestamp,
    originNodeId,
    isDeleted,
    voucherNumber,
    voucherType,
    date,
    series,
    partyName,
    grandTotal,
    subTotal,
    totalTax,
    payloadJson,
    irn,
    ackNo,
    signedQrCode,
    isSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vouchers_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<VouchersTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('hlc_timestamp')) {
      context.handle(
        _hlcTimestampMeta,
        hlcTimestamp.isAcceptableOrUnknown(
          data['hlc_timestamp']!,
          _hlcTimestampMeta,
        ),
      );
    }
    if (data.containsKey('origin_node_id')) {
      context.handle(
        _originNodeIdMeta,
        originNodeId.isAcceptableOrUnknown(
          data['origin_node_id']!,
          _originNodeIdMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('voucher_number')) {
      context.handle(
        _voucherNumberMeta,
        voucherNumber.isAcceptableOrUnknown(
          data['voucher_number']!,
          _voucherNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voucherNumberMeta);
    }
    if (data.containsKey('voucher_type')) {
      context.handle(
        _voucherTypeMeta,
        voucherType.isAcceptableOrUnknown(
          data['voucher_type']!,
          _voucherTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_voucherTypeMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    }
    if (data.containsKey('party_name')) {
      context.handle(
        _partyNameMeta,
        partyName.isAcceptableOrUnknown(data['party_name']!, _partyNameMeta),
      );
    } else if (isInserting) {
      context.missing(_partyNameMeta);
    }
    if (data.containsKey('grand_total')) {
      context.handle(
        _grandTotalMeta,
        grandTotal.isAcceptableOrUnknown(data['grand_total']!, _grandTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_grandTotalMeta);
    }
    if (data.containsKey('sub_total')) {
      context.handle(
        _subTotalMeta,
        subTotal.isAcceptableOrUnknown(data['sub_total']!, _subTotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subTotalMeta);
    }
    if (data.containsKey('total_tax')) {
      context.handle(
        _totalTaxMeta,
        totalTax.isAcceptableOrUnknown(data['total_tax']!, _totalTaxMeta),
      );
    } else if (isInserting) {
      context.missing(_totalTaxMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('irn')) {
      context.handle(
        _irnMeta,
        irn.isAcceptableOrUnknown(data['irn']!, _irnMeta),
      );
    }
    if (data.containsKey('ack_no')) {
      context.handle(
        _ackNoMeta,
        ackNo.isAcceptableOrUnknown(data['ack_no']!, _ackNoMeta),
      );
    }
    if (data.containsKey('signed_qr_code')) {
      context.handle(
        _signedQrCodeMeta,
        signedQrCode.isAcceptableOrUnknown(
          data['signed_qr_code']!,
          _signedQrCodeMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VouchersTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VouchersTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      hlcTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc_timestamp'],
      )!,
      originNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_node_id'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      voucherNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_number'],
      )!,
      voucherType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voucher_type'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      )!,
      partyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}party_name'],
      )!,
      grandTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grand_total'],
      )!,
      subTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sub_total'],
      )!,
      totalTax: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tax'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      irn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}irn'],
      ),
      ackNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ack_no'],
      ),
      signedQrCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signed_qr_code'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
    );
  }

  @override
  $VouchersTableTable createAlias(String alias) {
    return $VouchersTableTable(attachedDatabase, alias);
  }
}

class VouchersTableData extends DataClass
    implements Insertable<VouchersTableData> {
  final String id;
  final String hlcTimestamp;
  final String originNodeId;
  final bool isDeleted;
  final String voucherNumber;
  final String voucherType;
  final String date;
  final String series;
  final String partyName;
  final double grandTotal;
  final double subTotal;
  final double totalTax;
  final String payloadJson;
  final String? irn;
  final String? ackNo;
  final String? signedQrCode;
  final bool isSynced;
  const VouchersTableData({
    required this.id,
    required this.hlcTimestamp,
    required this.originNodeId,
    required this.isDeleted,
    required this.voucherNumber,
    required this.voucherType,
    required this.date,
    required this.series,
    required this.partyName,
    required this.grandTotal,
    required this.subTotal,
    required this.totalTax,
    required this.payloadJson,
    this.irn,
    this.ackNo,
    this.signedQrCode,
    required this.isSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['hlc_timestamp'] = Variable<String>(hlcTimestamp);
    map['origin_node_id'] = Variable<String>(originNodeId);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['voucher_number'] = Variable<String>(voucherNumber);
    map['voucher_type'] = Variable<String>(voucherType);
    map['date'] = Variable<String>(date);
    map['series'] = Variable<String>(series);
    map['party_name'] = Variable<String>(partyName);
    map['grand_total'] = Variable<double>(grandTotal);
    map['sub_total'] = Variable<double>(subTotal);
    map['total_tax'] = Variable<double>(totalTax);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || irn != null) {
      map['irn'] = Variable<String>(irn);
    }
    if (!nullToAbsent || ackNo != null) {
      map['ack_no'] = Variable<String>(ackNo);
    }
    if (!nullToAbsent || signedQrCode != null) {
      map['signed_qr_code'] = Variable<String>(signedQrCode);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  VouchersTableCompanion toCompanion(bool nullToAbsent) {
    return VouchersTableCompanion(
      id: Value(id),
      hlcTimestamp: Value(hlcTimestamp),
      originNodeId: Value(originNodeId),
      isDeleted: Value(isDeleted),
      voucherNumber: Value(voucherNumber),
      voucherType: Value(voucherType),
      date: Value(date),
      series: Value(series),
      partyName: Value(partyName),
      grandTotal: Value(grandTotal),
      subTotal: Value(subTotal),
      totalTax: Value(totalTax),
      payloadJson: Value(payloadJson),
      irn: irn == null && nullToAbsent ? const Value.absent() : Value(irn),
      ackNo: ackNo == null && nullToAbsent
          ? const Value.absent()
          : Value(ackNo),
      signedQrCode: signedQrCode == null && nullToAbsent
          ? const Value.absent()
          : Value(signedQrCode),
      isSynced: Value(isSynced),
    );
  }

  factory VouchersTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VouchersTableData(
      id: serializer.fromJson<String>(json['id']),
      hlcTimestamp: serializer.fromJson<String>(json['hlcTimestamp']),
      originNodeId: serializer.fromJson<String>(json['originNodeId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      voucherNumber: serializer.fromJson<String>(json['voucherNumber']),
      voucherType: serializer.fromJson<String>(json['voucherType']),
      date: serializer.fromJson<String>(json['date']),
      series: serializer.fromJson<String>(json['series']),
      partyName: serializer.fromJson<String>(json['partyName']),
      grandTotal: serializer.fromJson<double>(json['grandTotal']),
      subTotal: serializer.fromJson<double>(json['subTotal']),
      totalTax: serializer.fromJson<double>(json['totalTax']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      irn: serializer.fromJson<String?>(json['irn']),
      ackNo: serializer.fromJson<String?>(json['ackNo']),
      signedQrCode: serializer.fromJson<String?>(json['signedQrCode']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'hlcTimestamp': serializer.toJson<String>(hlcTimestamp),
      'originNodeId': serializer.toJson<String>(originNodeId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'voucherNumber': serializer.toJson<String>(voucherNumber),
      'voucherType': serializer.toJson<String>(voucherType),
      'date': serializer.toJson<String>(date),
      'series': serializer.toJson<String>(series),
      'partyName': serializer.toJson<String>(partyName),
      'grandTotal': serializer.toJson<double>(grandTotal),
      'subTotal': serializer.toJson<double>(subTotal),
      'totalTax': serializer.toJson<double>(totalTax),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'irn': serializer.toJson<String?>(irn),
      'ackNo': serializer.toJson<String?>(ackNo),
      'signedQrCode': serializer.toJson<String?>(signedQrCode),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  VouchersTableData copyWith({
    String? id,
    String? hlcTimestamp,
    String? originNodeId,
    bool? isDeleted,
    String? voucherNumber,
    String? voucherType,
    String? date,
    String? series,
    String? partyName,
    double? grandTotal,
    double? subTotal,
    double? totalTax,
    String? payloadJson,
    Value<String?> irn = const Value.absent(),
    Value<String?> ackNo = const Value.absent(),
    Value<String?> signedQrCode = const Value.absent(),
    bool? isSynced,
  }) => VouchersTableData(
    id: id ?? this.id,
    hlcTimestamp: hlcTimestamp ?? this.hlcTimestamp,
    originNodeId: originNodeId ?? this.originNodeId,
    isDeleted: isDeleted ?? this.isDeleted,
    voucherNumber: voucherNumber ?? this.voucherNumber,
    voucherType: voucherType ?? this.voucherType,
    date: date ?? this.date,
    series: series ?? this.series,
    partyName: partyName ?? this.partyName,
    grandTotal: grandTotal ?? this.grandTotal,
    subTotal: subTotal ?? this.subTotal,
    totalTax: totalTax ?? this.totalTax,
    payloadJson: payloadJson ?? this.payloadJson,
    irn: irn.present ? irn.value : this.irn,
    ackNo: ackNo.present ? ackNo.value : this.ackNo,
    signedQrCode: signedQrCode.present ? signedQrCode.value : this.signedQrCode,
    isSynced: isSynced ?? this.isSynced,
  );
  VouchersTableData copyWithCompanion(VouchersTableCompanion data) {
    return VouchersTableData(
      id: data.id.present ? data.id.value : this.id,
      hlcTimestamp: data.hlcTimestamp.present
          ? data.hlcTimestamp.value
          : this.hlcTimestamp,
      originNodeId: data.originNodeId.present
          ? data.originNodeId.value
          : this.originNodeId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      voucherNumber: data.voucherNumber.present
          ? data.voucherNumber.value
          : this.voucherNumber,
      voucherType: data.voucherType.present
          ? data.voucherType.value
          : this.voucherType,
      date: data.date.present ? data.date.value : this.date,
      series: data.series.present ? data.series.value : this.series,
      partyName: data.partyName.present ? data.partyName.value : this.partyName,
      grandTotal: data.grandTotal.present
          ? data.grandTotal.value
          : this.grandTotal,
      subTotal: data.subTotal.present ? data.subTotal.value : this.subTotal,
      totalTax: data.totalTax.present ? data.totalTax.value : this.totalTax,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      irn: data.irn.present ? data.irn.value : this.irn,
      ackNo: data.ackNo.present ? data.ackNo.value : this.ackNo,
      signedQrCode: data.signedQrCode.present
          ? data.signedQrCode.value
          : this.signedQrCode,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VouchersTableData(')
          ..write('id: $id, ')
          ..write('hlcTimestamp: $hlcTimestamp, ')
          ..write('originNodeId: $originNodeId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('date: $date, ')
          ..write('series: $series, ')
          ..write('partyName: $partyName, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('subTotal: $subTotal, ')
          ..write('totalTax: $totalTax, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('irn: $irn, ')
          ..write('ackNo: $ackNo, ')
          ..write('signedQrCode: $signedQrCode, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    hlcTimestamp,
    originNodeId,
    isDeleted,
    voucherNumber,
    voucherType,
    date,
    series,
    partyName,
    grandTotal,
    subTotal,
    totalTax,
    payloadJson,
    irn,
    ackNo,
    signedQrCode,
    isSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VouchersTableData &&
          other.id == this.id &&
          other.hlcTimestamp == this.hlcTimestamp &&
          other.originNodeId == this.originNodeId &&
          other.isDeleted == this.isDeleted &&
          other.voucherNumber == this.voucherNumber &&
          other.voucherType == this.voucherType &&
          other.date == this.date &&
          other.series == this.series &&
          other.partyName == this.partyName &&
          other.grandTotal == this.grandTotal &&
          other.subTotal == this.subTotal &&
          other.totalTax == this.totalTax &&
          other.payloadJson == this.payloadJson &&
          other.irn == this.irn &&
          other.ackNo == this.ackNo &&
          other.signedQrCode == this.signedQrCode &&
          other.isSynced == this.isSynced);
}

class VouchersTableCompanion extends UpdateCompanion<VouchersTableData> {
  final Value<String> id;
  final Value<String> hlcTimestamp;
  final Value<String> originNodeId;
  final Value<bool> isDeleted;
  final Value<String> voucherNumber;
  final Value<String> voucherType;
  final Value<String> date;
  final Value<String> series;
  final Value<String> partyName;
  final Value<double> grandTotal;
  final Value<double> subTotal;
  final Value<double> totalTax;
  final Value<String> payloadJson;
  final Value<String?> irn;
  final Value<String?> ackNo;
  final Value<String?> signedQrCode;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const VouchersTableCompanion({
    this.id = const Value.absent(),
    this.hlcTimestamp = const Value.absent(),
    this.originNodeId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.voucherNumber = const Value.absent(),
    this.voucherType = const Value.absent(),
    this.date = const Value.absent(),
    this.series = const Value.absent(),
    this.partyName = const Value.absent(),
    this.grandTotal = const Value.absent(),
    this.subTotal = const Value.absent(),
    this.totalTax = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.irn = const Value.absent(),
    this.ackNo = const Value.absent(),
    this.signedQrCode = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VouchersTableCompanion.insert({
    required String id,
    this.hlcTimestamp = const Value.absent(),
    this.originNodeId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required String voucherNumber,
    required String voucherType,
    required String date,
    this.series = const Value.absent(),
    required String partyName,
    required double grandTotal,
    required double subTotal,
    required double totalTax,
    required String payloadJson,
    this.irn = const Value.absent(),
    this.ackNo = const Value.absent(),
    this.signedQrCode = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       voucherNumber = Value(voucherNumber),
       voucherType = Value(voucherType),
       date = Value(date),
       partyName = Value(partyName),
       grandTotal = Value(grandTotal),
       subTotal = Value(subTotal),
       totalTax = Value(totalTax),
       payloadJson = Value(payloadJson);
  static Insertable<VouchersTableData> custom({
    Expression<String>? id,
    Expression<String>? hlcTimestamp,
    Expression<String>? originNodeId,
    Expression<bool>? isDeleted,
    Expression<String>? voucherNumber,
    Expression<String>? voucherType,
    Expression<String>? date,
    Expression<String>? series,
    Expression<String>? partyName,
    Expression<double>? grandTotal,
    Expression<double>? subTotal,
    Expression<double>? totalTax,
    Expression<String>? payloadJson,
    Expression<String>? irn,
    Expression<String>? ackNo,
    Expression<String>? signedQrCode,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (hlcTimestamp != null) 'hlc_timestamp': hlcTimestamp,
      if (originNodeId != null) 'origin_node_id': originNodeId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (voucherNumber != null) 'voucher_number': voucherNumber,
      if (voucherType != null) 'voucher_type': voucherType,
      if (date != null) 'date': date,
      if (series != null) 'series': series,
      if (partyName != null) 'party_name': partyName,
      if (grandTotal != null) 'grand_total': grandTotal,
      if (subTotal != null) 'sub_total': subTotal,
      if (totalTax != null) 'total_tax': totalTax,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (irn != null) 'irn': irn,
      if (ackNo != null) 'ack_no': ackNo,
      if (signedQrCode != null) 'signed_qr_code': signedQrCode,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VouchersTableCompanion copyWith({
    Value<String>? id,
    Value<String>? hlcTimestamp,
    Value<String>? originNodeId,
    Value<bool>? isDeleted,
    Value<String>? voucherNumber,
    Value<String>? voucherType,
    Value<String>? date,
    Value<String>? series,
    Value<String>? partyName,
    Value<double>? grandTotal,
    Value<double>? subTotal,
    Value<double>? totalTax,
    Value<String>? payloadJson,
    Value<String?>? irn,
    Value<String?>? ackNo,
    Value<String?>? signedQrCode,
    Value<bool>? isSynced,
    Value<int>? rowid,
  }) {
    return VouchersTableCompanion(
      id: id ?? this.id,
      hlcTimestamp: hlcTimestamp ?? this.hlcTimestamp,
      originNodeId: originNodeId ?? this.originNodeId,
      isDeleted: isDeleted ?? this.isDeleted,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      voucherType: voucherType ?? this.voucherType,
      date: date ?? this.date,
      series: series ?? this.series,
      partyName: partyName ?? this.partyName,
      grandTotal: grandTotal ?? this.grandTotal,
      subTotal: subTotal ?? this.subTotal,
      totalTax: totalTax ?? this.totalTax,
      payloadJson: payloadJson ?? this.payloadJson,
      irn: irn ?? this.irn,
      ackNo: ackNo ?? this.ackNo,
      signedQrCode: signedQrCode ?? this.signedQrCode,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (hlcTimestamp.present) {
      map['hlc_timestamp'] = Variable<String>(hlcTimestamp.value);
    }
    if (originNodeId.present) {
      map['origin_node_id'] = Variable<String>(originNodeId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (voucherNumber.present) {
      map['voucher_number'] = Variable<String>(voucherNumber.value);
    }
    if (voucherType.present) {
      map['voucher_type'] = Variable<String>(voucherType.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (partyName.present) {
      map['party_name'] = Variable<String>(partyName.value);
    }
    if (grandTotal.present) {
      map['grand_total'] = Variable<double>(grandTotal.value);
    }
    if (subTotal.present) {
      map['sub_total'] = Variable<double>(subTotal.value);
    }
    if (totalTax.present) {
      map['total_tax'] = Variable<double>(totalTax.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (irn.present) {
      map['irn'] = Variable<String>(irn.value);
    }
    if (ackNo.present) {
      map['ack_no'] = Variable<String>(ackNo.value);
    }
    if (signedQrCode.present) {
      map['signed_qr_code'] = Variable<String>(signedQrCode.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VouchersTableCompanion(')
          ..write('id: $id, ')
          ..write('hlcTimestamp: $hlcTimestamp, ')
          ..write('originNodeId: $originNodeId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('voucherNumber: $voucherNumber, ')
          ..write('voucherType: $voucherType, ')
          ..write('date: $date, ')
          ..write('series: $series, ')
          ..write('partyName: $partyName, ')
          ..write('grandTotal: $grandTotal, ')
          ..write('subTotal: $subTotal, ')
          ..write('totalTax: $totalTax, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('irn: $irn, ')
          ..write('ackNo: $ackNo, ')
          ..write('signedQrCode: $signedQrCode, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $VouchersTableTable vouchersTable = $VouchersTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vouchersTable];
}

typedef $$VouchersTableTableCreateCompanionBuilder =
    VouchersTableCompanion Function({
      required String id,
      Value<String> hlcTimestamp,
      Value<String> originNodeId,
      Value<bool> isDeleted,
      required String voucherNumber,
      required String voucherType,
      required String date,
      Value<String> series,
      required String partyName,
      required double grandTotal,
      required double subTotal,
      required double totalTax,
      required String payloadJson,
      Value<String?> irn,
      Value<String?> ackNo,
      Value<String?> signedQrCode,
      Value<bool> isSynced,
      Value<int> rowid,
    });
typedef $$VouchersTableTableUpdateCompanionBuilder =
    VouchersTableCompanion Function({
      Value<String> id,
      Value<String> hlcTimestamp,
      Value<String> originNodeId,
      Value<bool> isDeleted,
      Value<String> voucherNumber,
      Value<String> voucherType,
      Value<String> date,
      Value<String> series,
      Value<String> partyName,
      Value<double> grandTotal,
      Value<double> subTotal,
      Value<double> totalTax,
      Value<String> payloadJson,
      Value<String?> irn,
      Value<String?> ackNo,
      Value<String?> signedQrCode,
      Value<bool> isSynced,
      Value<int> rowid,
    });

class $$VouchersTableTableFilterComposer
    extends Composer<_$AppDatabase, $VouchersTableTable> {
  $$VouchersTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlcTimestamp => $composableBuilder(
    column: $table.hlcTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originNodeId => $composableBuilder(
    column: $table.originNodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTax => $composableBuilder(
    column: $table.totalTax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get irn => $composableBuilder(
    column: $table.irn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ackNo => $composableBuilder(
    column: $table.ackNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signedQrCode => $composableBuilder(
    column: $table.signedQrCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VouchersTableTableOrderingComposer
    extends Composer<_$AppDatabase, $VouchersTableTable> {
  $$VouchersTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlcTimestamp => $composableBuilder(
    column: $table.hlcTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originNodeId => $composableBuilder(
    column: $table.originNodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partyName => $composableBuilder(
    column: $table.partyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get subTotal => $composableBuilder(
    column: $table.subTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTax => $composableBuilder(
    column: $table.totalTax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get irn => $composableBuilder(
    column: $table.irn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ackNo => $composableBuilder(
    column: $table.ackNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signedQrCode => $composableBuilder(
    column: $table.signedQrCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VouchersTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $VouchersTableTable> {
  $$VouchersTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get hlcTimestamp => $composableBuilder(
    column: $table.hlcTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originNodeId => $composableBuilder(
    column: $table.originNodeId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get voucherNumber => $composableBuilder(
    column: $table.voucherNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voucherType => $composableBuilder(
    column: $table.voucherType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get partyName =>
      $composableBuilder(column: $table.partyName, builder: (column) => column);

  GeneratedColumn<double> get grandTotal => $composableBuilder(
    column: $table.grandTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get subTotal =>
      $composableBuilder(column: $table.subTotal, builder: (column) => column);

  GeneratedColumn<double> get totalTax =>
      $composableBuilder(column: $table.totalTax, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get irn =>
      $composableBuilder(column: $table.irn, builder: (column) => column);

  GeneratedColumn<String> get ackNo =>
      $composableBuilder(column: $table.ackNo, builder: (column) => column);

  GeneratedColumn<String> get signedQrCode => $composableBuilder(
    column: $table.signedQrCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$VouchersTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VouchersTableTable,
          VouchersTableData,
          $$VouchersTableTableFilterComposer,
          $$VouchersTableTableOrderingComposer,
          $$VouchersTableTableAnnotationComposer,
          $$VouchersTableTableCreateCompanionBuilder,
          $$VouchersTableTableUpdateCompanionBuilder,
          (
            VouchersTableData,
            BaseReferences<
              _$AppDatabase,
              $VouchersTableTable,
              VouchersTableData
            >,
          ),
          VouchersTableData,
          PrefetchHooks Function()
        > {
  $$VouchersTableTableTableManager(_$AppDatabase db, $VouchersTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VouchersTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VouchersTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VouchersTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> hlcTimestamp = const Value.absent(),
                Value<String> originNodeId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> voucherNumber = const Value.absent(),
                Value<String> voucherType = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> series = const Value.absent(),
                Value<String> partyName = const Value.absent(),
                Value<double> grandTotal = const Value.absent(),
                Value<double> subTotal = const Value.absent(),
                Value<double> totalTax = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String?> irn = const Value.absent(),
                Value<String?> ackNo = const Value.absent(),
                Value<String?> signedQrCode = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VouchersTableCompanion(
                id: id,
                hlcTimestamp: hlcTimestamp,
                originNodeId: originNodeId,
                isDeleted: isDeleted,
                voucherNumber: voucherNumber,
                voucherType: voucherType,
                date: date,
                series: series,
                partyName: partyName,
                grandTotal: grandTotal,
                subTotal: subTotal,
                totalTax: totalTax,
                payloadJson: payloadJson,
                irn: irn,
                ackNo: ackNo,
                signedQrCode: signedQrCode,
                isSynced: isSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> hlcTimestamp = const Value.absent(),
                Value<String> originNodeId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required String voucherNumber,
                required String voucherType,
                required String date,
                Value<String> series = const Value.absent(),
                required String partyName,
                required double grandTotal,
                required double subTotal,
                required double totalTax,
                required String payloadJson,
                Value<String?> irn = const Value.absent(),
                Value<String?> ackNo = const Value.absent(),
                Value<String?> signedQrCode = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VouchersTableCompanion.insert(
                id: id,
                hlcTimestamp: hlcTimestamp,
                originNodeId: originNodeId,
                isDeleted: isDeleted,
                voucherNumber: voucherNumber,
                voucherType: voucherType,
                date: date,
                series: series,
                partyName: partyName,
                grandTotal: grandTotal,
                subTotal: subTotal,
                totalTax: totalTax,
                payloadJson: payloadJson,
                irn: irn,
                ackNo: ackNo,
                signedQrCode: signedQrCode,
                isSynced: isSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VouchersTableTable, VouchersTableData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $VouchersTableTable,
                    VouchersTableData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VouchersTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VouchersTableTable,
      VouchersTableData,
      $$VouchersTableTableFilterComposer,
      $$VouchersTableTableOrderingComposer,
      $$VouchersTableTableAnnotationComposer,
      $$VouchersTableTableCreateCompanionBuilder,
      $$VouchersTableTableUpdateCompanionBuilder,
      (
        VouchersTableData,
        BaseReferences<_$AppDatabase, $VouchersTableTable, VouchersTableData>,
      ),
      VouchersTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$VouchersTableTableTableManager get vouchersTable =>
      $$VouchersTableTableTableManager(_db, _db.vouchersTable);
}
