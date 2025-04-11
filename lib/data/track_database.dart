// lib/data/track_database.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/track.dart';

class TrackDatabase {
  static final TrackDatabase instance = TrackDatabase._init();
  static Database? _database;

  TrackDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hiking_tracks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    print('Database path: $path');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planned_tracks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        distance REAL,
        elevationGain REAL,
        dateAdded TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE track_tags (
        track_id INTEGER,
        tag_id INTEGER,
        FOREIGN KEY (track_id) REFERENCES planned_tracks(id) ON DELETE CASCADE,
        FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE,
        PRIMARY KEY (track_id, tag_id)
      )
    ''');
  }

  Future<int> createTrack(Track track) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Insert the track
      final trackId = await txn.insert('planned_tracks', track.toMap());

      // Insert tags and link them
      for (final tagName in track.tags) {
        int tagId;
        final existingTag = await txn.query(
          'tags',
          where: 'name = ?',
          whereArgs: [tagName],
        );
        if (existingTag.isEmpty) {
          tagId = await txn.insert('tags', {'name': tagName});
        } else {
          tagId = existingTag.first['id'] as int;
        }
        await txn.insert('track_tags', {
          'track_id': trackId,
          'tag_id': tagId,
        });
      }
      return trackId;
    });
  }

  Future<List<Track>> getAllTracks() async {
    final db = await database;
    final trackMaps = await db.query('planned_tracks');
    
    final List<Track> tracks = [];
    for (final trackMap in trackMaps) {
      final tags = await _getTagsForTrack(db, trackMap['id'] as int);
      tracks.add(Track.fromMap(trackMap, tags: tags));
    }
    return tracks;
  }

  Future<Track?> getTrack(int id) async {
    final db = await database;
    final maps = await db.query(
      'planned_tracks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final tags = await _getTagsForTrack(db, id);
      return Track.fromMap(maps.first, tags: tags);
    }
    return null;
  }

  Future<List<String>> _getTagsForTrack(Database db, int trackId) async {
    final tagMaps = await db.rawQuery('''
      SELECT tags.name 
      FROM tags
      JOIN track_tags ON tags.id = track_tags.tag_id
      WHERE track_tags.track_id = ?
    ''', [trackId]);
    return tagMaps.map((map) => map['name'] as String).toList();
  }

  Future<int> updateTrack(Track track) async {
    final db = await database;
    return await db.transaction((txn) async {
      // Update track details
      final count = await txn.update(
        'planned_tracks',
        track.toMap(),
        where: 'id = ?',
        whereArgs: [track.id],
      );

      // Delete existing tags
      await txn.delete('track_tags', where: 'track_id = ?', whereArgs: [track.id]);

      // Insert new tags
      for (final tagName in track.tags) {
        int tagId;
        final existingTag = await txn.query(
          'tags',
          where: 'name = ?',
          whereArgs: [tagName],
        );
        if (existingTag.isEmpty) {
          tagId = await txn.insert('tags', {'name': tagName});
        } else {
          tagId = existingTag.first['id'] as int;
        }
        await txn.insert('track_tags', {
          'track_id': track.id,
          'tag_id': tagId,
        });
      }
      return count;
    });
  }

  Future<int> deleteTrack(int id) async {
    final db = await database;
    return await db.delete(
      'planned_tracks',
      where: 'id = ?',
      whereArgs: [id],
    ); // ON DELETE CASCADE will handle track_tags cleanup
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}