// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

public enum TaskStatus {
    NOT_STARTED,
    IN_PROGRESS,
    COMPLETED
}

public type Employee record {|
    readonly int id;
    string name;
    int age;
    string phone;
    string email;
    string department;
|};

public type EmployeeOptionalized record {|
    int id?;
    string name?;
    int age?;
    string phone?;
    string email?;
    string department?;
|};

public type EmployeeWithRelations record {|
    *EmployeeOptionalized;
    TaskOptionalized[] tasks?;
|};

public type EmployeeTargetType typedesc<EmployeeWithRelations>;

public type EmployeeInsert Employee;

public type EmployeeUpdate record {|
    string name?;
    int age?;
    string phone?;
    string email?;
    string department?;
|};

public type Task record {|
    readonly int taskId;
    string taskName;
    string description;
    TaskStatus status;
    int employeeId;
|};

public type TaskOptionalized record {|
    int taskId?;
    string taskName?;
    string description?;
    TaskStatus status?;
    int employeeId?;
|};

public type TaskWithRelations record {|
    *TaskOptionalized;
    EmployeeOptionalized employee?;
|};

public type TaskTargetType typedesc<TaskWithRelations>;

public type TaskInsert Task;

public type TaskUpdate record {|
    string taskName?;
    string description?;
    TaskStatus status?;
    int employeeId?;
|};

