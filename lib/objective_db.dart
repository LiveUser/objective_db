library objective_db;

import 'dart:io';
import 'dart:convert';
import 'package:power_plant/power_plant.dart';
import 'package:chromarotor/chromarotor.dart';
import 'package:bson/bson.dart';

class Entry{
  Entry({
    required this.dbPath,
    this.cipherKeys,
  });
  final String dbPath;
  final ChromaImage? cipherKeys;
  DbObject select(){
    return DbObject(
      uuid: "entry",
      dbPath: dbPath,
      cipherKeys: cipherKeys,
    );
  }
  //Encrypt entire database
  void encryptEntireDatabase(){
    if(cipherKeys != null){
      List<FileSystemEntity> folderContents = Directory(dbPath).listSync().toList();
      for(FileSystemEntity item in folderContents){
        if(item is File){
          List<int> content = item.readAsBytesSync();
          List<int> encryptedContent = _encryptFile(fileContents: content, keys: cipherKeys);
          item.writeAsBytesSync(encryptedContent);
        }
      }
    }else{
      throw "Need a key to encrypt.";
    }
  }
  //Decrypt entire database
  void decryptEntireDatabase(){
    if(cipherKeys != null){
      List<FileSystemEntity> folderContents = Directory(dbPath).listSync().toList();
      for(FileSystemEntity item in folderContents){
        if(item is File){
          List<int> content = item.readAsBytesSync();
          Map<String,dynamic> decryptedContent = _decryptFile(fileContents: content, keys: cipherKeys);
          item.writeAsBytesSync(BsonCodec.serialize(decryptedContent).byteList);
        }
      }
    }else{
      throw "Need a key to decrypt.";
    }
  }
  //Change password
  void changeDatabasePassword({
    required ChromaImage oldPassword,
  }){
    if(cipherKeys != null){
      //Decrypt entire database
      if(cipherKeys != null){
        List<FileSystemEntity> folderContents = Directory(dbPath).listSync().toList();
        for(FileSystemEntity item in folderContents){
          if(item is File){
            List<int> content = item.readAsBytesSync();
            Map<String,dynamic> decryptedContent = _decryptFile(fileContents: content, keys: oldPassword);
            item.writeAsBytesSync(BsonCodec.serialize(decryptedContent).byteList);
          }
        }
      }else{
        throw "Need a key to decrypt.";
      }
      //Encrypt entire database
      if(cipherKeys != null){
        List<FileSystemEntity> folderContents = Directory(dbPath).listSync().toList();
        for(FileSystemEntity item in folderContents){
          if(item is File){
            List<int> content = item.readAsBytesSync();
            List<int> encryptedContent = _encryptFile(fileContents: content, keys: cipherKeys);
            item.writeAsBytesSync(encryptedContent);
          }
        }
      }else{
        throw "Need a key to encrypt.";
      }
    }else{
      throw "Need a key to unlock password.";
    }
  }
}
class DbObject{
  DbObject({
    required this.uuid,
    required this.dbPath,
    required this.cipherKeys,
  });
  final String uuid;
  final String dbPath;
  final ChromaImage? cipherKeys;
  DbObject select({
    required Map reference,
  }){
    return DbObject(
      uuid: reference["uuid"],
      dbPath: dbPath,
      cipherKeys: cipherKeys,
    );
  }
  List<DbObject> selectMultiple({
    required String key,
  }){
    Map<String,dynamic> map = view();
    if(map[key] == null){
      throw "Key has a null value";
    }else if(map[key] is List){
      if((map[key] as List).every((element)=> element is Map<String,dynamic>)){
        List references = map[key];
        List<DbObject> objects = [];
        for(Map<String,dynamic> reference in references){
          objects.add(DbObject(
            uuid: reference["uuid"],
            dbPath: dbPath,
            cipherKeys: cipherKeys,
          ));
        }
        return objects;
      }else{
        throw "Value is not a List of references";
      }
    }else{
      throw "Key is not a List of references";
    }
  }
  Map<String,dynamic> view(){
    File selectedFile = File("$dbPath/$uuid.bson");
    if(!selectedFile.existsSync()){
      selectedFile.createSync(recursive: true);
      if(cipherKeys == null){
        selectedFile.writeAsBytesSync(BsonCodec.serialize({}).byteList);
      }else{
        selectedFile.writeAsBytesSync(_encryptFile(fileContents: utf8.encode("{}"), keys: cipherKeys));
      }
    }
    List<int> fileContent = selectedFile.readAsBytesSync();
    Map<String,dynamic> map = _decryptFile(
      fileContents: fileContent, 
      keys: cipherKeys,
    );
    return map;
  }
  String _addMap({
    required Map<String,dynamic> value,
  }){
    String uuid = _generateUUID(dbPath: dbPath);
    Map<String,dynamic> map = {
      "uuid": uuid,
    };
    File outputFile = File("$dbPath/$uuid.bson");
    outputFile.create(recursive: true);
    if(cipherKeys == null){
      outputFile.writeAsBytesSync(BsonCodec.serialize({}).byteList);
    }else{
      outputFile.writeAsBytesSync(_encryptFile(fileContents: BsonCodec.serialize(map).byteList, keys: cipherKeys));
    }
    //Insert all properties
    List<String> keys = value.keys.toList();
    for(String key in keys){
      DbObject dbObject = DbObject(uuid: uuid, dbPath: dbPath,cipherKeys: cipherKeys);
      dbObject.insert(key: key, value: value[key]);
    }
    //return uuid
    return uuid;
  }
  void _saveFile({
    required String uuid,
    required Map<String,dynamic> object,
  }){
    File outputFile = File("$dbPath/$uuid.bson");
    if (object.isEmpty) {
    if (outputFile.existsSync()) {
        outputFile.deleteSync();
      }
    } else {
      if (cipherKeys == null) {
        outputFile.writeAsBytesSync(BsonCodec.serialize(object).byteList);
      } else {
        outputFile.writeAsBytesSync(
          _encryptFile(fileContents: BsonCodec.serialize(object).byteList, keys: cipherKeys)
        );
      }
    } 
  }
  //Insert:
  //Return String or List<String> containing uuids
  dynamic insert({
    required String key,
    required dynamic value,
  }){
    if(key == "uuid"){
      throw "Cannot modify the uuid of an object";
    }
    dynamic createdUUIDs;
    Map<String,dynamic> object = view();
    if(object[key] == null){
      if(value is String){
        object[key] = value;
      }else if(value is int){
        object[key] = value;
      }else if(value is double){
        object[key] = value;
      }else if(value is bool){
        object[key] = value;
      }else if(value is List){
        //Check if contains a map.
        if(value.isEmpty){
          object[key] = value;
        }else if(value.every((element)=> element is Map<String,dynamic>)){
          createdUUIDs = [];
          //Verify that all are of the same type..Already done in the else if statement.
          //Store each map in another file and store reference here
          object[key] = [];
          for(Map<String,dynamic> map in value){
            String uuid = _addMap(value: map);
            (object[key] as List).add({
              "uuid": uuid,
            });
            createdUUIDs.add(uuid);
          }
        }else if(value.every((element)=> element is! Map<String,dynamic>)){
          //Add the value if it is not a Map
          object[key] = value;
        }else{
          throw "Cannot mix data type Map with other data types in List";
        }
      }else if(value is Map<String,dynamic>){
        //Save file is storing an unedited version of object
        //print("----------------------Should store reference");
        String uuid = _addMap(value: value);
        object[key] = {"uuid": uuid};
        createdUUIDs = uuid;
      }else{
        throw "Unsupported data type";
      }
    }else{
      if(object[key] is String && value is String){
        object[key] = value;
      }else if(object[key] is int && value is int){
        object[key] = value;
      }else if(object[key] is double && value is double){
        object[key] = value;
      }else if(object[key] is Map<String,dynamic> && value is Map<String,dynamic>){
        throw "Cannot insert in reference to object";
      }else if(object[key] is bool && value is bool){
        object[key] = value;
      }else if(object[key] is List && value is List){
        //Check if contains a map.
        if(object[key].isEmpty){
          //object[key] = value;
          if(value.every((element)=> element is String)){
            (object[key] as List).addAll(value);
          }else if(value.every((element)=> element is int)){
            (object[key] as List).addAll(value);
          }else if(value.every((element)=> element is double)){
            (object[key] as List).addAll(value);
          }else if(value.every((element)=> element is bool)){
            (object[key] as List).addAll(value);
          }else if(value.every((element)=> element is Map<String,dynamic>)){
            createdUUIDs = [];
            for(Map<String,dynamic> listItem in value){
              String uuid = _addMap(value: listItem);
              (object[key] as List).add({
                "uuid": uuid,
              });
              createdUUIDs.add(uuid);
            }
          }else{
            throw "Unsupported data type as value.";
          }
        }else if(value.every((element)=> element is String) && object[key].every((element)=> element is String)){
          (object[key] as List).addAll(value);
        }else if(value.every((element)=> element is int) && object[key].every((element)=> element is int)){
          (object[key] as List).addAll(value);
        }else if(value.every((element)=> element is double) && object[key].every((element)=> element is double)){
          (object[key] as List).addAll(value);
        }else if(value.every((element)=> element is Map<String,dynamic>) && object[key].every((element)=> element is Map<String,dynamic>)){
          createdUUIDs = [];
          //Verify that all are of the same type..Already done in the else if statement.
          //Store each map in another file and store reference here
          for(Map<String,dynamic> map in value){
            String uuid = _addMap(value: map);
            (object[key] as List).add({
              "uuid": uuid,
            });
            createdUUIDs.add(uuid);
          }
        }else{
          throw "Cannot mix data type Map with other data types in List";
        }
      }else if(value is Map<String,dynamic>){
        //Store map in another file and store reference here
        String uuid = _addMap(value: value);
        object[key] = {"uuid": uuid};
        createdUUIDs = uuid;
      }else{
        throw "Unsupported data type";
      }
    }
    _saveFile(uuid: uuid, object: object);
    if(createdUUIDs == null){
      return null;
    }else if(createdUUIDs is String){
      return createdUUIDs;
    }else{
      return List<String>.from(createdUUIDs);
    }
  }
  void _deleteLinked({
    required String uuid,
  }){
    // First check if file exists before trying to view it
    File linkedFile = File("$dbPath/$uuid.bson");
    if(!linkedFile.existsSync()){
      return; // File already deleted or doesn't exist
    }

    try {
      DbObject selection = DbObject(
        uuid: uuid,
        dbPath: dbPath,
        cipherKeys: cipherKeys,
      );
      Map<String,dynamic> map = selection.view();
      List<String> keys = map.keys.toList();

      // Remove linked recursively BEFORE trying to delete this file
      for(String key in keys){
        if(map[key] is Map<String,dynamic>){
          Map<String,dynamic> value = map[key];
          if(value.containsKey("uuid")){
            _deleteLinked(uuid: value["uuid"]);
          }
        }else if(map[key] is List){
          List listValue = map[key];
          if(listValue.isNotEmpty && listValue.every((element)=> element is Map<String,dynamic>)){
            for(Map<String,dynamic> object in listValue){
              if(object.containsKey("uuid")){
                _deleteLinked(uuid: object["uuid"]);
              }
            }
          }
        }
      }
    } catch (e) {
      // If we can't read the file, it might be corrupted or already being deleted
      // Just proceed to delete the file
    }

    // Now delete this file
    if(linkedFile.existsSync()){
      try {
        linkedFile.deleteSync();
      } catch (e) {
        // If we can't delete, rethrow the error
        throw "Could not delete file $uuid.bson: $e";
      }
    }
  }
  ///Delete all objects and references to them
  void delete({
    required String key,
    required String uuid,
  }) {
    Map<String,dynamic> object = view();

    if (object[key] == null) {
      throw "Key has a null value";
    } else if (object[key] is Map<String,dynamic>) {
      Map<String,dynamic> ref = object[key];
      if (ref.containsKey("uuid") && ref["uuid"] == uuid) {
        // Delete linked file(s)
        _deleteLinked(uuid: uuid);
        object.remove(key);
      } else {
        throw "UUID doesn't match the reference";
      }
    } else if (object[key] is List) {
      List listValue = object[key];

      if (listValue.isEmpty) {
        throw "List is empty";
      }

      bool allItemsAreMapsWithUUID = listValue.every((element) =>
          element is Map<String,dynamic> && element.containsKey("uuid"));

      if (allItemsAreMapsWithUUID) {
        bool found = listValue.any((ref) => ref["uuid"] == uuid);

        if (found) {
          _deleteLinked(uuid: uuid);
          listValue.removeWhere((map) =>
              (map as Map<String,dynamic>)["uuid"] == uuid);
          object[key] = listValue;
        } else {
          throw "UUID not found in list";
        }
      } else {
        throw "List doesn't contain only object references (maps with uuid)";
      }
    } else {
      throw "uuid and key do not point to an object or list of objects.";
    }

    // Save or delete depending on whether object is empty
    _saveFile(uuid: this.uuid, object: object);
  }
  //Delete key
  void deleteKey({
    required String key,
  }){
    Map<String,dynamic> object = view();
  
    if (object[key] is Map<String,dynamic>) {
      Map<String,dynamic> ref = object[key];
      if (ref.containsKey("uuid")) {
        _deleteLinked(uuid: ref["uuid"]);
      }
    } else if (object[key] is List) {
      List listValue = object[key];
      bool containsMapsWithUUID = listValue.isNotEmpty &&
          listValue.every((element) => element is Map<String,dynamic>);
  
      if (containsMapsWithUUID) {
        for (dynamic item in listValue) {
          if (item is Map<String,dynamic> && item.containsKey("uuid")) {
            _deleteLinked(uuid: item["uuid"]);
          }
        }
      }
    }
  
    // Remove the key itself
    object.remove(key);
  
    // Save or delete depending on whether object is empty
    _saveFile(uuid: uuid, object: object);
  }
  //Move List item
  void move({
    required String key,
    required int from,
    required int to,
  }){
    Map<String,dynamic> object = view();
    if(object[key] is List){
      (object[key] as List).insert(to, object[key][from]);
      if(to < from){
        (object[key] as List).removeAt(from + 1);
      }else{
        (object[key] as List).removeAt(from);
      }
      _saveFile(
        uuid: uuid, 
        object: object,
      );
    }else{
      throw "$key is not a List";
    }
  }
  //Swap List items
  void swap({
    required String key,
    required int from,
    required int to,
  }){
    Map<String,dynamic> object = view();
    if(object[key] is List){
      dynamic a = object[key][from];
      dynamic b = object[key][to];
      object[key][from] = b;
      object[key][to] = a;
      _saveFile(
        uuid: uuid, 
        object: object,
      );
    }else{
      throw "$key is not a List";
    }
  }
  //Pop item
  void pop({
    required int index,
    required String key,
  }){
    Map<String,dynamic> object = view();
    if(object[key] is List){
      List listItems = object[key];
      if(listItems.isEmpty){
        throw "Cannot pop from empty List.";
      }else{
        if(index >= 0 && index < listItems.length){
          dynamic item = listItems[index];
          // Only delete linked files if item is a map with uuid
          if(item is Map<String,dynamic> && item.containsKey("uuid")){
            _deleteLinked(uuid: item["uuid"]);
          }
          listItems.removeAt(index);
          object[key] = listItems;
          _saveFile(
            uuid: uuid,
            object: object,
          );
        }else{
          throw "Index out of bounds";
        }
      }
    }else{
      throw "$key value is not of type List.";
    }
  }
  void insertAt({
    required int index,
    required String key,
    required dynamic value,
  }){
    //Add at the end of the list
    insert(key: key, value: value);
    //Get how many items are on the list
    List listItems = view()[key];
    //Move the inserted item into the desired position
    move(
      key: key, 
      from: listItems.length - 1, 
      to: index,
    );
  }
  void replaceAt({
    required int index,
    required String key,
    required dynamic value,
  }){
    Map<String,dynamic> object = view();
    if(object[key] is List){
      List listItems = object[key];
      if(listItems.first is Map<String,dynamic>){
        throw "Cannot replace object references.";
      }else{
        //Insert new value
        insertAt(
          index: index, 
          key: key, 
          value: value,
        );
        //Pop old value
        pop(
          index: index + 1, 
          key: key,
        );
      }
    }else{
      throw "key value must be a List.";
    }
  }
}
String _generateUUID({
  required String dbPath,
}){
  bool exists = true;
  String uuid = "";
  while(exists){
    uuid = uniqueAlphanumeric(tokenLength: 40);
    File file = File("$dbPath/$uuid.bson");
    exists = file.existsSync();
  }
  return uuid;
}
List<int> _encryptFile({
  required List<int> fileContents,
  required ChromaImage? keys,
}){
  //Try to parse .bson if successfull file is unencrypted else it is already encrypted
  try{
    //Parse to make sure it is unencrypted
    Map<String,dynamic> parsedJSON = BsonCodec.deserialize(BsonBinary.from(fileContents));
    if(keys != null){
      //Encrypt the data
      List<int> cipheredContent = chromaRotorCipher(
        chromaImage: keys, 
        bytes: fileContents,
      );
      return cipheredContent;
    }else{
      //Return file as is (unencrypted)
      return fileContents;
    }
  }catch(error){
    //It is already encrypted
    return fileContents;
  }
}
Map<String,dynamic> _decryptFile({
  required List<int> fileContents,
  required ChromaImage? keys,
}){
  //Try to parse .bson if successfull file is unencrypted else it is already encrypted
  try{
    //Parse to make sure it is unencrypted
    Map<String,dynamic> parsedJSON = BsonCodec.deserialize(BsonBinary.from(fileContents));
    //If unencrypted return parsed data
    return parsedJSON;
  }catch(error){
    if(keys != null){
      try{
        //Decrypt file
        List<int> decryptedFile = chromaRotorDecipher(
          chromaImage: keys,
          cipheredBytes: fileContents,
        );
        Map<String,dynamic> decryptedJSON = BsonCodec.deserialize(BsonBinary.from(decryptedFile));
        return decryptedJSON;
      }catch(err){
        throw "Wrong password.";
      }
    }else{
      throw "File is encrypted but there is no password";
    }
  }
}