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
    EmployeeTaskOptionalized[] employeeTask?;
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

public type EmployeeTask record {|
    readonly int taskId;
    string taskName;
    string description;
    TaskStatus status;
    int employeeId;
|};

public type EmployeeTaskOptionalized record {|
    int taskId?;
    string taskName?;
    string description?;
    TaskStatus status?;
    int employeeId?;
|};

public type EmployeeTaskWithRelations record {|
    *EmployeeTaskOptionalized;
    EmployeeOptionalized employee?;
|};

public type EmployeeTaskTargetType typedesc<EmployeeTaskWithRelations>;

public type EmployeeTaskInsert EmployeeTask;

public type EmployeeTaskUpdate record {|
    string taskName?;
    string description?;
    TaskStatus status?;
    int employeeId?;
|};

