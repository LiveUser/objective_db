import 'package:objective_db/objective_db.dart';
import 'package:chromarotor/chromarotor.dart';
import 'package:test/test.dart';

void main() {
  test('Create some basic data entries', () {
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(
      key: "string", 
      value: "A string",
    );
    entry.select().insert(
      key: "numbers", 
      value: [],
    );
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
    print(createdUUIDs);
  });
  test("Add numbers to list",(){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(
      key: "numbers", 
      value: [1,2,3,4,5],
    );
  });
  test("Pop item",(){
    Entry entry = Entry(dbPath: "./database");
    entry.select().pop(
      index: 1, 
      key: "numbers",
    );
  });
  test("Insert at",(){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insertAt(
      index: 1, 
      key: "numbers",
      value: [
        78,
      ],
    );
  });
  test("Replace at",(){
    Entry entry = Entry(dbPath: "./database");
    entry.select().replaceAt(
      index: 1, 
      key: "numbers",
      value: [
        1105,
      ],
    );
  });
  test("Create empty object", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(
      key: "emptyObject",
      value: Map<String,dynamic>.from({}),
    );
  });
  test("Delete empty object", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().deleteKey(key: "emptyObject");
  });
  test("Select and print entry", (){
    Entry entry = Entry(dbPath: "./database");
    print(entry.select().view());
  });
  test("Change the value", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(
      key: "string", 
      value: "Another string",
    );
  });
  test("Select and print data", (){
    Entry entry = Entry(dbPath: "./database");
    List<DbObject> objects = entry.select().selectMultiple(
      key: "Stores",
    );
    for(DbObject object in objects){
      print(object.view());
    }
  });
  test("Delete objects and references", (){
    Entry entry = Entry(dbPath: "./database");
    List<DbObject> objects = entry.select().selectMultiple(
      key: "Stores",
    );
    DbObject pizzaPlace = objects.firstWhere((element)=> (element.view()["Name"] as String).toLowerCase().contains("pizza"));
    entry.select().delete(
      key: "Stores", 
      uuid: pizzaPlace.uuid,
    );
  });
  test("Delete key", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().deleteKey(key: "string");
  });
  test("Insert empty list", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(key: "empty", value: []);
  });
  test("Insert object into empty list", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(key: "empty", value: [
      {
        "something": "something",
      },
    ]);
  });
  test("Single Object", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().insert(key: "singleObject", 
    value: {
        "something": "somethingElse",
      },
    );
  });
  test("Swap function test", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().swap(
      key: "numbers", 
      from: 0, 
      to: 1,
    );
  });
  test("Move item function", (){
    Entry entry = Entry(dbPath: "./database");
    entry.select().move(
      key: "numbers", 
      from: 3, 
      to: 2,
    );
  });
  test("Encrypt entire database", (){
    Entry entry = Entry(
      dbPath: "./database",
      cipherKeys: generateImage(
        seed: BigInt.from(7863),
      ),
    );
    entry.encryptEntireDatabase();
  });
  test("Display entry point", (){
    Entry entry = Entry(
      dbPath: "./database",
      cipherKeys: generateImage(
        seed: BigInt.from(7863),
      ),
    );
    print(entry.select().view());
  });
  test("Decrypt entire database", (){
    Entry entry = Entry(
      dbPath: "./database",
      cipherKeys: generateImage(
        seed: BigInt.from(7863),
      ),
    );
    entry.decryptEntireDatabase();
  });
  test("Change password",(){
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
  });
  test("Flush all stores",(){
    ChromaImage newPassword = generateImage(
      seed: BigInt.from(1034),
    );
    Entry entry = Entry(
      dbPath: "./database",
      cipherKeys: newPassword
    );
    List<DbObject> objects = entry.select().selectMultiple(
      key: "Stores",
    );
    for(DbObject object in objects){
      entry.select().delete(key: "Stores", uuid: object.uuid);
    }
  });
}
