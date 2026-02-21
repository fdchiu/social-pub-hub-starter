// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_db.dart';

// ignore_for_file: type=lint
class $SourceItemsTable extends SourceItems
    with TableInfo<$SourceItemsTable, SourceItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
      'url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userNoteMeta =
      const VerificationMeta('userNote');
  @override
  late final GeneratedColumn<String> userNote = GeneratedColumn<String>(
      'user_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>('tags', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>($SourceItemsTable.$convertertags);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, url, title, userNote, tags, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_items';
  @override
  VerificationContext validateIntegrity(Insertable<SourceItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
          _urlMeta, url.isAcceptableOrUnknown(data['url']!, _urlMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('user_note')) {
      context.handle(_userNoteMeta,
          userNote.isAcceptableOrUnknown(data['user_note']!, _userNoteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SourceItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      url: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      userNote: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_note']),
      tags: $SourceItemsTable.$convertertags.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SourceItemsTable createAlias(String alias) {
    return $SourceItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $convertertags =
      const StringListConverter();
}

class SourceItem extends DataClass implements Insertable<SourceItem> {
  final String id;
  final String type;
  final String? url;
  final String? title;
  final String? userNote;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SourceItem(
      {required this.id,
      required this.type,
      this.url,
      this.title,
      this.userNote,
      required this.tags,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || userNote != null) {
      map['user_note'] = Variable<String>(userNote);
    }
    {
      map['tags'] =
          Variable<String>($SourceItemsTable.$convertertags.toSql(tags));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SourceItemsCompanion toCompanion(bool nullToAbsent) {
    return SourceItemsCompanion(
      id: Value(id),
      type: Value(type),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      userNote: userNote == null && nullToAbsent
          ? const Value.absent()
          : Value(userNote),
      tags: Value(tags),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SourceItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceItem(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      url: serializer.fromJson<String?>(json['url']),
      title: serializer.fromJson<String?>(json['title']),
      userNote: serializer.fromJson<String?>(json['userNote']),
      tags: serializer.fromJson<List<String>>(json['tags']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'url': serializer.toJson<String?>(url),
      'title': serializer.toJson<String?>(title),
      'userNote': serializer.toJson<String?>(userNote),
      'tags': serializer.toJson<List<String>>(tags),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SourceItem copyWith(
          {String? id,
          String? type,
          Value<String?> url = const Value.absent(),
          Value<String?> title = const Value.absent(),
          Value<String?> userNote = const Value.absent(),
          List<String>? tags,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SourceItem(
        id: id ?? this.id,
        type: type ?? this.type,
        url: url.present ? url.value : this.url,
        title: title.present ? title.value : this.title,
        userNote: userNote.present ? userNote.value : this.userNote,
        tags: tags ?? this.tags,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SourceItem copyWithCompanion(SourceItemsCompanion data) {
    return SourceItem(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      url: data.url.present ? data.url.value : this.url,
      title: data.title.present ? data.title.value : this.title,
      userNote: data.userNote.present ? data.userNote.value : this.userNote,
      tags: data.tags.present ? data.tags.value : this.tags,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceItem(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('userNote: $userNote, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, url, title, userNote, tags, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceItem &&
          other.id == this.id &&
          other.type == this.type &&
          other.url == this.url &&
          other.title == this.title &&
          other.userNote == this.userNote &&
          other.tags == this.tags &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SourceItemsCompanion extends UpdateCompanion<SourceItem> {
  final Value<String> id;
  final Value<String> type;
  final Value<String?> url;
  final Value<String?> title;
  final Value<String?> userNote;
  final Value<List<String>> tags;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SourceItemsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.userNote = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceItemsCompanion.insert({
    required String id,
    required String type,
    this.url = const Value.absent(),
    this.title = const Value.absent(),
    this.userNote = const Value.absent(),
    this.tags = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type);
  static Insertable<SourceItem> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? url,
    Expression<String>? title,
    Expression<String>? userNote,
    Expression<String>? tags,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (url != null) 'url': url,
      if (title != null) 'title': title,
      if (userNote != null) 'user_note': userNote,
      if (tags != null) 'tags': tags,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String?>? url,
      Value<String?>? title,
      Value<String?>? userNote,
      Value<List<String>>? tags,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SourceItemsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      title: title ?? this.title,
      userNote: userNote ?? this.userNote,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (userNote.present) {
      map['user_note'] = Variable<String>(userNote.value);
    }
    if (tags.present) {
      map['tags'] =
          Variable<String>($SourceItemsTable.$convertertags.toSql(tags.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceItemsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('url: $url, ')
          ..write('title: $title, ')
          ..write('userNote: $userNote, ')
          ..write('tags: $tags, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _canonicalMarkdownMeta =
      const VerificationMeta('canonicalMarkdown');
  @override
  late final GeneratedColumn<String> canonicalMarkdown =
      GeneratedColumn<String>('canonical_markdown', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant(''));
  static const VerificationMeta _intentMeta = const VerificationMeta('intent');
  @override
  late final GeneratedColumn<String> intent = GeneratedColumn<String>(
      'intent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _toneMeta = const VerificationMeta('tone');
  @override
  late final GeneratedColumn<double> tone = GeneratedColumn<double>(
      'tone', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _punchinessMeta =
      const VerificationMeta('punchiness');
  @override
  late final GeneratedColumn<double> punchiness = GeneratedColumn<double>(
      'punchiness', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _emojiLevelMeta =
      const VerificationMeta('emojiLevel');
  @override
  late final GeneratedColumn<String> emojiLevel = GeneratedColumn<String>(
      'emoji_level', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _audienceMeta =
      const VerificationMeta('audience');
  @override
  late final GeneratedColumn<String> audience = GeneratedColumn<String>(
      'audience', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        canonicalMarkdown,
        intent,
        tone,
        punchiness,
        emojiLevel,
        audience,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(Insertable<Draft> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('canonical_markdown')) {
      context.handle(
          _canonicalMarkdownMeta,
          canonicalMarkdown.isAcceptableOrUnknown(
              data['canonical_markdown']!, _canonicalMarkdownMeta));
    }
    if (data.containsKey('intent')) {
      context.handle(_intentMeta,
          intent.isAcceptableOrUnknown(data['intent']!, _intentMeta));
    }
    if (data.containsKey('tone')) {
      context.handle(
          _toneMeta, tone.isAcceptableOrUnknown(data['tone']!, _toneMeta));
    }
    if (data.containsKey('punchiness')) {
      context.handle(
          _punchinessMeta,
          punchiness.isAcceptableOrUnknown(
              data['punchiness']!, _punchinessMeta));
    }
    if (data.containsKey('emoji_level')) {
      context.handle(
          _emojiLevelMeta,
          emojiLevel.isAcceptableOrUnknown(
              data['emoji_level']!, _emojiLevelMeta));
    }
    if (data.containsKey('audience')) {
      context.handle(_audienceMeta,
          audience.isAcceptableOrUnknown(data['audience']!, _audienceMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      canonicalMarkdown: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}canonical_markdown'])!,
      intent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}intent']),
      tone: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}tone']),
      punchiness: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}punchiness']),
      emojiLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji_level']),
      audience: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audience']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  final String id;
  final String canonicalMarkdown;
  final String? intent;
  final double? tone;
  final double? punchiness;
  final String? emojiLevel;
  final String? audience;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Draft(
      {required this.id,
      required this.canonicalMarkdown,
      this.intent,
      this.tone,
      this.punchiness,
      this.emojiLevel,
      this.audience,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['canonical_markdown'] = Variable<String>(canonicalMarkdown);
    if (!nullToAbsent || intent != null) {
      map['intent'] = Variable<String>(intent);
    }
    if (!nullToAbsent || tone != null) {
      map['tone'] = Variable<double>(tone);
    }
    if (!nullToAbsent || punchiness != null) {
      map['punchiness'] = Variable<double>(punchiness);
    }
    if (!nullToAbsent || emojiLevel != null) {
      map['emoji_level'] = Variable<String>(emojiLevel);
    }
    if (!nullToAbsent || audience != null) {
      map['audience'] = Variable<String>(audience);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      canonicalMarkdown: Value(canonicalMarkdown),
      intent:
          intent == null && nullToAbsent ? const Value.absent() : Value(intent),
      tone: tone == null && nullToAbsent ? const Value.absent() : Value(tone),
      punchiness: punchiness == null && nullToAbsent
          ? const Value.absent()
          : Value(punchiness),
      emojiLevel: emojiLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(emojiLevel),
      audience: audience == null && nullToAbsent
          ? const Value.absent()
          : Value(audience),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Draft.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      id: serializer.fromJson<String>(json['id']),
      canonicalMarkdown: serializer.fromJson<String>(json['canonicalMarkdown']),
      intent: serializer.fromJson<String?>(json['intent']),
      tone: serializer.fromJson<double?>(json['tone']),
      punchiness: serializer.fromJson<double?>(json['punchiness']),
      emojiLevel: serializer.fromJson<String?>(json['emojiLevel']),
      audience: serializer.fromJson<String?>(json['audience']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'canonicalMarkdown': serializer.toJson<String>(canonicalMarkdown),
      'intent': serializer.toJson<String?>(intent),
      'tone': serializer.toJson<double?>(tone),
      'punchiness': serializer.toJson<double?>(punchiness),
      'emojiLevel': serializer.toJson<String?>(emojiLevel),
      'audience': serializer.toJson<String?>(audience),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Draft copyWith(
          {String? id,
          String? canonicalMarkdown,
          Value<String?> intent = const Value.absent(),
          Value<double?> tone = const Value.absent(),
          Value<double?> punchiness = const Value.absent(),
          Value<String?> emojiLevel = const Value.absent(),
          Value<String?> audience = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Draft(
        id: id ?? this.id,
        canonicalMarkdown: canonicalMarkdown ?? this.canonicalMarkdown,
        intent: intent.present ? intent.value : this.intent,
        tone: tone.present ? tone.value : this.tone,
        punchiness: punchiness.present ? punchiness.value : this.punchiness,
        emojiLevel: emojiLevel.present ? emojiLevel.value : this.emojiLevel,
        audience: audience.present ? audience.value : this.audience,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      id: data.id.present ? data.id.value : this.id,
      canonicalMarkdown: data.canonicalMarkdown.present
          ? data.canonicalMarkdown.value
          : this.canonicalMarkdown,
      intent: data.intent.present ? data.intent.value : this.intent,
      tone: data.tone.present ? data.tone.value : this.tone,
      punchiness:
          data.punchiness.present ? data.punchiness.value : this.punchiness,
      emojiLevel:
          data.emojiLevel.present ? data.emojiLevel.value : this.emojiLevel,
      audience: data.audience.present ? data.audience.value : this.audience,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('id: $id, ')
          ..write('canonicalMarkdown: $canonicalMarkdown, ')
          ..write('intent: $intent, ')
          ..write('tone: $tone, ')
          ..write('punchiness: $punchiness, ')
          ..write('emojiLevel: $emojiLevel, ')
          ..write('audience: $audience, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, canonicalMarkdown, intent, tone,
      punchiness, emojiLevel, audience, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.id == this.id &&
          other.canonicalMarkdown == this.canonicalMarkdown &&
          other.intent == this.intent &&
          other.tone == this.tone &&
          other.punchiness == this.punchiness &&
          other.emojiLevel == this.emojiLevel &&
          other.audience == this.audience &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<String> id;
  final Value<String> canonicalMarkdown;
  final Value<String?> intent;
  final Value<double?> tone;
  final Value<double?> punchiness;
  final Value<String?> emojiLevel;
  final Value<String?> audience;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.canonicalMarkdown = const Value.absent(),
    this.intent = const Value.absent(),
    this.tone = const Value.absent(),
    this.punchiness = const Value.absent(),
    this.emojiLevel = const Value.absent(),
    this.audience = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String id,
    this.canonicalMarkdown = const Value.absent(),
    this.intent = const Value.absent(),
    this.tone = const Value.absent(),
    this.punchiness = const Value.absent(),
    this.emojiLevel = const Value.absent(),
    this.audience = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<Draft> custom({
    Expression<String>? id,
    Expression<String>? canonicalMarkdown,
    Expression<String>? intent,
    Expression<double>? tone,
    Expression<double>? punchiness,
    Expression<String>? emojiLevel,
    Expression<String>? audience,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canonicalMarkdown != null) 'canonical_markdown': canonicalMarkdown,
      if (intent != null) 'intent': intent,
      if (tone != null) 'tone': tone,
      if (punchiness != null) 'punchiness': punchiness,
      if (emojiLevel != null) 'emoji_level': emojiLevel,
      if (audience != null) 'audience': audience,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith(
      {Value<String>? id,
      Value<String>? canonicalMarkdown,
      Value<String?>? intent,
      Value<double?>? tone,
      Value<double?>? punchiness,
      Value<String?>? emojiLevel,
      Value<String?>? audience,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return DraftsCompanion(
      id: id ?? this.id,
      canonicalMarkdown: canonicalMarkdown ?? this.canonicalMarkdown,
      intent: intent ?? this.intent,
      tone: tone ?? this.tone,
      punchiness: punchiness ?? this.punchiness,
      emojiLevel: emojiLevel ?? this.emojiLevel,
      audience: audience ?? this.audience,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (canonicalMarkdown.present) {
      map['canonical_markdown'] = Variable<String>(canonicalMarkdown.value);
    }
    if (intent.present) {
      map['intent'] = Variable<String>(intent.value);
    }
    if (tone.present) {
      map['tone'] = Variable<double>(tone.value);
    }
    if (punchiness.present) {
      map['punchiness'] = Variable<double>(punchiness.value);
    }
    if (emojiLevel.present) {
      map['emoji_level'] = Variable<String>(emojiLevel.value);
    }
    if (audience.present) {
      map['audience'] = Variable<String>(audience.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('canonicalMarkdown: $canonicalMarkdown, ')
          ..write('intent: $intent, ')
          ..write('tone: $tone, ')
          ..write('punchiness: $punchiness, ')
          ..write('emojiLevel: $emojiLevel, ')
          ..write('audience: $audience, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VariantsTable extends Variants with TableInfo<$VariantsTable, Variant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _draftIdMeta =
      const VerificationMeta('draftId');
  @override
  late final GeneratedColumn<String> draftId = GeneratedColumn<String>(
      'draft_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES drafts (id)'));
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, draftId, platform, body, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variants';
  @override
  VerificationContext validateIntegrity(Insertable<Variant> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('draft_id')) {
      context.handle(_draftIdMeta,
          draftId.isAcceptableOrUnknown(data['draft_id']!, _draftIdMeta));
    } else if (isInserting) {
      context.missing(_draftIdMeta);
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['text']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Variant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Variant(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      draftId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}draft_id'])!,
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}text'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VariantsTable createAlias(String alias) {
    return $VariantsTable(attachedDatabase, alias);
  }
}

class Variant extends DataClass implements Insertable<Variant> {
  final String id;
  final String draftId;
  final String platform;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Variant(
      {required this.id,
      required this.draftId,
      required this.platform,
      required this.body,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['draft_id'] = Variable<String>(draftId);
    map['platform'] = Variable<String>(platform);
    map['text'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VariantsCompanion toCompanion(bool nullToAbsent) {
    return VariantsCompanion(
      id: Value(id),
      draftId: Value(draftId),
      platform: Value(platform),
      body: Value(body),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Variant.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Variant(
      id: serializer.fromJson<String>(json['id']),
      draftId: serializer.fromJson<String>(json['draftId']),
      platform: serializer.fromJson<String>(json['platform']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'draftId': serializer.toJson<String>(draftId),
      'platform': serializer.toJson<String>(platform),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Variant copyWith(
          {String? id,
          String? draftId,
          String? platform,
          String? body,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Variant(
        id: id ?? this.id,
        draftId: draftId ?? this.draftId,
        platform: platform ?? this.platform,
        body: body ?? this.body,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Variant copyWithCompanion(VariantsCompanion data) {
    return Variant(
      id: data.id.present ? data.id.value : this.id,
      draftId: data.draftId.present ? data.draftId.value : this.draftId,
      platform: data.platform.present ? data.platform.value : this.platform,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Variant(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('platform: $platform, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, draftId, platform, body, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Variant &&
          other.id == this.id &&
          other.draftId == this.draftId &&
          other.platform == this.platform &&
          other.body == this.body &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VariantsCompanion extends UpdateCompanion<Variant> {
  final Value<String> id;
  final Value<String> draftId;
  final Value<String> platform;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VariantsCompanion({
    this.id = const Value.absent(),
    this.draftId = const Value.absent(),
    this.platform = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VariantsCompanion.insert({
    required String id,
    required String draftId,
    required String platform,
    required String body,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        draftId = Value(draftId),
        platform = Value(platform),
        body = Value(body);
  static Insertable<Variant> custom({
    Expression<String>? id,
    Expression<String>? draftId,
    Expression<String>? platform,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (draftId != null) 'draft_id': draftId,
      if (platform != null) 'platform': platform,
      if (body != null) 'text': body,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VariantsCompanion copyWith(
      {Value<String>? id,
      Value<String>? draftId,
      Value<String>? platform,
      Value<String>? body,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VariantsCompanion(
      id: id ?? this.id,
      draftId: draftId ?? this.draftId,
      platform: platform ?? this.platform,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (draftId.present) {
      map['draft_id'] = Variable<String>(draftId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariantsCompanion(')
          ..write('id: $id, ')
          ..write('draftId: $draftId, ')
          ..write('platform: $platform, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PublishLogsTable extends PublishLogs
    with TableInfo<$PublishLogsTable, PublishLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PublishLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _variantIdMeta =
      const VerificationMeta('variantId');
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
      'variant_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES variants (id)'));
  static const VerificationMeta _platformMeta =
      const VerificationMeta('platform');
  @override
  late final GeneratedColumn<String> platform = GeneratedColumn<String>(
      'platform', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('draft'));
  static const VerificationMeta _externalUrlMeta =
      const VerificationMeta('externalUrl');
  @override
  late final GeneratedColumn<String> externalUrl = GeneratedColumn<String>(
      'external_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _postedAtMeta =
      const VerificationMeta('postedAt');
  @override
  late final GeneratedColumn<DateTime> postedAt = GeneratedColumn<DateTime>(
      'posted_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, variantId, platform, mode, status, externalUrl, postedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'publish_logs';
  @override
  VerificationContext validateIntegrity(Insertable<PublishLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(_variantIdMeta,
          variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta));
    }
    if (data.containsKey('platform')) {
      context.handle(_platformMeta,
          platform.isAcceptableOrUnknown(data['platform']!, _platformMeta));
    } else if (isInserting) {
      context.missing(_platformMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('external_url')) {
      context.handle(
          _externalUrlMeta,
          externalUrl.isAcceptableOrUnknown(
              data['external_url']!, _externalUrlMeta));
    }
    if (data.containsKey('posted_at')) {
      context.handle(_postedAtMeta,
          postedAt.isAcceptableOrUnknown(data['posted_at']!, _postedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PublishLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PublishLog(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      variantId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}variant_id']),
      platform: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}platform'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      externalUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_url']),
      postedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}posted_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PublishLogsTable createAlias(String alias) {
    return $PublishLogsTable(attachedDatabase, alias);
  }
}

class PublishLog extends DataClass implements Insertable<PublishLog> {
  final String id;
  final String? variantId;
  final String platform;
  final String mode;
  final String status;
  final String? externalUrl;
  final DateTime? postedAt;
  final DateTime createdAt;
  const PublishLog(
      {required this.id,
      this.variantId,
      required this.platform,
      required this.mode,
      required this.status,
      this.externalUrl,
      this.postedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    map['platform'] = Variable<String>(platform);
    map['mode'] = Variable<String>(mode);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || externalUrl != null) {
      map['external_url'] = Variable<String>(externalUrl);
    }
    if (!nullToAbsent || postedAt != null) {
      map['posted_at'] = Variable<DateTime>(postedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PublishLogsCompanion toCompanion(bool nullToAbsent) {
    return PublishLogsCompanion(
      id: Value(id),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      platform: Value(platform),
      mode: Value(mode),
      status: Value(status),
      externalUrl: externalUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(externalUrl),
      postedAt: postedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(postedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PublishLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PublishLog(
      id: serializer.fromJson<String>(json['id']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      platform: serializer.fromJson<String>(json['platform']),
      mode: serializer.fromJson<String>(json['mode']),
      status: serializer.fromJson<String>(json['status']),
      externalUrl: serializer.fromJson<String?>(json['externalUrl']),
      postedAt: serializer.fromJson<DateTime?>(json['postedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'variantId': serializer.toJson<String?>(variantId),
      'platform': serializer.toJson<String>(platform),
      'mode': serializer.toJson<String>(mode),
      'status': serializer.toJson<String>(status),
      'externalUrl': serializer.toJson<String?>(externalUrl),
      'postedAt': serializer.toJson<DateTime?>(postedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PublishLog copyWith(
          {String? id,
          Value<String?> variantId = const Value.absent(),
          String? platform,
          String? mode,
          String? status,
          Value<String?> externalUrl = const Value.absent(),
          Value<DateTime?> postedAt = const Value.absent(),
          DateTime? createdAt}) =>
      PublishLog(
        id: id ?? this.id,
        variantId: variantId.present ? variantId.value : this.variantId,
        platform: platform ?? this.platform,
        mode: mode ?? this.mode,
        status: status ?? this.status,
        externalUrl: externalUrl.present ? externalUrl.value : this.externalUrl,
        postedAt: postedAt.present ? postedAt.value : this.postedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  PublishLog copyWithCompanion(PublishLogsCompanion data) {
    return PublishLog(
      id: data.id.present ? data.id.value : this.id,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      platform: data.platform.present ? data.platform.value : this.platform,
      mode: data.mode.present ? data.mode.value : this.mode,
      status: data.status.present ? data.status.value : this.status,
      externalUrl:
          data.externalUrl.present ? data.externalUrl.value : this.externalUrl,
      postedAt: data.postedAt.present ? data.postedAt.value : this.postedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PublishLog(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('platform: $platform, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('postedAt: $postedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, variantId, platform, mode, status, externalUrl, postedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PublishLog &&
          other.id == this.id &&
          other.variantId == this.variantId &&
          other.platform == this.platform &&
          other.mode == this.mode &&
          other.status == this.status &&
          other.externalUrl == this.externalUrl &&
          other.postedAt == this.postedAt &&
          other.createdAt == this.createdAt);
}

class PublishLogsCompanion extends UpdateCompanion<PublishLog> {
  final Value<String> id;
  final Value<String?> variantId;
  final Value<String> platform;
  final Value<String> mode;
  final Value<String> status;
  final Value<String?> externalUrl;
  final Value<DateTime?> postedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PublishLogsCompanion({
    this.id = const Value.absent(),
    this.variantId = const Value.absent(),
    this.platform = const Value.absent(),
    this.mode = const Value.absent(),
    this.status = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PublishLogsCompanion.insert({
    required String id,
    this.variantId = const Value.absent(),
    required String platform,
    required String mode,
    this.status = const Value.absent(),
    this.externalUrl = const Value.absent(),
    this.postedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        platform = Value(platform),
        mode = Value(mode);
  static Insertable<PublishLog> custom({
    Expression<String>? id,
    Expression<String>? variantId,
    Expression<String>? platform,
    Expression<String>? mode,
    Expression<String>? status,
    Expression<String>? externalUrl,
    Expression<DateTime>? postedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (variantId != null) 'variant_id': variantId,
      if (platform != null) 'platform': platform,
      if (mode != null) 'mode': mode,
      if (status != null) 'status': status,
      if (externalUrl != null) 'external_url': externalUrl,
      if (postedAt != null) 'posted_at': postedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PublishLogsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? variantId,
      Value<String>? platform,
      Value<String>? mode,
      Value<String>? status,
      Value<String?>? externalUrl,
      Value<DateTime?>? postedAt,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PublishLogsCompanion(
      id: id ?? this.id,
      variantId: variantId ?? this.variantId,
      platform: platform ?? this.platform,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      externalUrl: externalUrl ?? this.externalUrl,
      postedAt: postedAt ?? this.postedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (platform.present) {
      map['platform'] = Variable<String>(platform.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (externalUrl.present) {
      map['external_url'] = Variable<String>(externalUrl.value);
    }
    if (postedAt.present) {
      map['posted_at'] = Variable<DateTime>(postedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PublishLogsCompanion(')
          ..write('id: $id, ')
          ..write('variantId: $variantId, ')
          ..write('platform: $platform, ')
          ..write('mode: $mode, ')
          ..write('status: $status, ')
          ..write('externalUrl: $externalUrl, ')
          ..write('postedAt: $postedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StyleProfilesTable extends StyleProfiles
    with TableInfo<$StyleProfilesTable, StyleProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StyleProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _voiceNameMeta =
      const VerificationMeta('voiceName');
  @override
  late final GeneratedColumn<String> voiceName = GeneratedColumn<String>(
      'voice_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('David'));
  static const VerificationMeta _casualFormalMeta =
      const VerificationMeta('casualFormal');
  @override
  late final GeneratedColumn<double> casualFormal = GeneratedColumn<double>(
      'casual_formal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.6));
  static const VerificationMeta _punchinessMeta =
      const VerificationMeta('punchiness');
  @override
  late final GeneratedColumn<double> punchiness = GeneratedColumn<double>(
      'punchiness', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.7));
  static const VerificationMeta _emojiLevelMeta =
      const VerificationMeta('emojiLevel');
  @override
  late final GeneratedColumn<String> emojiLevel = GeneratedColumn<String>(
      'emoji_level', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('light'));
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String>
      bannedPhrases = GeneratedColumn<String>(
              'banned_phrases', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>(
              $StyleProfilesTable.$converterbannedPhrases);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        voiceName,
        casualFormal,
        punchiness,
        emojiLevel,
        bannedPhrases,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'style_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<StyleProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('voice_name')) {
      context.handle(_voiceNameMeta,
          voiceName.isAcceptableOrUnknown(data['voice_name']!, _voiceNameMeta));
    }
    if (data.containsKey('casual_formal')) {
      context.handle(
          _casualFormalMeta,
          casualFormal.isAcceptableOrUnknown(
              data['casual_formal']!, _casualFormalMeta));
    }
    if (data.containsKey('punchiness')) {
      context.handle(
          _punchinessMeta,
          punchiness.isAcceptableOrUnknown(
              data['punchiness']!, _punchinessMeta));
    }
    if (data.containsKey('emoji_level')) {
      context.handle(
          _emojiLevelMeta,
          emojiLevel.isAcceptableOrUnknown(
              data['emoji_level']!, _emojiLevelMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StyleProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StyleProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      voiceName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voice_name'])!,
      casualFormal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}casual_formal'])!,
      punchiness: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}punchiness'])!,
      emojiLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}emoji_level'])!,
      bannedPhrases: $StyleProfilesTable.$converterbannedPhrases.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}banned_phrases'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $StyleProfilesTable createAlias(String alias) {
    return $StyleProfilesTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterbannedPhrases =
      const StringListConverter();
}

class StyleProfile extends DataClass implements Insertable<StyleProfile> {
  final String id;
  final String voiceName;
  final double casualFormal;
  final double punchiness;
  final String emojiLevel;
  final List<String> bannedPhrases;
  final DateTime createdAt;
  final DateTime updatedAt;
  const StyleProfile(
      {required this.id,
      required this.voiceName,
      required this.casualFormal,
      required this.punchiness,
      required this.emojiLevel,
      required this.bannedPhrases,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['voice_name'] = Variable<String>(voiceName);
    map['casual_formal'] = Variable<double>(casualFormal);
    map['punchiness'] = Variable<double>(punchiness);
    map['emoji_level'] = Variable<String>(emojiLevel);
    {
      map['banned_phrases'] = Variable<String>(
          $StyleProfilesTable.$converterbannedPhrases.toSql(bannedPhrases));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  StyleProfilesCompanion toCompanion(bool nullToAbsent) {
    return StyleProfilesCompanion(
      id: Value(id),
      voiceName: Value(voiceName),
      casualFormal: Value(casualFormal),
      punchiness: Value(punchiness),
      emojiLevel: Value(emojiLevel),
      bannedPhrases: Value(bannedPhrases),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory StyleProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StyleProfile(
      id: serializer.fromJson<String>(json['id']),
      voiceName: serializer.fromJson<String>(json['voiceName']),
      casualFormal: serializer.fromJson<double>(json['casualFormal']),
      punchiness: serializer.fromJson<double>(json['punchiness']),
      emojiLevel: serializer.fromJson<String>(json['emojiLevel']),
      bannedPhrases: serializer.fromJson<List<String>>(json['bannedPhrases']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'voiceName': serializer.toJson<String>(voiceName),
      'casualFormal': serializer.toJson<double>(casualFormal),
      'punchiness': serializer.toJson<double>(punchiness),
      'emojiLevel': serializer.toJson<String>(emojiLevel),
      'bannedPhrases': serializer.toJson<List<String>>(bannedPhrases),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  StyleProfile copyWith(
          {String? id,
          String? voiceName,
          double? casualFormal,
          double? punchiness,
          String? emojiLevel,
          List<String>? bannedPhrases,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      StyleProfile(
        id: id ?? this.id,
        voiceName: voiceName ?? this.voiceName,
        casualFormal: casualFormal ?? this.casualFormal,
        punchiness: punchiness ?? this.punchiness,
        emojiLevel: emojiLevel ?? this.emojiLevel,
        bannedPhrases: bannedPhrases ?? this.bannedPhrases,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  StyleProfile copyWithCompanion(StyleProfilesCompanion data) {
    return StyleProfile(
      id: data.id.present ? data.id.value : this.id,
      voiceName: data.voiceName.present ? data.voiceName.value : this.voiceName,
      casualFormal: data.casualFormal.present
          ? data.casualFormal.value
          : this.casualFormal,
      punchiness:
          data.punchiness.present ? data.punchiness.value : this.punchiness,
      emojiLevel:
          data.emojiLevel.present ? data.emojiLevel.value : this.emojiLevel,
      bannedPhrases: data.bannedPhrases.present
          ? data.bannedPhrases.value
          : this.bannedPhrases,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StyleProfile(')
          ..write('id: $id, ')
          ..write('voiceName: $voiceName, ')
          ..write('casualFormal: $casualFormal, ')
          ..write('punchiness: $punchiness, ')
          ..write('emojiLevel: $emojiLevel, ')
          ..write('bannedPhrases: $bannedPhrases, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, voiceName, casualFormal, punchiness,
      emojiLevel, bannedPhrases, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StyleProfile &&
          other.id == this.id &&
          other.voiceName == this.voiceName &&
          other.casualFormal == this.casualFormal &&
          other.punchiness == this.punchiness &&
          other.emojiLevel == this.emojiLevel &&
          other.bannedPhrases == this.bannedPhrases &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StyleProfilesCompanion extends UpdateCompanion<StyleProfile> {
  final Value<String> id;
  final Value<String> voiceName;
  final Value<double> casualFormal;
  final Value<double> punchiness;
  final Value<String> emojiLevel;
  final Value<List<String>> bannedPhrases;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const StyleProfilesCompanion({
    this.id = const Value.absent(),
    this.voiceName = const Value.absent(),
    this.casualFormal = const Value.absent(),
    this.punchiness = const Value.absent(),
    this.emojiLevel = const Value.absent(),
    this.bannedPhrases = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StyleProfilesCompanion.insert({
    required String id,
    this.voiceName = const Value.absent(),
    this.casualFormal = const Value.absent(),
    this.punchiness = const Value.absent(),
    this.emojiLevel = const Value.absent(),
    this.bannedPhrases = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<StyleProfile> custom({
    Expression<String>? id,
    Expression<String>? voiceName,
    Expression<double>? casualFormal,
    Expression<double>? punchiness,
    Expression<String>? emojiLevel,
    Expression<String>? bannedPhrases,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (voiceName != null) 'voice_name': voiceName,
      if (casualFormal != null) 'casual_formal': casualFormal,
      if (punchiness != null) 'punchiness': punchiness,
      if (emojiLevel != null) 'emoji_level': emojiLevel,
      if (bannedPhrases != null) 'banned_phrases': bannedPhrases,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StyleProfilesCompanion copyWith(
      {Value<String>? id,
      Value<String>? voiceName,
      Value<double>? casualFormal,
      Value<double>? punchiness,
      Value<String>? emojiLevel,
      Value<List<String>>? bannedPhrases,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return StyleProfilesCompanion(
      id: id ?? this.id,
      voiceName: voiceName ?? this.voiceName,
      casualFormal: casualFormal ?? this.casualFormal,
      punchiness: punchiness ?? this.punchiness,
      emojiLevel: emojiLevel ?? this.emojiLevel,
      bannedPhrases: bannedPhrases ?? this.bannedPhrases,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (voiceName.present) {
      map['voice_name'] = Variable<String>(voiceName.value);
    }
    if (casualFormal.present) {
      map['casual_formal'] = Variable<double>(casualFormal.value);
    }
    if (punchiness.present) {
      map['punchiness'] = Variable<double>(punchiness.value);
    }
    if (emojiLevel.present) {
      map['emoji_level'] = Variable<String>(emojiLevel.value);
    }
    if (bannedPhrases.present) {
      map['banned_phrases'] = Variable<String>($StyleProfilesTable
          .$converterbannedPhrases
          .toSql(bannedPhrases.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StyleProfilesCompanion(')
          ..write('id: $id, ')
          ..write('voiceName: $voiceName, ')
          ..write('casualFormal: $casualFormal, ')
          ..write('punchiness: $punchiness, ')
          ..write('emojiLevel: $emojiLevel, ')
          ..write('bannedPhrases: $bannedPhrases, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SourceItemsTable sourceItems = $SourceItemsTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $VariantsTable variants = $VariantsTable(this);
  late final $PublishLogsTable publishLogs = $PublishLogsTable(this);
  late final $StyleProfilesTable styleProfiles = $StyleProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [sourceItems, drafts, variants, publishLogs, styleProfiles];
}

typedef $$SourceItemsTableCreateCompanionBuilder = SourceItemsCompanion
    Function({
  required String id,
  required String type,
  Value<String?> url,
  Value<String?> title,
  Value<String?> userNote,
  Value<List<String>> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$SourceItemsTableUpdateCompanionBuilder = SourceItemsCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String?> url,
  Value<String?> title,
  Value<String?> userNote,
  Value<List<String>> tags,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SourceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SourceItemsTable> {
  $$SourceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userNote => $composableBuilder(
      column: $table.userNote, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
          column: $table.tags,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SourceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SourceItemsTable> {
  $$SourceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userNote => $composableBuilder(
      column: $table.userNote, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SourceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourceItemsTable> {
  $$SourceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get userNote =>
      $composableBuilder(column: $table.userNote, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SourceItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SourceItemsTable,
    SourceItem,
    $$SourceItemsTableFilterComposer,
    $$SourceItemsTableOrderingComposer,
    $$SourceItemsTableAnnotationComposer,
    $$SourceItemsTableCreateCompanionBuilder,
    $$SourceItemsTableUpdateCompanionBuilder,
    (SourceItem, BaseReferences<_$AppDatabase, $SourceItemsTable, SourceItem>),
    SourceItem,
    PrefetchHooks Function()> {
  $$SourceItemsTableTableManager(_$AppDatabase db, $SourceItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String?> url = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> userNote = const Value.absent(),
            Value<List<String>> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SourceItemsCompanion(
            id: id,
            type: type,
            url: url,
            title: title,
            userNote: userNote,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            Value<String?> url = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String?> userNote = const Value.absent(),
            Value<List<String>> tags = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SourceItemsCompanion.insert(
            id: id,
            type: type,
            url: url,
            title: title,
            userNote: userNote,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SourceItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SourceItemsTable,
    SourceItem,
    $$SourceItemsTableFilterComposer,
    $$SourceItemsTableOrderingComposer,
    $$SourceItemsTableAnnotationComposer,
    $$SourceItemsTableCreateCompanionBuilder,
    $$SourceItemsTableUpdateCompanionBuilder,
    (SourceItem, BaseReferences<_$AppDatabase, $SourceItemsTable, SourceItem>),
    SourceItem,
    PrefetchHooks Function()>;
typedef $$DraftsTableCreateCompanionBuilder = DraftsCompanion Function({
  required String id,
  Value<String> canonicalMarkdown,
  Value<String?> intent,
  Value<double?> tone,
  Value<double?> punchiness,
  Value<String?> emojiLevel,
  Value<String?> audience,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$DraftsTableUpdateCompanionBuilder = DraftsCompanion Function({
  Value<String> id,
  Value<String> canonicalMarkdown,
  Value<String?> intent,
  Value<double?> tone,
  Value<double?> punchiness,
  Value<String?> emojiLevel,
  Value<String?> audience,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$DraftsTableReferences
    extends BaseReferences<_$AppDatabase, $DraftsTable, Draft> {
  $$DraftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$VariantsTable, List<Variant>> _variantsRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.variants,
          aliasName: $_aliasNameGenerator(db.drafts.id, db.variants.draftId));

  $$VariantsTableProcessedTableManager get variantsRefs {
    final manager = $$VariantsTableTableManager($_db, $_db.variants)
        .filter((f) => f.draftId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_variantsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalMarkdown => $composableBuilder(
      column: $table.canonicalMarkdown,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get intent => $composableBuilder(
      column: $table.intent, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get tone => $composableBuilder(
      column: $table.tone, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get audience => $composableBuilder(
      column: $table.audience, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> variantsRefs(
      Expression<bool> Function($$VariantsTableFilterComposer f) f) {
    final $$VariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.variants,
        getReferencedColumn: (t) => t.draftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VariantsTableFilterComposer(
              $db: $db,
              $table: $db.variants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalMarkdown => $composableBuilder(
      column: $table.canonicalMarkdown,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get intent => $composableBuilder(
      column: $table.intent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get tone => $composableBuilder(
      column: $table.tone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get audience => $composableBuilder(
      column: $table.audience, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canonicalMarkdown => $composableBuilder(
      column: $table.canonicalMarkdown, builder: (column) => column);

  GeneratedColumn<String> get intent =>
      $composableBuilder(column: $table.intent, builder: (column) => column);

  GeneratedColumn<double> get tone =>
      $composableBuilder(column: $table.tone, builder: (column) => column);

  GeneratedColumn<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => column);

  GeneratedColumn<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => column);

  GeneratedColumn<String> get audience =>
      $composableBuilder(column: $table.audience, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> variantsRefs<T extends Object>(
      Expression<T> Function($$VariantsTableAnnotationComposer a) f) {
    final $$VariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.variants,
        getReferencedColumn: (t) => t.draftId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.variants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$DraftsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DraftsTable,
    Draft,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (Draft, $$DraftsTableReferences),
    Draft,
    PrefetchHooks Function({bool variantsRefs})> {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> canonicalMarkdown = const Value.absent(),
            Value<String?> intent = const Value.absent(),
            Value<double?> tone = const Value.absent(),
            Value<double?> punchiness = const Value.absent(),
            Value<String?> emojiLevel = const Value.absent(),
            Value<String?> audience = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DraftsCompanion(
            id: id,
            canonicalMarkdown: canonicalMarkdown,
            intent: intent,
            tone: tone,
            punchiness: punchiness,
            emojiLevel: emojiLevel,
            audience: audience,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> canonicalMarkdown = const Value.absent(),
            Value<String?> intent = const Value.absent(),
            Value<double?> tone = const Value.absent(),
            Value<double?> punchiness = const Value.absent(),
            Value<String?> emojiLevel = const Value.absent(),
            Value<String?> audience = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DraftsCompanion.insert(
            id: id,
            canonicalMarkdown: canonicalMarkdown,
            intent: intent,
            tone: tone,
            punchiness: punchiness,
            emojiLevel: emojiLevel,
            audience: audience,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$DraftsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({variantsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (variantsRefs) db.variants],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (variantsRefs)
                    await $_getPrefetchedData<Draft, $DraftsTable, Variant>(
                        currentTable: table,
                        referencedTable:
                            $$DraftsTableReferences._variantsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$DraftsTableReferences(db, table, p0).variantsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.draftId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$DraftsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DraftsTable,
    Draft,
    $$DraftsTableFilterComposer,
    $$DraftsTableOrderingComposer,
    $$DraftsTableAnnotationComposer,
    $$DraftsTableCreateCompanionBuilder,
    $$DraftsTableUpdateCompanionBuilder,
    (Draft, $$DraftsTableReferences),
    Draft,
    PrefetchHooks Function({bool variantsRefs})>;
typedef $$VariantsTableCreateCompanionBuilder = VariantsCompanion Function({
  required String id,
  required String draftId,
  required String platform,
  required String body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$VariantsTableUpdateCompanionBuilder = VariantsCompanion Function({
  Value<String> id,
  Value<String> draftId,
  Value<String> platform,
  Value<String> body,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$VariantsTableReferences
    extends BaseReferences<_$AppDatabase, $VariantsTable, Variant> {
  $$VariantsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DraftsTable _draftIdTable(_$AppDatabase db) => db.drafts
      .createAlias($_aliasNameGenerator(db.variants.draftId, db.drafts.id));

  $$DraftsTableProcessedTableManager get draftId {
    final $_column = $_itemColumn<String>('draft_id')!;

    final manager = $$DraftsTableTableManager($_db, $_db.drafts)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_draftIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PublishLogsTable, List<PublishLog>>
      _publishLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.publishLogs,
          aliasName:
              $_aliasNameGenerator(db.variants.id, db.publishLogs.variantId));

  $$PublishLogsTableProcessedTableManager get publishLogsRefs {
    final manager = $$PublishLogsTableTableManager($_db, $_db.publishLogs)
        .filter((f) => f.variantId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_publishLogsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$VariantsTableFilterComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$DraftsTableFilterComposer get draftId {
    final $$DraftsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.draftId,
        referencedTable: $db.drafts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DraftsTableFilterComposer(
              $db: $db,
              $table: $db.drafts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> publishLogsRefs(
      Expression<bool> Function($$PublishLogsTableFilterComposer f) f) {
    final $$PublishLogsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.publishLogs,
        getReferencedColumn: (t) => t.variantId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PublishLogsTableFilterComposer(
              $db: $db,
              $table: $db.publishLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$DraftsTableOrderingComposer get draftId {
    final $$DraftsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.draftId,
        referencedTable: $db.drafts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DraftsTableOrderingComposer(
              $db: $db,
              $table: $db.drafts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$VariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VariantsTable> {
  $$VariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DraftsTableAnnotationComposer get draftId {
    final $$DraftsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.draftId,
        referencedTable: $db.drafts,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$DraftsTableAnnotationComposer(
              $db: $db,
              $table: $db.drafts,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> publishLogsRefs<T extends Object>(
      Expression<T> Function($$PublishLogsTableAnnotationComposer a) f) {
    final $$PublishLogsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.publishLogs,
        getReferencedColumn: (t) => t.variantId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PublishLogsTableAnnotationComposer(
              $db: $db,
              $table: $db.publishLogs,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$VariantsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VariantsTable,
    Variant,
    $$VariantsTableFilterComposer,
    $$VariantsTableOrderingComposer,
    $$VariantsTableAnnotationComposer,
    $$VariantsTableCreateCompanionBuilder,
    $$VariantsTableUpdateCompanionBuilder,
    (Variant, $$VariantsTableReferences),
    Variant,
    PrefetchHooks Function({bool draftId, bool publishLogsRefs})> {
  $$VariantsTableTableManager(_$AppDatabase db, $VariantsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> draftId = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VariantsCompanion(
            id: id,
            draftId: draftId,
            platform: platform,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String draftId,
            required String platform,
            required String body,
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VariantsCompanion.insert(
            id: id,
            draftId: draftId,
            platform: platform,
            body: body,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$VariantsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({draftId = false, publishLogsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (publishLogsRefs) db.publishLogs],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (draftId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.draftId,
                    referencedTable:
                        $$VariantsTableReferences._draftIdTable(db),
                    referencedColumn:
                        $$VariantsTableReferences._draftIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (publishLogsRefs)
                    await $_getPrefetchedData<Variant, $VariantsTable,
                            PublishLog>(
                        currentTable: table,
                        referencedTable:
                            $$VariantsTableReferences._publishLogsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$VariantsTableReferences(db, table, p0)
                                .publishLogsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.variantId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$VariantsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VariantsTable,
    Variant,
    $$VariantsTableFilterComposer,
    $$VariantsTableOrderingComposer,
    $$VariantsTableAnnotationComposer,
    $$VariantsTableCreateCompanionBuilder,
    $$VariantsTableUpdateCompanionBuilder,
    (Variant, $$VariantsTableReferences),
    Variant,
    PrefetchHooks Function({bool draftId, bool publishLogsRefs})>;
typedef $$PublishLogsTableCreateCompanionBuilder = PublishLogsCompanion
    Function({
  required String id,
  Value<String?> variantId,
  required String platform,
  required String mode,
  Value<String> status,
  Value<String?> externalUrl,
  Value<DateTime?> postedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$PublishLogsTableUpdateCompanionBuilder = PublishLogsCompanion
    Function({
  Value<String> id,
  Value<String?> variantId,
  Value<String> platform,
  Value<String> mode,
  Value<String> status,
  Value<String?> externalUrl,
  Value<DateTime?> postedAt,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

final class $$PublishLogsTableReferences
    extends BaseReferences<_$AppDatabase, $PublishLogsTable, PublishLog> {
  $$PublishLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $VariantsTable _variantIdTable(_$AppDatabase db) =>
      db.variants.createAlias(
          $_aliasNameGenerator(db.publishLogs.variantId, db.variants.id));

  $$VariantsTableProcessedTableManager? get variantId {
    final $_column = $_itemColumn<String>('variant_id');
    if ($_column == null) return null;
    final manager = $$VariantsTableTableManager($_db, $_db.variants)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_variantIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PublishLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PublishLogsTable> {
  $$PublishLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalUrl => $composableBuilder(
      column: $table.externalUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$VariantsTableFilterComposer get variantId {
    final $$VariantsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.variantId,
        referencedTable: $db.variants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VariantsTableFilterComposer(
              $db: $db,
              $table: $db.variants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PublishLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PublishLogsTable> {
  $$PublishLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get platform => $composableBuilder(
      column: $table.platform, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalUrl => $composableBuilder(
      column: $table.externalUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get postedAt => $composableBuilder(
      column: $table.postedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$VariantsTableOrderingComposer get variantId {
    final $$VariantsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.variantId,
        referencedTable: $db.variants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VariantsTableOrderingComposer(
              $db: $db,
              $table: $db.variants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PublishLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PublishLogsTable> {
  $$PublishLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get platform =>
      $composableBuilder(column: $table.platform, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get externalUrl => $composableBuilder(
      column: $table.externalUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get postedAt =>
      $composableBuilder(column: $table.postedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$VariantsTableAnnotationComposer get variantId {
    final $$VariantsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.variantId,
        referencedTable: $db.variants,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$VariantsTableAnnotationComposer(
              $db: $db,
              $table: $db.variants,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$PublishLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PublishLogsTable,
    PublishLog,
    $$PublishLogsTableFilterComposer,
    $$PublishLogsTableOrderingComposer,
    $$PublishLogsTableAnnotationComposer,
    $$PublishLogsTableCreateCompanionBuilder,
    $$PublishLogsTableUpdateCompanionBuilder,
    (PublishLog, $$PublishLogsTableReferences),
    PublishLog,
    PrefetchHooks Function({bool variantId})> {
  $$PublishLogsTableTableManager(_$AppDatabase db, $PublishLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PublishLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PublishLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PublishLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> variantId = const Value.absent(),
            Value<String> platform = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> externalUrl = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PublishLogsCompanion(
            id: id,
            variantId: variantId,
            platform: platform,
            mode: mode,
            status: status,
            externalUrl: externalUrl,
            postedAt: postedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> variantId = const Value.absent(),
            required String platform,
            required String mode,
            Value<String> status = const Value.absent(),
            Value<String?> externalUrl = const Value.absent(),
            Value<DateTime?> postedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PublishLogsCompanion.insert(
            id: id,
            variantId: variantId,
            platform: platform,
            mode: mode,
            status: status,
            externalUrl: externalUrl,
            postedAt: postedAt,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PublishLogsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({variantId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (variantId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.variantId,
                    referencedTable:
                        $$PublishLogsTableReferences._variantIdTable(db),
                    referencedColumn:
                        $$PublishLogsTableReferences._variantIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$PublishLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PublishLogsTable,
    PublishLog,
    $$PublishLogsTableFilterComposer,
    $$PublishLogsTableOrderingComposer,
    $$PublishLogsTableAnnotationComposer,
    $$PublishLogsTableCreateCompanionBuilder,
    $$PublishLogsTableUpdateCompanionBuilder,
    (PublishLog, $$PublishLogsTableReferences),
    PublishLog,
    PrefetchHooks Function({bool variantId})>;
typedef $$StyleProfilesTableCreateCompanionBuilder = StyleProfilesCompanion
    Function({
  required String id,
  Value<String> voiceName,
  Value<double> casualFormal,
  Value<double> punchiness,
  Value<String> emojiLevel,
  Value<List<String>> bannedPhrases,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$StyleProfilesTableUpdateCompanionBuilder = StyleProfilesCompanion
    Function({
  Value<String> id,
  Value<String> voiceName,
  Value<double> casualFormal,
  Value<double> punchiness,
  Value<String> emojiLevel,
  Value<List<String>> bannedPhrases,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$StyleProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $StyleProfilesTable> {
  $$StyleProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voiceName => $composableBuilder(
      column: $table.voiceName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get casualFormal => $composableBuilder(
      column: $table.casualFormal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get bannedPhrases => $composableBuilder(
          column: $table.bannedPhrases,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$StyleProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $StyleProfilesTable> {
  $$StyleProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voiceName => $composableBuilder(
      column: $table.voiceName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get casualFormal => $composableBuilder(
      column: $table.casualFormal,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bannedPhrases => $composableBuilder(
      column: $table.bannedPhrases,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$StyleProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StyleProfilesTable> {
  $$StyleProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get voiceName =>
      $composableBuilder(column: $table.voiceName, builder: (column) => column);

  GeneratedColumn<double> get casualFormal => $composableBuilder(
      column: $table.casualFormal, builder: (column) => column);

  GeneratedColumn<double> get punchiness => $composableBuilder(
      column: $table.punchiness, builder: (column) => column);

  GeneratedColumn<String> get emojiLevel => $composableBuilder(
      column: $table.emojiLevel, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get bannedPhrases =>
      $composableBuilder(
          column: $table.bannedPhrases, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$StyleProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $StyleProfilesTable,
    StyleProfile,
    $$StyleProfilesTableFilterComposer,
    $$StyleProfilesTableOrderingComposer,
    $$StyleProfilesTableAnnotationComposer,
    $$StyleProfilesTableCreateCompanionBuilder,
    $$StyleProfilesTableUpdateCompanionBuilder,
    (
      StyleProfile,
      BaseReferences<_$AppDatabase, $StyleProfilesTable, StyleProfile>
    ),
    StyleProfile,
    PrefetchHooks Function()> {
  $$StyleProfilesTableTableManager(_$AppDatabase db, $StyleProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StyleProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StyleProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StyleProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> voiceName = const Value.absent(),
            Value<double> casualFormal = const Value.absent(),
            Value<double> punchiness = const Value.absent(),
            Value<String> emojiLevel = const Value.absent(),
            Value<List<String>> bannedPhrases = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StyleProfilesCompanion(
            id: id,
            voiceName: voiceName,
            casualFormal: casualFormal,
            punchiness: punchiness,
            emojiLevel: emojiLevel,
            bannedPhrases: bannedPhrases,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String> voiceName = const Value.absent(),
            Value<double> casualFormal = const Value.absent(),
            Value<double> punchiness = const Value.absent(),
            Value<String> emojiLevel = const Value.absent(),
            Value<List<String>> bannedPhrases = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StyleProfilesCompanion.insert(
            id: id,
            voiceName: voiceName,
            casualFormal: casualFormal,
            punchiness: punchiness,
            emojiLevel: emojiLevel,
            bannedPhrases: bannedPhrases,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StyleProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $StyleProfilesTable,
    StyleProfile,
    $$StyleProfilesTableFilterComposer,
    $$StyleProfilesTableOrderingComposer,
    $$StyleProfilesTableAnnotationComposer,
    $$StyleProfilesTableCreateCompanionBuilder,
    $$StyleProfilesTableUpdateCompanionBuilder,
    (
      StyleProfile,
      BaseReferences<_$AppDatabase, $StyleProfilesTable, StyleProfile>
    ),
    StyleProfile,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SourceItemsTableTableManager get sourceItems =>
      $$SourceItemsTableTableManager(_db, _db.sourceItems);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$VariantsTableTableManager get variants =>
      $$VariantsTableTableManager(_db, _db.variants);
  $$PublishLogsTableTableManager get publishLogs =>
      $$PublishLogsTableTableManager(_db, _db.publishLogs);
  $$StyleProfilesTableTableManager get styleProfiles =>
      $$StyleProfilesTableTableManager(_db, _db.styleProfiles);
}
