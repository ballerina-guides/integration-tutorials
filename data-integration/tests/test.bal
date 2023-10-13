import ballerina/http;
import ballerina/test;
import data_integration.db;

final http:Client cl = check new (string `http://localhost:${port}/employees`, retryConfig = {maxWaitInterval: 12});

@test:AfterSuite {}
function afterSuite() returns error? {
    _ = check stopDBService();
}

@test:Config
isolated function testEmployee() returns error? {
    http:Response res = check cl->/employees.post({
        id: 4,
        name: "John Doe",
        age: 22,
        phone: "8770586755",
        email: "johnDoe@gmail.com",
        department: "IT"
    });

    test:assertEquals(res.statusCode, http:CREATED.status.code);
}

@test:Config
isolated function testTask() returns error? {
    http:Response res = check cl->/tasks.post({
        taskId: 1008,
        taskName: "IT Training Workshop'",
        description: "Organize a workshop",
        status: "IN_PROGRESS",
        employeeId: 2
    });

    test:assertEquals(res.statusCode, http:CREATED.status.code);
}

@test:Config
isolated function testGetEmployee() returns error? {
    db:Employee[] res = check cl->/employees(empId = 1);
    db:Employee expectedRes = {
        id: 1,
        name: "John Doe",
        age: 22,
        phone: "8770586755",
        email: "johndoe@gmail.com",
        department: "IT"
    };

    test:assertEquals(res[0], expectedRes);
}

@test:Config
isolated function testGetTask() returns error? {
    db:EmployeeTask[] res = check cl->/tasks(taskId = 1001);
    db:EmployeeTask expectedRes = {
        taskId: 1001,
        taskName: "Update Server Security",
        description: "Implement the latest security patches and configurations",
        status: "IN_PROGRESS",
        employeeId: 1
    };

    test:assertEquals(res[0], expectedRes);
}

@test:Config
isolated function testGetEmployeeTasks() returns error? {
    db:EmployeeTask[] res = check cl->/tasks/employee(empId = 1);
    db:EmployeeTask[] expectedRes = [
        {
            taskId: 1001,
            taskName: "Update Server Security",
            description: "Implement the latest security patches and configurations",
            status: "IN_PROGRESS",
            employeeId: 1
        },
        {
            taskId: 1002,
            taskName: "Network Optimization",
            description: "Analyze network performance",
            status: "NOT_STARTED",
            employeeId: 1
        },
        {
            taskId: 1003,
            taskName: "Database Migration",
            description: "Migrate database from MySQL to PostgreSQL",
            status: "COMPLETED",
            employeeId: 1
        }
    ];

    test:assertEquals(res, expectedRes);
}

@test:Config
isolated function testPutEmployee() returns error? {
    db:EmployeeTask[] res = check cl->/tasks(taskId = 1001);
    test:assertEquals(res[0].status, "IN_PROGRESS");

    db:EmployeeTaskUpdate updatedTask = {
        status: "COMPLETED"
    };

    db:EmployeeTask updatedRes = check cl->/tasks/[1001].put(updatedTask);
    test:assertEquals(updatedRes.status, "COMPLETED");
}

@test:Config
isolated function testDeleteEmployeeTask() returns error? {
    http:Response res = check cl->/tasks/[1001].delete();
    test:assertEquals(res.statusCode, http:NO_CONTENT.status.code);
}
