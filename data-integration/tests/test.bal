import data_integration.store;
import ballerina/http;
import ballerina/persist;
import ballerina/test;

final http:Client cl = check new ("http://localhost:9090/");

const store:Employee EMPLOYEE = {
    id: 1,
    name: "John Doe",
    age: 22,
    phone: "8770586755",
    email: "johndoe@gmail.com",
    department: "IT"
};

const store:Task EMPLOYEE_TASK = {
    taskId: 1001,
    description: "Organize a workshop",
    status: store:IN_PROGRESS,
    employeeId: 1
};

@test:Config
function testAddEmployee() returns error? {
    http:Response res = check cl->/employees.post(EMPLOYEE);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);

    store:Employee|persist:Error employee = dbClient->/employees/[1];
    if employee is persist:Error {
        test:assertFail(employee.message());
    }
    test:assertEquals(EMPLOYEE, employee);
}

@test:Config {
    dependsOn: [testAddEmployee]
}
function testAddTask() returns error? {
    http:Response res = check cl->/tasks.post(EMPLOYEE_TASK);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);

    store:Task|persist:Error empTask = dbClient->/tasks/[1001];
    if empTask is persist:Error {
        test:assertFail(empTask.message());
    }
    test:assertEquals(EMPLOYEE_TASK, empTask);
}

@test:Config {
    dependsOn: [testAddEmployee]
}
function testGetEmployee() returns error? {
    store:Employee res = check cl->/employees/[1];
    test:assertEquals(res, EMPLOYEE);
}

@test:Config {
    dependsOn: [testAddTask]
}
function testGetTask() returns error? {
    store:Task res = check cl->/tasks/[1001];
    test:assertEquals(res, EMPLOYEE_TASK);
}

@test:Config {
    dependsOn: [testAddTask]
}
function testGetEmployeeTasks() returns error? {
    store:Task[] res = check cl->/employees/[1]/tasks;
    test:assertEquals(res, [EMPLOYEE_TASK]);
}

@test:Config {
    dependsOn: [testDeleteInProgressTask]
}
function testPutEmployee() returns error? {
    store:Task res = check cl->/tasks/[1001];
    test:assertEquals(res.status, "IN_PROGRESS");

    store:TaskUpdate updatedTask = {
        status: store:COMPLETED
    };

    store:Task updatedRes = check cl->/tasks/[1001].put(updatedTask);
    test:assertEquals(updatedRes.status, "COMPLETED");
}

@test:Config {
    dependsOn: [testAddTask]
}
function testDeleteInProgressTask() returns error? {
    http:Response res = check cl->/tasks/[1001].delete();
    test:assertEquals(res.statusCode, http:STATUS_INTERNAL_SERVER_ERROR);
}

@test:Config {
    dependsOn: [testPutEmployee]
}
function testDeleteEmployeeTask() returns error? {
    http:Response res = check cl->/tasks/[1001].delete();
    test:assertEquals(res.statusCode, http:STATUS_NO_CONTENT);
}
