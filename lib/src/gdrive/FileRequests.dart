import 'dart:async';
import 'dart:convert';

import 'package:googleapis/drive/v2.dart' as drive;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:lg_controller/src/menu/MainMenu.dart';
import 'package:lg_controller/src/menu/POINavBarMenu.dart';
import 'package:lg_controller/src/menu/TourNavBarMenu.dart';
import 'package:lg_controller/src/models/KMLData.dart';
import 'package:lg_controller/src/models/POIData.dart';
import 'package:lg_controller/src/models/SegregatedKMLData.dart';
import 'package:lg_controller/src/models/TourData.dart';

/// To handle all functionalities with Google Drive.
class FileRequests {
  /// Credentials of the service account.
  final _credentials = r'''
  {
  }
  ''';

  /// Drive scope required for getting file data.
  final scopes = [drive.DriveApi.DriveScope];

  /// To get the KML data for the modules.
  Future<Map<String, List<KMLData>>> getFiles(MainMenu pagestate) async {
    var client = await authorizeUser();
    if (client == null) return null;
    var api = new drive.DriveApi(client);
    String query = "";
    if (pagestate == MainMenu.POI)
      query =
          "mimeType = 'application/vnd.google-earth.kml+xml' and '1Gs-KiheWHACyUtYtvGZma8xsBX6r1iTJ' in parents";
    else if (pagestate == MainMenu.TOURS)
      query =
          "mimeType = 'application/vnd.google-earth.kml+xml' and '1bGjX92kaxTZ5zJxX5vLiAAyOM9zHV2sf' in parents";
    List<drive.File> files =
        await searchFiles(api, 24, query).catchError((error) {
      print('An error occured: ' + (error.toString()));
      return null;
    }).whenComplete(() {
      client.close();
    });
    return decodeFiles(files, pagestate);
  }

  /// To get the KML data in required map format from [drive.File].
  Future<Map<String, List<KMLData>>> decodeFiles(
      List<drive.File> files, MainMenu pagestate) async {
    Map<String, List<KMLData>> segData = new Map<String, List<KMLData>>();
    if (pagestate == MainMenu.POI) {
      for (var ic in POINavBarMenu.values()) {
        segData.addAll({ic.title: new List<KMLData>()});
      }
      SegregatedKmlData d;
      try {
        for (var file in files) {
          d = new SegregatedKmlData.fromJson(jsonDecode(file.description));
          if (segData.containsKey(d.category)) {
            segData[d.category].add(POIData.fromJson(jsonDecode(d.data)));
          }
        }
      } catch (e) {
        print(e.toString());
      }
    } else if (pagestate == MainMenu.TOURS) {
      for (var ic in TourNavBarMenu.values()) {
        segData.addAll({ic.title: new List<KMLData>()});
      }
      SegregatedKmlData d;
      try {
        for (var file in files) {
          d = new SegregatedKmlData.fromJson(jsonDecode(file.description));
          if (segData.containsKey(d.category)) {
            Map<String, dynamic> data = jsonDecode(d.data);
            data.addAll({'fileID': file.id});
            segData[d.category].add(TourData.fromJson(data));
          }
        }
      } catch (e) {
        print(e.toString());
      }
    }
    return segData;
  }

  /// To authorize and return the client for the service account.
  Future<auth.AuthClient> authorizeUser() async {
    try {
      final acc_credentials =
          new auth.ServiceAccountCredentials.fromJson(_credentials);
      var client = await auth
          .clientViaServiceAccount(acc_credentials, scopes)
          .catchError((error) {
        print("An unknown error occured: $error");
        return null;
      });
      return client;
    } catch (e) {
      return null;
    }
  }

  /// Returns a list of [drive.File] according to the [query] provided.
  Future<List<drive.File>> searchFiles(
      drive.DriveApi api, int max, String query) async {
    List<drive.File> docs = [];
    Future<List<drive.File>> next(String token) {
      try {
        return api.files
            .list(q: query, pageToken: token, maxResults: max)
            .then((results) {
          docs.addAll(results.items);
          if (docs.length < max && results.nextPageToken != null) {
            return next(results.nextPageToken);
          }
          return docs;
        });
      } catch (e) {
        return null;
      }
    }

    return next(null);
  }
}
