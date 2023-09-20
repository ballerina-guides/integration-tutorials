// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

import ballerina/persist;
import ballerina/jballerina.java;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/persist.sql as psql;

const PERSON = "people";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [PERSON] : {
            entityName: "Person",
            tableName: "Person",
            fieldMetadata: {
                firstName: {columnName: "firstName"},
                lastName: {columnName: "lastName"},
                phone: {columnName: "phone"}
            },
            keyFields: ["firstName", "lastName"]
        }
    };

    public isolated function init() returns persist:Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {[PERSON] : check new (dbClient, self.metadata.get(PERSON), psql:MYSQL_SPECIFICS)};
    }

    isolated resource function get people(PersonTargetType targetType = <>) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get people/[string firstName]/[string lastName](PersonTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post people(PersonInsert[] data) returns [string, string][]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from PersonInsert inserted in data
            select [inserted.firstName, inserted.lastName];
    }

    isolated resource function put people/[string firstName]/[string lastName](PersonUpdate value) returns Person|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON);
        }
        _ = check sqlClient.runUpdateQuery({"firstName": firstName, "lastName": lastName}, value);
        return self->/people/[firstName]/[lastName].get();
    }

    isolated resource function delete people/[string firstName]/[string lastName]() returns Person|persist:Error {
        Person result = check self->/people/[firstName]/[lastName].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(PERSON);
        }
        _ = check sqlClient.runDeleteQuery({"firstName": firstName, "lastName": lastName});
        return result;
    }

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

