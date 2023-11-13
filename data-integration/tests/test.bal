import data_integration.store;
import ballerina/http;
import ballerina/test;
import ballerina/persist;

final http:Client cl = check new (string `http://localhost:${port}/`);

@test:Config
function testEmployee() returns error? {
    store:Employee emp = {
        id: 4,
        name: "John Doe",
        age: 22,
        phone: "8770586755",
        email: "johnDoe@gmail.com",
        department: "IT"
    };

    http:Response res = check cl->/employee.post(emp);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);
    
    store:Employee|persist:Error employee = dbClient->/employees/[4];
    if employee is persist:Error {
        test:assertFail(employee.message());
    }
    test:assertEquals(emp, employee);
}

@test:Config
function testTask() returns error? {
    store:EmployeeTask task = {
        taskId: 1008,
        taskName: "IT Training Workshop'",
        description: "Organize a workshop",
        status: store:IN_PROGRESS,
        employeeId: 2
    };

    http:Response res = check cl->/task.post(task);
    test:assertEquals(res.statusCode, http:STATUS_CREATED);

    store:EmployeeTask|persist:Error empTask = dbClient->/employeetasks/[1008];
    if empTask is persist:Error {
        test:assertFail(empTask.message());  
    }
    test:assertEquals(task, empTask);
}

@test:Config
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
function testGetTask() returns error? {
    store:EmployeeTask res = check cl->/task/[1001];
    store:EmployeeTask expectedRes = {
        taskId: 1001,
        taskName: "Update Server Security",
        description: "Implement the latest security patches and configurations",
        status: store:IN_PROGRESS,
        employeeId: 1
    };

    test:assertEquals(res, expectedRes);
}

@test:Config
function testGetEmployeeTasks() returns error? {
    store:EmployeeTask[] res = check cl->/employeetasks/[1];
    store:EmployeeTask[] expectedRes = [
        {
            taskId: 1001,
            taskName: "Update Server Security",
            description: "Implement the latest security patches and configurations",
            status: store:IN_PROGRESS,
            employeeId: 1
        },
        {
            taskId: 1002,
            taskName: "Network Optimization",
            description: "Analyze network performance",
            status: store:NOT_STARTED,
            employeeId: 1
        },
        {
            taskId: 1003,
            taskName: "Database Migration",
            description: "Migrate database from MySQL to PostgreSQL",
            status: store:COMPLETED,
            employeeId: 1
        }
    ];

    test:assertEquals(res, expectedRes);
}

@test:Config
function testPutEmployee() returns error? {
    store:EmployeeTask res = check cl->/task/[1001];
    test:assertEquals(res.status, "IN_PROGRESS");

    store:EmployeeTaskUpdate updatedTask = {
        status: store:COMPLETED
    };

    store:EmployeeTask updatedRes = check cl->/task/[1001].put(updatedTask);
    test:assertEquals(updatedRes.status, "COMPLETED");
}

@test:Config
function testDeleteEmployeeTask() returns error? {
    http:Response res = check cl->/task/[1004].delete();
    test:assertEquals(res.statusCode, http:STATUS_NO_CONTENT);
}
