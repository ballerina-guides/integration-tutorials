import data_integration.store;
import ballerina/http;
import ballerina/persist;

configurable int port = 9090;

service /taskmanager on new http:Listener(port) {
    private final store:Client dbClient;

    function init() returns error? {
        self.dbClient = check getDBClient();
    }

    isolated resource function post employee(store:EmployeeInsert employee)
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

    isolated resource function post task(store:EmployeeTaskInsert task)
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
        store:EmployeeTask|persist:Error result = self.dbClient->/employeetasks/[taskId];
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function get employeetasks/[int empId]() returns http:Ok|http:NotFound|http:InternalServerError {
        store:EmployeeTask[]|persist:Error result = from store:EmployeeTask task in self.dbClient->/employeetasks(store:EmployeeTask)
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
        store:Employee|persist:Error result = self.dbClient->/employees/[empId];
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function put task/[int taskId](store:EmployeeTaskUpdate emp)
            returns http:Ok|http:InternalServerError {
        store:EmployeeTask|persist:Error result = self.dbClient->/employeetasks/[taskId].put(emp);
        if result is persist:Error {
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    isolated resource function delete task/[int taskId]()
            returns http:NoContent|http:NotFound|http:InternalServerError {
        store:EmployeeTask[]|persist:Error result = from store:EmployeeTask task in self.dbClient->/employeetasks(store:EmployeeTask)
            where task.taskId == taskId
                && task.status == store:COMPLETED
            select task;
        if result is persist:Error {
            if result is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: result.message()};
        }
        foreach store:EmployeeTask task in result {
            store:EmployeeTask|persist:Error deleteResult = self.dbClient->/employeetasks/[task.taskId].delete;
            if deleteResult is persist:Error {
                return <http:InternalServerError>{body: deleteResult.message()};
            }
        }
        return http:NO_CONTENT;
    }
}

function getDBClient() returns store:Client|error => new ();
