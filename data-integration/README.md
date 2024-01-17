# Data integration

## Overview

In this tutorial, you will develop a service that accepts requests to create an employee and a task, update task status, and delete a completed task. Ballerina persistence layer is used to manage data stored in a database. The service will be used to create, retrieve, update, and delete data from the database.

To implement this use case, you will develop a REST service with multiple resources using Visual Studio Code with the Ballerina Swan Lake extension.

Define the data model using the `bal persist` feature and generate the client objects, types, and scripts for the model. Then, define the service and implement the logic to interact with the database.

The flow is as follows.

1. Send a `POST` request to the service to create an employee.

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

2. Send a `POST` request to the service to create a task for the employee.

    ```json
    {
        "taskId": 1001,
        "description": "Analyze network performance",
        "status": "IN_PROGRESS",
        "employeeId": 1
    }
    ```

3. Send a `PUT` request to the service to update the task status.
   
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
- The Ballerina persistence layer
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

2. Use `bal persist` in the project root to initialize the persistence layer for the project. Specify the module name as `store` and the datastore as `mysql`. This will create a directory named `persist` in the project root directory. The directory will contain the `model.bal` file, which is used to define the data model.

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

    - The above data model defines a one to many relationship, where each `Employee` can have multiple assigned `Task`s, and each `Task` is associated with only one `Employee`.   

    **Note:** 
    > The entities defined in the `model.bal` file should be based on the [`persist model specification`](https://ballerina.io/learn/persist-model/).

4. Generate the client objects, types, and scripts for the model using the following command. This will use the model defined in the `persist/model.bal` file to generate the persistence constructs in a module named `store` in a directory named `generated`.
   
    ```bash
    $ bal persist generate --module store
    ```

Now, we are going to implement the logic using the generated constructs.

5. Remove the generated content in the `main.bal` file in the project root and open the diagram view in VS Code.

    ![Open diagram view](./resources/open_diagram_view.gif)

6. Define a variable of the generated client object type (`store:Client`) to interact with the database.
   
   ```ballerina
   import data_integration.store;

   final store:Client dbClient = check new;
   ```
   
7. Define the [HTTP service (REST API)](https://ballerina.io/learn/by-example/#rest-service) that has the resources that accept user requests, interact with the database, and manage operations to create, retrieve, update, and delete employee and task data.
  
   - Open the [Ballerina HTTP API Designer](https://wso2.com/ballerina/vscode/docs/design-the-services/http-api-designer) in VS Code.

   - Define a service attached to the listener that is listening on port `9090`.

        ![Define the service](./resources/define_a_service.gif)

   - Define an HTTP resource that allows the `POST` operation to create an employee. Use `http:Created`, `http:Conflict`, and `http:InternalServerError` as the response types. Similarly, define the `GET`, `PUT`, and `DELETE` resources.

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
```

   - The `POST` resource accepts a `store:EmployeeInsert` record as the payload and returns an `http:Created` response if the employee is created successfully. If the employee already exists, it returns an `http:Conflict` response and if an error occurs, it returns an `http:InternalServerError` response.

```ballerina
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
}
```

   - The `GET` resource accepts an employee ID as a path parameter and retrieves tasks assigned to the employee using a database query where the `employeeId` is equal to the provided `empId`. If the employee does not exist, it returns an `http:NotFound` response and if an error occurs, it returns an `http:InternalServerError` response.

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
```

#### Entity Relationship Diagram

The [entity relationship diagram view](https://wso2.com/ballerina/vscode/docs/implement-the-code/sequence-diagram-view/) for the defined data model is the following.

![Entity relationship diagram](./resources/er_diagram.gif)

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

Send a GET request to retrieve the employee details.

![Send a request](./resources/try_it_get.gif)

#### Verify the response

You will receive an `http:Created` response if the employee is created successfully.

## References

- [`ballerina/http` API docs](https://lib.ballerina.io/ballerina/http/latest)
- [bal persist](https://ballerina.io/learn/bal-persist-overview/)
