// AUTO-GENERATED FILE. DO NOT MODIFY.

// This file is an auto-generated file by Ballerina persistence layer for model.
// It should not be modified by hand.

public type Person record {|
    readonly string firstName;
    readonly string lastName;
    string phone;
|};

public type PersonOptionalized record {|
    string firstName?;
    string lastName?;
    string phone?;
|};

public type PersonTargetType typedesc<PersonOptionalized>;

public type PersonInsert Person;

public type PersonUpdate record {|
    string phone?;
|};

