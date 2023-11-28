import data_integration.store;
import ballerina/http;
import ballerina/persist;

final store:Client dbClient = check new ();

service / on new http:Listener(9090) {
    resource function post employees(store:EmployeeInsert employee)
            returns http:Created|http:Conflict|http:InternalServerError {
        int[]|persist:Error result = dbClient->/employees.post([employee]);
        if result is persist:AlreadyExistsError {
            return http:CONFLICT;
        }
        if result is persist:Error {
            return <http:InternalServerError>{body: result.message()};
        }
        return http:CREATED;
    }

    resource function post task(store:TaskInsert task)
            returns http:Created|http:Conflict|http:InternalServerError {
        int[]|persist:Error result = dbClient->/tasks.post([task]);
        if result is persist:AlreadyExistsError {
            return http:CONFLICT;
        }
        if result is persist:Error {
            return <http:InternalServerError>{body: result.message()};
        }
        return http:CREATED;
    }

    resource function get task/[int taskId]() returns http:Ok|http:NotFound|http:InternalServerError {
        store:Task|persist:Error task = dbClient->/tasks/[taskId];
        if task is persist:Error {
            if task is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: task.message()};
        }
        return <http:Ok>{body: task};
    }

    resource function get employeetasks/[int empId]() returns http:Ok|http:NotFound|http:InternalServerError {
        store:Task[]|persist:Error tasks = from store:Task task
                in dbClient->/tasks(store:Task)
            where task.employeeId == empId
            select task;
        if tasks is persist:Error {
            if tasks is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: tasks.message()};
        }
        return <http:Ok>{body: tasks};
    }

    resource function get employee/[int empId]() returns http:Ok|http:NotFound|http:InternalServerError {
        store:Employee|persist:Error employee = dbClient->/employees/[empId];
        if employee is persist:Error {
            if employee is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: employee.message()};
        }
        return <http:Ok>{body: employee};
    }

    resource function put task/[int taskId](store:TaskUpdate emp)
            returns http:Ok|http:InternalServerError {
        store:Task|persist:Error result = dbClient->/tasks/[taskId].put(emp);
        if result is persist:Error {
            return <http:InternalServerError>{body: result.message()};
        }
        return <http:Ok>{body: result};
    }

    resource function delete task/[int taskId]()
            returns http:NoContent|http:NotFound|http:InternalServerError {
        store:Task|persist:Error task = dbClient->/tasks/[taskId];
        if task is persist:Error {
            if task is persist:NotFoundError {
                return http:NOT_FOUND;
            }
            return <http:InternalServerError>{body: task.message()};
        }
        if task.status != store:COMPLETED {
            return <http:InternalServerError>{body: "Task is not completed yet"};
        }
        store:Task|persist:Error deleteResult = dbClient->/tasks/[taskId].delete;
        if deleteResult is persist:Error {
            return <http:InternalServerError>{body: deleteResult.message()};
        }
        return http:NO_CONTENT;
    }
}