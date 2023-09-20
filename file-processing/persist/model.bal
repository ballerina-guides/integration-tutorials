import ballerina/persist as _;

public type Person record {|
    readonly string firstName;
    readonly string lastName;
    string phone;
|};
