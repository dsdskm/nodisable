// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

class $FloorMyDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$MyDatabaseBuilder databaseBuilder(String name) =>
      _$MyDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static _$MyDatabaseBuilder inMemoryDatabaseBuilder() =>
      _$MyDatabaseBuilder(null);
}

class _$MyDatabaseBuilder {
  _$MyDatabaseBuilder(this.name);

  final String name;

  final List<Migration> _migrations = [];

  Callback _callback;

  /// Adds migrations to the builder.
  _$MyDatabaseBuilder addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  /// Adds a database [Callback] to the builder.
  _$MyDatabaseBuilder addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  /// Creates the database and initializes it.
  Future<MyDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name)
        : ':memory:';
    final database = _$MyDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$MyDatabase extends MyDatabase {
  _$MyDatabase([StreamController<String> listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  PlaceDao _placeDaoInstance;

  NoticeDao _noticeDaoInstance;

  CategoryDao _categoryDaoInstance;

  Future<sqflite.Database> open(String path, List<Migration> migrations,
      [Callback callback]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `placeTable` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT, `docu` TEXT, `address` TEXT, `category1` TEXT, `category2` TEXT, `contact` TEXT, `elevator` INTEGER, `floor` TEXT, `gyungsaro` INTEGER, `latitude` REAL, `longitude` REAL, `name` TEXT, `parking` INTEGER, `restroom` INTEGER, `summary` TEXT, `using` INTEGER, `image_base` TEXT, `image_elevator` TEXT, `image_gyungsaro` TEXT, `image_parking` TEXT, `image_restroom` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `notice` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT, `docu` TEXT, `title` TEXT, `content` TEXT, `image` TEXT)');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `categoryTable` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT, `index` INTEGER, `depth` INTEGER, `category` TEXT, `value` TEXT)');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  PlaceDao get placeDao {
    return _placeDaoInstance ??= _$PlaceDao(database, changeListener);
  }

  @override
  NoticeDao get noticeDao {
    return _noticeDaoInstance ??= _$NoticeDao(database, changeListener);
  }

  @override
  CategoryDao get categoryDao {
    return _categoryDaoInstance ??= _$CategoryDao(database, changeListener);
  }
}

class _$PlaceDao extends PlaceDao {
  _$PlaceDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _placeDataInsertionAdapter = InsertionAdapter(
            database,
            'placeTable',
            (PlaceData item) => <String, dynamic>{
                  'uid': item.uid,
                  'docu': item.docu,
                  'address': item.address,
                  'category1': item.category1,
                  'category2': item.category2,
                  'contact': item.contact,
                  'elevator':
                      item.elevator == null ? null : (item.elevator ? 1 : 0),
                  'floor': item.floor,
                  'gyungsaro':
                      item.gyungsaro == null ? null : (item.gyungsaro ? 1 : 0),
                  'latitude': item.latitude,
                  'longitude': item.longitude,
                  'name': item.name,
                  'parking':
                      item.parking == null ? null : (item.parking ? 1 : 0),
                  'restroom':
                      item.restroom == null ? null : (item.restroom ? 1 : 0),
                  'summary': item.summary,
                  'using': item.using == null ? null : (item.using ? 1 : 0),
                  'image_base': item.image_base,
                  'image_elevator': item.image_elevator,
                  'image_gyungsaro': item.image_gyungsaro,
                  'image_parking': item.image_parking,
                  'image_restroom': item.image_restroom
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  static final _placeTableMapper = (Map<String, dynamic> row) => PlaceData(
      row['docu'] as String,
      row['address'] as String,
      row['category1'] as String,
      row['category2'] as String,
      row['contact'] as String,
      row['elevator'] == null ? null : (row['elevator'] as int) != 0,
      row['floor'] as String,
      row['gyungsaro'] == null ? null : (row['gyungsaro'] as int) != 0,
      row['latitude'] as double,
      row['longitude'] as double,
      row['name'] as String,
      row['parking'] == null ? null : (row['parking'] as int) != 0,
      row['restroom'] == null ? null : (row['restroom'] as int) != 0,
      row['summary'] as String,
      row['using'] == null ? null : (row['using'] as int) != 0,
      row['image_base'] as String,
      row['image_elevator'] as String,
      row['image_gyungsaro'] as String,
      row['image_parking'] as String,
      row['image_restroom'] as String);

  final InsertionAdapter<PlaceData> _placeDataInsertionAdapter;

  @override
  Future<List<PlaceData>> getAllPlace() async {
    return _queryAdapter.queryList('SELECT * FROM placeTable',
        mapper: _placeTableMapper);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM placeTable');
  }

  @override
  Future<void> deleteByDocu(String param) async {
    await _queryAdapter.queryNoReturn('DELETE FROM placeTable WHERE docu = ?',
        arguments: <dynamic>[param]);
  }

  @override
  Future<void> insertData(PlaceData data) async {
    await _placeDataInsertionAdapter.insert(data, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertAll(List<PlaceData> data) async {
    await _placeDataInsertionAdapter.insertList(data, OnConflictStrategy.abort);
  }
}

class _$NoticeDao extends NoticeDao {
  _$NoticeDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _noticeDataInsertionAdapter = InsertionAdapter(
            database,
            'notice',
            (NoticeData item) => <String, dynamic>{
                  'uid': item.uid,
                  'docu': item.docu,
                  'title': item.title,
                  'content': item.content,
                  'image': item.image
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  static final _noticeMapper = (Map<String, dynamic> row) => NoticeData(
      row['docu'] as String,
      row['title'] as String,
      row['content'] as String,
      row['image'] as String);

  final InsertionAdapter<NoticeData> _noticeDataInsertionAdapter;

  @override
  Future<List<NoticeData>> getAllNotice() async {
    return _queryAdapter.queryList('SELECT * FROM notice',
        mapper: _noticeMapper);
  }

  @override
  Future<NoticeData> getNotice(String docu) async {
    return _queryAdapter.query('SELECT * FROM notice WHERE docu=?',
        arguments: <dynamic>[docu], mapper: _noticeMapper);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM notice');
  }

  @override
  Future<void> insertAll(List<NoticeData> data) async {
    await _noticeDataInsertionAdapter.insertList(
        data, OnConflictStrategy.abort);
  }
}

class _$CategoryDao extends CategoryDao {
  _$CategoryDao(this.database, this.changeListener)
      : _queryAdapter = QueryAdapter(database),
        _categoryDataInsertionAdapter = InsertionAdapter(
            database,
            'categoryTable',
            (CategoryData item) => <String, dynamic>{
                  'uid': item.uid,
                  'index': item.index,
                  'depth': item.depth,
                  'category': item.category,
                  'value': item.value
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  static final _categoryTableMapper = (Map<String, dynamic> row) =>
      CategoryData(row['index'] as int, row['depth'] as int,
          row['category'] as String, row['value'] as String);

  final InsertionAdapter<CategoryData> _categoryDataInsertionAdapter;

  @override
  Future<List<CategoryData>> getAllCategory() async {
    return _queryAdapter.queryList('SELECT * FROM categoryTable',
        mapper: _categoryTableMapper);
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM categoryTable');
  }

  @override
  Future<void> insertData(CategoryData data) async {
    await _categoryDataInsertionAdapter.insert(data, OnConflictStrategy.abort);
  }

  @override
  Future<void> insertAll(List<CategoryData> data) async {
    await _categoryDataInsertionAdapter.insertList(
        data, OnConflictStrategy.abort);
  }
}
