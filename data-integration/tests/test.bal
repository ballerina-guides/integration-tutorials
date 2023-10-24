import data_integration.store;
import ballerina/http;
import ballerina/lang.runtime;
import ballerina/os;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/taskmanager`, retryConfig = {maxWaitInterval: 12});

@test:AfterSuite {}
function afterSuite() returns error? {
    _ = check stopDBService();
}

@test:Config
function testEmployee() returns error? {
    http:Response res = check cl->/employee.post({
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
function testTask() returns error? {
    http:Response res = check cl->/task.post({
        taskId: 1008,
        taskName: "IT Training Workshop'",
        description: "Organize a workshop",
        status: "IN_PROGRESS",
        employeeId: 2
    });

    test:assertEquals(res.statusCode, http:CREATED.status.code);
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
        status: "IN_PROGRESS",
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
function testPutEmployee() returns error? {
    store:EmployeeTask res = check cl->/task/[1001];
    test:assertEquals(res.status, "IN_PROGRESS");

    store:EmployeeTaskUpdate updatedTask = {
        status: "COMPLETED"
    };

    store:EmployeeTask updatedRes = check cl->/task/[1001].put(updatedTask);
    test:assertEquals(updatedRes.status, "COMPLETED");
}

@test:Config
function testDeleteEmployeeTask() returns error? {
    http:Response res = check cl->/task/[1001].delete();
    test:assertEquals(res.statusCode, http:NO_CONTENT.status.code);
}

@test:Mock {
    functionName: "getDBClient"
}

function getDBClientMock() returns store:Client|error {
    _ = check startDBService();
    return new store:Client();
}

function startDBService() returns os:Process|os:Error {
    os:Command command = {
        value: "docker-compose",
        arguments: ["up"]
    };
    os:Process|os:Error exec = os:exec(command);
    runtime:sleep(10);
    return exec;
}

isolated function stopDBService() returns os:Process|os:Error {
    os:Command command = {
        value: "docker-compose",
        arguments: ["down"]
    };
    os:Process|os:Error exec = os:exec(command);
    runtime:sleep(10);
    return exec;
}
