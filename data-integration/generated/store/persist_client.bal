// AUTO-GENERATED FILE. DO NOT MODIFY.
// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.
import ballerina/jballerina.java;
import ballerina/persist;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerinax/persist.sql as psql;

const EMPLOYEE = "employees";
const TASK = "tasks";

public isolated client class Client {
    *persist:AbstractPersistClient;

    private final mysql:Client dbClient;

    private final map<psql:SQLClient> persistClients;

    private final record {|psql:SQLMetadata...;|} & readonly metadata = {
        [EMPLOYEE] : {
            entityName: "Employee",
            tableName: "Employee",
            fieldMetadata: {
                id: {columnName: "id"},
                name: {columnName: "name"},
                age: {columnName: "age"},
                phone: {columnName: "phone"},
                email: {columnName: "email"},
                department: {columnName: "department"},
                "tasks[].taskId": {relation: {entityName: "tasks", refField: "taskId"}},
                "tasks[].description": {relation: {entityName: "tasks", refField: "description"}},
                "tasks[].status": {relation: {entityName: "tasks", refField: "status"}},
                "tasks[].employeeId": {relation: {entityName: "tasks", refField: "employeeId"}}
            },
            keyFields: ["id"],
            joinMetadata: {tasks: {entity: Task, fieldName: "tasks", refTable: "Task", refColumns: ["employeeId"], joinColumns: ["id"], 'type: psql:MANY_TO_ONE}}
        },
        [TASK] : {
            entityName: "Task",
            tableName: "Task",
            fieldMetadata: {
                taskId: {columnName: "taskId"},
                description: {columnName: "description"},
                status: {columnName: "status"},
                employeeId: {columnName: "employeeId"},
                "employee.id": {relation: {entityName: "employee", refField: "id"}},
                "employee.name": {relation: {entityName: "employee", refField: "name"}},
                "employee.age": {relation: {entityName: "employee", refField: "age"}},
                "employee.phone": {relation: {entityName: "employee", refField: "phone"}},
                "employee.email": {relation: {entityName: "employee", refField: "email"}},
                "employee.department": {relation: {entityName: "employee", refField: "department"}}
            },
            keyFields: ["taskId"],
            joinMetadata: {employee: {entity: Employee, fieldName: "employee", refTable: "Employee", refColumns: ["id"], joinColumns: ["employeeId"], 'type: psql:ONE_TO_MANY}}
        }
    };

    public isolated function init() returns persist:Error? {
        mysql:Client|error dbClient = new (host = host, user = user, password = password, database = database, port = port, options = connectionOptions);
        if dbClient is error {
            return <persist:Error>error(dbClient.message());
        }
        self.dbClient = dbClient;
        self.persistClients = {
            [EMPLOYEE] : check new (dbClient, self.metadata.get(EMPLOYEE), psql:MYSQL_SPECIFICS),
            [TASK] : check new (dbClient, self.metadata.get(TASK), psql:MYSQL_SPECIFICS)
        };
    }

    isolated resource function get employees(EmployeeTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get employees/[int id](EmployeeTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post employees(EmployeeInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EMPLOYEE);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from EmployeeInsert inserted in data
            select inserted.id;
    }

    isolated resource function put employees/[int id](EmployeeUpdate value) returns Employee|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EMPLOYEE);
        }
        _ = check sqlClient.runUpdateQuery(id, value);
        return self->/employees/[id].get();
    }

    isolated resource function delete employees/[int id]() returns Employee|persist:Error {
        Employee result = check self->/employees/[id].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(EMPLOYEE);
        }
        _ = check sqlClient.runDeleteQuery(id);
        return result;
    }

    isolated resource function get tasks(TaskTargetType targetType = <>, sql:ParameterizedQuery whereClause = ``, sql:ParameterizedQuery orderByClause = ``, sql:ParameterizedQuery limitClause = ``, sql:ParameterizedQuery groupByClause = ``) returns stream<targetType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "query"
    } external;

    isolated resource function get tasks/[int taskId](TaskTargetType targetType = <>) returns targetType|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor",
        name: "queryOne"
    } external;

    isolated resource function post tasks(TaskInsert[] data) returns int[]|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK);
        }
        _ = check sqlClient.runBatchInsertQuery(data);
        return from TaskInsert inserted in data
            select inserted.taskId;
    }

    isolated resource function put tasks/[int taskId](TaskUpdate value) returns Task|persist:Error {
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK);
        }
        _ = check sqlClient.runUpdateQuery(taskId, value);
        return self->/tasks/[taskId].get();
    }

    isolated resource function delete tasks/[int taskId]() returns Task|persist:Error {
        Task result = check self->/tasks/[taskId].get();
        psql:SQLClient sqlClient;
        lock {
            sqlClient = self.persistClients.get(TASK);
        }
        _ = check sqlClient.runDeleteQuery(taskId);
        return result;
    }

    remote isolated function queryNativeSQL(sql:ParameterizedQuery sqlQuery, typedesc<record {}> rowType = <>) returns stream<rowType, persist:Error?> = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    remote isolated function executeNativeSQL(sql:ParameterizedQuery sqlQuery) returns psql:ExecutionResult|persist:Error = @java:Method {
        'class: "io.ballerina.stdlib.persist.sql.datastore.MySQLProcessor"
    } external;

    public isolated function close() returns persist:Error? {
        error? result = self.dbClient.close();
        if result is error {
            return <persist:Error>error(result.message());
        }
        return result;
    }
}

