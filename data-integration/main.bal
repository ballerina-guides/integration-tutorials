import data_integration.store;
import ballerina/http;
import ballerina/persist;

final store:Client dbClient = check new;

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

    resource function post tasks(store:TaskInsert task)
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

    resource function get tasks/[int taskId]() returns store:Task|http:NotFound|http:InternalServerError {
        store:Task|persist:Error task = dbClient->/tasks/[taskId];
        if task is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if task is persist:Error {
            return <http:InternalServerError>{body: task.message()};
        }
        return task;
    }

    resource function get employees/[int empId]/tasks() returns store:Task[]|http:NotFound|http:InternalServerError {
        store:Task[]|persist:Error tasks = from store:Task task in dbClient->/tasks(store:Task)
            where task.employeeId == empId
            select task;
        if tasks is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if tasks is persist:Error {
            return <http:InternalServerError>{body: tasks.message()};
        }
        return tasks;
    }

    resource function get employees/[int empId]() returns store:Employee|http:NotFound|http:InternalServerError {
        store:Employee|persist:Error employee = dbClient->/employees/[empId];
        if employee is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if employee is persist:Error {
            return <http:InternalServerError>{body: employee.message()};
        }
        return employee;
    }

    resource function put tasks/[int taskId](store:TaskUpdate task)
            returns store:Task|http:NotFound|http:InternalServerError {
        store:Task|persist:Error empTask = dbClient->/tasks/[taskId];
        if empTask is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        store:Task|persist:Error updatedTask = dbClient->/tasks/[taskId].put(task);
        if updatedTask is persist:Error {
            return <http:InternalServerError>{body: updatedTask.message()};
        }
        return updatedTask;
    }

    resource function delete tasks/[int taskId]()
            returns http:NoContent|http:NotFound|http:InternalServerError {
        store:Task|persist:Error task = dbClient->/tasks/[taskId];
        if task is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if task is persist:Error {
            return <http:InternalServerError>{body: task.message()};
        }
        if task.status != store:COMPLETED {
            return <http:InternalServerError>{body: "Task is not completed yet"};
        }
        store:Task|persist:Error deletedTask = dbClient->/tasks/[taskId].delete;
        if deletedTask is persist:Error {
            return <http:InternalServerError>{body: deletedTask.message()};
        }
        return http:NO_CONTENT;
    }
}
