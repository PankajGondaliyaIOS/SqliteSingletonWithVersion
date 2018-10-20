//
//  DatabaseBusinessLogicManager.swift
//  SqliteDatabaseSingleton
//
//  Created by pankaj on 16/01/18.
//  Copyright © 2018 Pankaj. All rights reserved.
//

import Foundation

//DatabaseManager->BusinessLogic->RequesterClass
//DatabaseManager-> Will have core operations
//BusinessLogic-> Will have operations distinguished by tables. Each table will have all the related methods in a group
//CallerClass-> It will request all database operations to BusinessLogic class, and that class to DatabaseManager and will respond to the CallerClass using block responses.

class DatabaseBusinessLogicManager {
    static var instance: DatabaseBusinessLogicManager?
    static func sharedInstance() -> DatabaseBusinessLogicManager {
        if self.instance == nil {
            self.instance = DatabaseBusinessLogicManager()
        }
        return self.instance!
    }
}

//MARK:- Table Students
extension DatabaseBusinessLogicManager {
    
    func fetchAllStudents(sucess:(_ arrSutdents: NSMutableArray)->Void, failure:(_ isFailed:String)->Void) {
        let queryStatementString = "SELECT * FROM Student;"
        DatabaseManager.sharedInstance().fetchUser(strQuery: queryStatementString, sucess: { (arrUser) in
            sucess(arrUser)
        }) { (strError) in
            failure(strError)
        }
    }
}
