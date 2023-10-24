import store.db;
import ballerina/http;
import ballerina/persist;

configurable int port = 9090;

service /taskmanager on new http:Listener(port) {
    private final db:Client dbClient;

    function init() returns error? {
        self.dbClient = check getDBClient();
    }

    isolated resource function post employee(db:EmployeeInsert employee)
            returns http:Created|http:Conflict|http:InternalServerError {
        int[]|persist:Error result = self.dbClient->/employees.post([employee]);
        if result is persist:Error {
            if result is persist:AlreadyExistsError {
                return http:CONFLICT;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return http:CREATED;
    }

    isolated resource function post task(db:EmployeeTaskInsert task)
            returns http:Created|http:Conflict|http:InternalServerError {
        int[]|persist:Error result = self.dbClient->/employeetasks.post([task]);
        if result is persist:Error {
            if result is persist:AlreadyExistsError {
                return http:CONFLICT;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return http:CREATED;
    }

    isolated resource function get task/[int taskId]() returns http:Ok|http:NotFound|http:InternalServerError {
        db:EmployeeTask|persist:Error result = self.dbClient->/employeetasks/[taskId];
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function get employeetasks/[int empId]() returns http:Ok|http:NotFound|http:InternalServerError {
        db:EmployeeTask[]|persist:Error result = from db:EmployeeTask task in self.dbClient->/employeetasks(db:EmployeeTask)
            where task.employeeId == empId
            select task;
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function get employee/[int empId]() returns http:Ok|http:NotFound|http:InternalServerError {
        db:Employee|persist:Error result = self.dbClient->/employees/[empId];
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function put task/[int taskId](db:EmployeeTaskUpdate emp)
            returns http:Ok|http:InternalServerError {
        db:EmployeeTask|persist:Error result = self.dbClient->/employeetasks/[taskId].put(emp);
        if result is persist:Error {
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function delete task/[int taskId]()
            returns http:NoContent|http:NotFound|http:InternalServerError {
        db:EmployeeTask[]|persist:Error result = from db:EmployeeTask task in self.dbClient->/employeetasks(db:EmployeeTask)
            where task.taskId == taskId
                && task.status == db:COMPLETED
            select task;
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        foreach db:EmployeeTask task in result {
            db:EmployeeTask|persist:Error deleteResult = self.dbClient->/employeetasks/[task.taskId].delete;
            if deleteResult is persist:Error {
                return <http:InternalServerError>{body: deleteResult.message()};
            }
        }
        return http:NO_CONTENT;
    }
}

function getDBClient() returns db:Client|error => new ();
