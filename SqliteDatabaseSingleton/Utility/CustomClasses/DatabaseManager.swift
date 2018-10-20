
//
//  DatabaseManager.swift
//  SqliteDatabaseSingleton
//
//  Created by Pankaj on 24/11/16.
//  Copyright © 2016 Pankaj. All rights reserved.
//

import Foundation

class DatabaseManager {
    static var instance: DatabaseManager?
    
    var documentDirectory: String?
    var databaseFilename: String = "StudentDB.sqlite"
    
    init() {
        copyDatabaseIntoDocumentsDirectory()
        createDatabase()
    }
    
    static func sharedInstance() -> DatabaseManager {
        if self.instance == nil {
            self.instance = DatabaseManager()
        }
        return self.instance!
    }
    
    //MARK: ========= Prepare For Database, Open and Copy ============
    func getDatabasePath() -> String {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
            ).first!
        documentDirectory = path
        let destinationPath: String = (self.documentDirectory?.stringByAppendingPathComponent(pathComponent: databaseFilename))!
        return destinationPath
    }
    
    func copyDatabaseIntoDocumentsDirectory() {
        var directory: ObjCBool = ObjCBool(false)
        let exists: Bool = FileManager.default.fileExists(atPath: getDatabasePath(), isDirectory: &directory)
        
        if exists {
            print("Already available")
        } else {
            let strsourcePath = Bundle.main.resourcePath?.stringByAppendingPathComponent(pathComponent: databaseFilename)
            do {
                print("copy from main bundle")
                try
                    FileManager.default.copyItem(atPath: strsourcePath!, toPath: getDatabasePath())
            } catch let error as NSError {
                print("error : \(error)")
            }
        }
    }
    
    func openDatabase() -> OpaquePointer {
        var db: OpaquePointer? = nil
        if sqlite3_open(getDatabasePath(), &db) == SQLITE_OK {
            print(" Database path: \(getDatabasePath())")
            return db!
        } else {
            print("Unable to open database.")
            return db!
        }
    }
    
    //MARK: Create Database
    func createDatabase() {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let previousVersion = UserDefaults.standard.string(forKey: StaticStrings.kPreviousBuildVersion)
        
        if(appVersion == previousVersion) {
            return //If build version is previous build version, then no need to create all the tables again or no need to update existing tables
        } else {
            if(previousVersion != nil) {
                // Else either create new table or update existing table
                createDatabaseStructureWithBuildVersion(previousBuildVersion: previousVersion!)
            } else {
                createDatabaseStructureWithBuildVersion(previousBuildVersion: appVersion!)
            }
            
        }
        
        UserDefaults.standard.set(appVersion, forKey: StaticStrings.kPreviousBuildVersion)
        UserDefaults.standard.synchronize()
    }
    
    //MARK: Create database structure
    func createDatabaseStructureWithBuildVersion(previousBuildVersion: String) {
        
        //Table 1: Student
        //Check if table is already exist
        //if table is already exist then check build version to add new columns if it is required to be added.
        
        if tableExists(tableName: "Student") == false {
            // table is not exist. Create table
            let createTableString = "CREATE TABLE Student(" +
                "Id INT PRIMARY KEY NOT NULL," +
                "Name CHAR(255)," + "image CHAR(1000));"
            createTable(strCreateTableString: createTableString, success: { (success) in
                
            }) { (failure) in
                
            }
        } else {
            let preVersion:Double = Double(previousBuildVersion)!
            //check version to update columns
            if(preVersion < 3.0) {
//                let sSQL="ALTER TABLE " + "STUDENT" + " ADD COLUMN " + "Age" + " INTEGER ";
//                if (alterTable(sqlQuery: sSQL, sTable: "STUDENT")) {
//                    print("Table Altered")
//                }
            }
        }
    }
    
    //MARK: ========= Create Table =============
    func createTable(strCreateTableString: String, success:(_ isCreated:Bool)->Void, failure:(_ isCreated:Bool)->Void) {
        var createTableStatement: OpaquePointer? = nil
        
        if sqlite3_prepare_v2(openDatabase(), strCreateTableString, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Table has been created.")
                success(true)
            } else {
                print("Unable to create table.")
                failure(false)
            }
        } else {
            print("Create statement error")
            failure(false)
        }
        sqlite3_finalize(createTableStatement)
    }
    
    //MARK: ========= Alter Table ===========
    func alterTable(sqlQuery:String, sTable:String) -> Bool {
        var bReturn:Bool = false;
        var statement:OpaquePointer? = nil
        if sqlite3_prepare_v2(openDatabase(), sqlQuery, -1, &statement, nil) != SQLITE_OK {
            print("Failed to prepare statement")
        }
        else {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Table Altered");
            }
            sqlite3_finalize(statement);
            bReturn=true;
        }
        return bReturn;
    }
    
    //MARK: ========= Insert Values =============
    func insertUser(user:User) {
        var insertStatement: OpaquePointer? = nil
        let strInsertQuerry = "INSERT INTO Student (Id, Name, image) VALUES (?, ?, ?);"
        if sqlite3_prepare_v2(openDatabase(), strInsertQuerry, -1, &insertStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(insertStatement, 1, Int32(user.strId!)!)
            sqlite3_bind_text(insertStatement, 2, user.strName!, -1, nil)
            sqlite3_bind_text(insertStatement, 3, user.strImageLocalPath!, -1, nil)
            if sqlite3_step(insertStatement) == SQLITE_DONE {
                print("Successfully inserted a row.")
            } else {
                print("Could not insert a row.")
            }
        } else {
            print("Insert statement error")
        }
        sqlite3_finalize(insertStatement)
    }
    
    
    //MARK:- ========= Fetch Records =========
    
    func fetchUser(strQuery: String, sucess:(_ arrSutdents: NSMutableArray)->Void, failure:(_ isFailed:String)->Void) {
        var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(openDatabase(), strQuery, -1, &queryStatement, nil) == SQLITE_OK {
            let arrUsers = NSMutableArray()
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                let id = sqlite3_column_int(queryStatement, 0)
                let name = sqlite3_column_text(queryStatement, 1)
                let image = sqlite3_column_text(queryStatement, 2)
                
                print(id)
                print(name as Any)
                print(image as Any)
                
                var user = User()
                user.strId = "\(id)"
                arrUsers.add(user)
                
            }
            sucess(arrUsers)
        } else {
            print("Unable to create fetch statement")
            failure("Unable to create fetch statement")
        }
        sqlite3_finalize(queryStatement)
    }
    
    //:MARK: ========= Update Records =========
    func update(strQuery: String) {
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(openDatabase(), strQuery, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("Unable to prepare update statement")
        }
        sqlite3_finalize(updateStatement)
    }
    
    //MARK: ========= Delete Records =========
    func delete(strQuery: String) {
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(openDatabase(), strQuery, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Row deleted successfully.")
            } else {
                print("Unable to delete row.")
            }
        } else {
            print("Unable to prepare delete statement")
        }
        sqlite3_finalize(deleteStatement)
    }
}

extension DatabaseManager {
    func tableExists(tableName: String) -> Bool {
        
        let strQuery = "SELECT name FROM sqlite_master WHERE type='table' AND name='\(tableName)';"
        
        var queryStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(openDatabase(), strQuery, -1, &queryStatement, nil) == SQLITE_OK {
            let arrUsers = NSMutableArray()
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                arrUsers.add("1")
            }
            if(arrUsers.count > 0) {
                return true
            } else {
                return false
            }
        } else {
            print("Unable to create fetch statement")
            return false
            //            failure("Unable to create fetch statement")
        }
        sqlite3_finalize(queryStatement)
    }
}

extension String {
    func stringByAppendingPathComponent(pathComponent: String) -> String {
        return (self as NSString).appendingPathComponent(pathComponent)
    }
}
