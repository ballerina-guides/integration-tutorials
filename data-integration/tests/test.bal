import data_integration.store;
import ballerina/http;
import ballerina/test;
import ballerina/persist;

final http:Client cl = check new ("http://localhost:9090/");

@test:Config
function testEmployee() returns error? {
    store:Employee emp = {
        id: 1,
        name: "John Doe",
        age: 22,
        phone: "8770586755",
        email: "johndoe@gmail.com",
        department: "IT"
    };

    http:Response res = check cl->/employees.post(emp);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);
    
    store:Employee|persist:Error employee = dbClient->/employees/[1];
    if employee is persist:Error {
        test:assertFail(employee.message());
    }
    test:assertEquals(emp, employee);
}

@test:Config
{dependsOn: [testEmployee]}
function testTask() returns error? {
    store:Task task = {
        taskId: 1001,
        description: "Organize a workshop",
        status: store:IN_PROGRESS,
        employeeId: 1
    };

    http:Response res = check cl->/task.post(task);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);

    store:Task|persist:Error empTask = dbClient->/tasks/[1001];
    if empTask is persist:Error {
        test:assertFail(empTask.message());  
    }
    test:assertEquals(task, empTask);
}

@test:Config
{dependsOn: [testEmployee]}
function testGetEmployee() returns error? {
    store:Employee res = check cl->/employee/[1];
    store:Employee expectedRes = {
        id: 1,
        name: "John Doe",
        age: 22,
        phone: "8770586755",
        email: "johndoe@gmail.com",
        department: "IT"
    };

    test:assertEquals(res, expectedRes);
}

@test:Config
{dependsOn: [testTask]}
function testGetTask() returns error? {
    store:Task res = check cl->/task/[1001];
    store:Task expectedRes = {
        taskId: 1001,
        description: "Organize a workshop",
        status: store:IN_PROGRESS,
        employeeId: 1
    };

    test:assertEquals(res, expectedRes);
}

@test:Config
{dependsOn: [testTask]}
function testGetEmployeeTasks() returns error? {
    store:Task[] res = check cl->/employeetasks/[1];
    store:Task[] expectedRes = [
        {
            taskId: 1001,
            description: "Organize a workshop",
            status: store:IN_PROGRESS,
            employeeId: 1
        }
    ];

    test:assertEquals(res, expectedRes);
}

@test:Config
{dependsOn: [testTask]}
function testPutEmployee() returns error? {
    store:Task res = check cl->/task/[1001];
    test:assertEquals(res.status, "IN_PROGRESS");

    store:TaskUpdate updatedTask = {
        status: store:COMPLETED
    };

    store:Task updatedRes = check cl->/task/[1001].put(updatedTask);
    test:assertEquals(updatedRes.status, "COMPLETED");
}

@test:Config
{dependsOn: [testTask]}
function testDeleteEmployeeTask() returns error? {
    http:Response res = check cl->/task/[1001].delete();
    test:assertEquals(res.statusCode, http:STATUS_NO_CONTENT);
}