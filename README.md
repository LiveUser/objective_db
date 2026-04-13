# Objective DB
BSON based Database.
------------------------------------------------------
Hecho en 🇵🇷 por Radamés J. Valentín Reyes
## Major Overhaul
Program now uses BSON(Binary Javascript Object Notation) instead o JSON to improve speed and reduce file size.
~~~
Ultra Mega Important Note:
- This version cannot interact with databases made with previous versions.
- Code stays the same (changes are under the hood)
~~~

## Importing
~~~dart
import 'package:objective_db/objective_db.dart';
~~~
## About the project
- The program will throw errors every time an error is encountered or a forbidden operation is attempted(such as editing the uuid).
- uuid's in this project are composed of 40 alphanumeric characters.
- All data is stored as .bson and returned as Map<String,dynamic>
- When insertin Map<String,dynamic> a new file will be created and a reference to it will be stored in the parent .bson object.

Functions, classes and methods
-----------------------------
## Entry
Entry class is the root of the file structure.
~~~dart
Entry entry = Entry(dbPath: "./database");
~~~
## Select method
returns a DbObject which contains many more useful methods like insert and delete.
~~~dart
Entry entry = Entry(dbPath: "./database");
DbObject dbObject = entry.select();
~~~
## Insert method
If the value is a double, int or String the insert method will add the key to the selected Map, if the key already exists the value will be replaced. If you you try to insert a Map a new file will be created and a reference to the file will be generated. If the value you try to replace has a Map assigned to it you will get an error. If you try to insert a List<Map<String,dynamic>> new files and references will be generated. A String or List<String> will be returned containing the UUIDs of the created objects.
~~~dart
Entry entry = Entry(dbPath: "./database");
List<String> createdUUIDs = entry.select().insert(
  key: "Stores",
  value: [
    {
      "Name": "Frappé inc",
      "balance": 18.59,
    },
    {
      "Name": "Rica Pizza",
      "balance": 19000,
    },
  ],
);
~~~
## View method
Returns a Map<String,dynamic> with parsed .bson contents. You will see that the only property that stored Map<String,dynamic> contains is "uuid". The reason is that this are references not the actual Object.
~~~dart
Entry entry = Entry(dbPath: "./database");
List<DbObject> objects = entry.select().selectMultiple(
  key: "Stores",
);
for(DbObject object in objects){
  print(object.view());
}
~~~
## Delete method
If your delete target is an object reference(Map<String,dynamic> with uuid) deletes the object and all linked/referenced objects(children).
~~~dart
Entry entry = Entry(dbPath: "./database");
List<DbObject> objects = entry.select().selectMultiple(
  key: "Stores",
);
DbObject pizzaPlace = objects.firstWhere((element)=> (element.view()["Name"] as String).toLowerCase().contains("pizza"));
entry.select().delete(
  key: "Stores", 
  uuid: pizzaPlace.uuid,
);
~~~
## Delete key method
If your target is a String, double or int, the property gets removed from the target object.
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().deleteKey(key: "string");
~~~
## Pop method
If the key value is of type List it will remove the element at the specified index.
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().pop(
  index: 1, 
  key: "numbers",
);
~~~
## Insert at method
If the key value is a List the specified value will be inserted at the specified index.
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().insertAt(
  index: 1, 
  key: "numbers",
  value: [
    78,
  ],
);
~~~
## Replace at method
Replaces the value at the specified index. Since objects store a reference to a file containing the entire object they cannot be replaced.
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().replaceAt(
  index: 1, 
  key: "numbers",
  value: [
    1105,
  ],
);
~~~
## Move item method
Moves item on the list
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().move(
  key: "numbers", 
  from: 3, 
  to: 2,
);
~~~
## Swap item method
Swaps the position of list items
~~~dart
Entry entry = Entry(dbPath: "./database");
entry.select().swap(
  key: "numbers", 
  from: 0, 
  to: 1,
);
~~~
Encryption
 ------------------------------------------------
 Chromarotor cipher is a symmetric criptographic methot I created and co engineered using AI to cipher data without introducing encryption overhead. It is inspired by multiple things like image generation, the enigma machine and ray tracing to create a complex reversible cipher.
 ## Additional import
 ~~~dart
import 'package:chromarotor/chromarotor.dart';
 ~~~
 ## Encrypt database
 ~~~dart
Entry entry = Entry(
  dbPath: "./database",
  cipherKeys: generateImage(
    seed: BigInt.from(7863),
  ),
);
entry.encryptEntireDatabase();
 ~~~
 ## Decrypt database
 ~~~dart
Entry entry = Entry(
  dbPath: "./database",
  cipherKeys: generateImage(
    seed: BigInt.from(7863),
  ),
);
entry.decryptEntireDatabase();
 ~~~
 ## Change database password
 ~~~dart
ChromaImage newPassword = generateImage(
  seed: BigInt.from(1034),
);
Entry entry = Entry(
  dbPath: "./database",
  cipherKeys: newPassword,
);
entry.changeDatabasePassword(
  oldPassword: generateImage(
    seed: BigInt.from(7863),
  ),
);
 ~~~