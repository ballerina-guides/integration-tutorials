# Data integration

## Overview

In this tutorial, you will develop a service to manage data stored in a database using bal persist. The service will be used to create, retrieve, update and delete data from the database.

To implement this use case, you will develop a REST service with multiple resources using Visual Studio Code with the Ballerina Swan Lake extension and define the `data model` using the `bal persist` feature.

The flow is as follows.

1. Create an employee.

   ```json
   {
        "id": 1,
        "name": "John Doe",
        "age": 22,
        "phone": "8770586755",
        "email": "johndoe@gmail.com",
        "department": "IT"
   }
   ```
2. Create a task and assign it to the employee.

    ```json
    {
        "taskId": 1001,
        "description": "Analyze network performance",
        "status": "IN_PROGRESS",
        "employeeId": 1
    }
    ```
3. Update the status of the task.
   
    ```json
    {
        "description": "Analyze network performance",
        "status": "COMPLETED",
        "employeeId": 1
    }
    ```
4. Delete the task by giving the task ID of the completed task that needs to be deleted.

### Concepts covered

- REST API
- Bal persist
- CRUD operations

## Develop the application

### Step 1: Set up the workspace

Install [Ballerina Swan Lake](https://ballerina.io/downloads/) and the [Ballerina Swan Lake extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) on VS Code.

### Step 2: Develop the service

Follow the instructions given in this section to develop the service.

1. Create a new Ballerina project using the `bal` command and open it in VS Code.

    ```bash
    $ bal new data-integration
    ```

2. Initialize `bal persist` in the project. Specify the module name as `store` and the datastore as `mysql`. This will create a persist directory in the project root directory. The directory will contain the `model.bal` file, which is used to define the data model.

    ```bash
    $ bal persist init --module store --datastore mysql
    ```

3. Open the `model.bal` file in the persist directory and define the data model as follows.

    ```ballerina
    import ballerina/persist as _;

    type Employee record {|
        readonly int id;
        string name;
        int age;
        string phone;
        string email;
        string department;
        Task[] tasks;
    |};

    type Task record {|
        readonly int taskId;
        string taskName;
        string description;
        TaskStatus status;
        Employee employee;
    |};

    public enum TaskStatus {
        NOT_STARTED,
        IN_PROGRESS,
        COMPLETED
    };
    ```

    **Note:** 
    > The entities defined in the `model.bal` file should be based on the [`persist model specification`](https://ballerina.io/learn/persist-model/).

4. Generate the client objects, types and and scripts for the model using the following command. This will parse the `persist/model.bal` file and add the generated files under the generated directory..
   
    ```bash
    $ bal persist generate --module store
    ```

5. Remove the generated content in the `main.bal` file and open the diagram view in VS Code.

    ![Open diagram view](./resources/open_diagram_view.gif)

6. Define the generated client object `store:Client`.
   
   ```ballerina
   import data_integration.store;

   final store:Client dbClient = check new;
   ```
   
7. Define the [HTTP service (REST API)](https://ballerina.io/learn/by-example/#rest-service) that has the resources that accepts user requests, interact with the database and manage operations to create, retrieve, update and delete employee and task data.
  
  - Open the [Ballerina HTTP API Designer](https://wso2.com/ballerina/vscode/docs/design-the-services/http-api-designer) in VS Code.

  - Define a service attached to the listener that is listening on port `9090`.

        ![Define the service](./resources/define_a_service.gif)

  - Define HTTP resources that allow CRUD operations on the employee data. The following GIF shows how to define the `post` resource that creates an employee. Similarly, define the `get`, `put` and `delete` resources.

        ![Define the resource](./resources/define_the_resource.gif)

8. Implement the logic.

```ballerina
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
}
```

   - The `post` resource accepts a `store:EmployeeInsert` object as the payload and returns a `http:Created` response if the employee is created successfully. If the employee already exists, it returns an `http:Conflict` response and if an error occurs, it returns an `http:InternalServerError` response.

   - Similarly, implement the logic for the other resources.

You have successfully developed the required service.

#### Complete source

```ballerina
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

    resource function get task/[int taskId]() returns store:Task|http:NotFound|http:InternalServerError {
        store:Task|persist:Error task = dbClient->/tasks/[taskId];
        if task is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if task is persist:Error {
            return <http:InternalServerError>{body: task.message()};
        }
        return task;
    }

    resource function get employeetasks/[int empId]() returns store:Task[]|http:NotFound|http:InternalServerError {
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

    resource function get employee/[int empId]() returns store:Employee|http:NotFound|http:InternalServerError {
        store:Employee|persist:Error employee = dbClient->/employees/[empId];
        if employee is persist:NotFoundError {
            return http:NOT_FOUND;
        }
        if employee is persist:Error {
            return <http:InternalServerError>{body: employee.message()};
        }
        return employee;
    }

    resource function put task/[int taskId](store:TaskUpdate task)
            returns store:Task|http:InternalServerError {
        store:Task|persist:Error updatedTask = dbClient->/tasks/[taskId].put(task);
        if updatedTask is persist:Error {
            return <http:InternalServerError>{body: updatedTask.message()};
        }
        return updatedTask;
    }

    resource function delete task/[int taskId]()
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
        store:Task|persist:Error deleteResult = dbClient->/tasks/[taskId].delete;
        if deleteResult is persist:Error {
            return <http:InternalServerError>{body: deleteResult.message()};
        }
        return http:NO_CONTENT;
    }
}
```

#### Entity Relationship Diagram

The [entity relationship diagram view](https://wso2.com/ballerina/vscode/docs/implement-the-code/sequence-diagram-view/) for the defined data model is the following.

<img src="./resources/entity_diagram.png" alt="Entity Diagram" height="800" style="width:auto; max-width:100%">

### Step 3: Start the docker service

Start the docker service using the following command.

```bash
$ docker-compose up
```

### Step 4: Build and run the service

![Run the service](./resources/run_the_service.gif)

> **Note:**
> Alternatively, you can run this service by navigating to the project root and using the `bal run` command.
>
> ```
> data-integration$ bal run
> Compiling source
>         integration_tutorials/data_integration:0.1.0
>
> Running executable
> ```

### Step 5: Try out the use case

Let's test the use case by sending a request to the service.

#### Send a request

Use the [Try it](https://wso2.com/ballerina/vscode/docs/try-the-services/try-http-services/) feature to send a request to the service. Use the following as the JSON payload to create an employee.

```json
{
    "id": 1,
    "name": "John Doe",
    "age": 22,
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "department": "IT"
}
```

![Send a request](./resources/try_it.gif)

#### Verify the response

You will receive an `http:Created` response if the employee is created successfully.

## References

- [`ballerina/http` API docs](https://lib.ballerina.io/ballerina/http/latest)
- [bal persist](https://ballerina.io/learn/bal-persist-overview/)
