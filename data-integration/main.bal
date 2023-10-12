import ballerina/http;
import ballerina/os;
import ballerina/persist;
import ballerina/lang.runtime;
import data_integration.db;

configurable int port = 9090;

service /employees on new http:Listener(9090) {
    private final db:Client dbClient;

    function init() returns error? {
        _ = check startDBService();
        self.dbClient  = check new();
    }

    isolated resource function post employees(db:EmployeeInsert employee)
            returns http:InternalServerError|http:Created|http:Conflict {
        int[]|persist:Error result = self.dbClient->/employees.post([employee]);
        if result is persist:Error {
            if result is persist:AlreadyExistsError {
                return http:CONFLICT;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return http:CREATED;
    }

    isolated resource function post tasks(db:EmployeeTaskInsert task)
            returns http:InternalServerError|http:Created|http:Conflict {
        int[]|persist:Error result = self.dbClient->/employeetasks.post([task]);
        if result is persist:Error {
            if result is persist:AlreadyExistsError {
                return http:CONFLICT;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        return http:CREATED;
    }

    isolated resource function get tasks(int empId) returns db:EmployeeTask[]|error {
        stream<db:EmployeeTask, persist:Error?> tasks = self.dbClient->/employeetasks;
        return from db:EmployeeTask task in tasks
            where task.employeeId == empId
            select task;
    }

    isolated resource function get employees(int empId) returns db:Employee[]|error {
        stream<db:Employee, persist:Error?> employees = self.dbClient->/employees;
        return from db:Employee employee in employees
            where employee.id == empId
            select employee;
    }

    isolated resource function put [int taskId](db:EmployeeTaskUpdate emp) returns db:EmployeeTask|persist:Error {
        return check self.dbClient->/employeetasks/[taskId].put(emp);
    }

    isolated resource function delete tasks/[int taskId]()
            returns http:InternalServerError|http:NoContent|http:NotFound {
        stream<db:EmployeeTask, persist:Error?> tasks = self.dbClient->/employeetasks;
        db:EmployeeTask[]|persist:Error result = from db:EmployeeTask task in tasks
            where task.taskId == taskId
                && task.status == "COMPLETED"
            select task;
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return http:INTERNAL_SERVER_ERROR;
        }
        foreach db:EmployeeTask task in result {
            db:EmployeeTask|persist:Error deleteResult = self.dbClient->/employeetasks/[task.taskId].delete;
            if deleteResult is persist:Error {
                return http:INTERNAL_SERVER_ERROR;
            }
        }
        return http:NO_CONTENT;
    }
}

function startDBService() returns os:Process|os:Error {
    os:Command command = {value: "docker-compose", 
    arguments: ["up"]};
    os:Process|os:Error exec = os:exec(command);
    runtime:sleep(4);
    return exec;
}

isolated function stopDBService() returns os:Process|os:Error {
    os:Command command = {value: "docker-compose", 
    arguments: ["down"]};
    os:Process|os:Error exec = os:exec(command);
    runtime:sleep(4);
    return exec;
}
