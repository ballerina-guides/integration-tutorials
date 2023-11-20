import ballerina/file;
import ballerina/io;
import ballerina/lang.runtime;
import ballerina/sql;
import ballerina/test;
import ballerina/time;

type DatabasePerson record {|
    string firstName;
    string lastName;
    string phone;
|};

@test:Config
function testValidFileProcessing() returns error? {
    int successfulFileCount = (check file:readDir(mvOnSuccessPath)).length();
    int failedFileCount = (check file:readDir(mvOnFailurePath)).length();

    string filename = string `testfile_${time:monotonicNow()}.csv`;
    string[] content = [
        "First Name, Last Name, Phone",
        "Amy, Roy, 0112222222",
        "Joy, Williams, 0111111111"
    ];

    check io:fileWriteLines(
        string `${inPath}${file:pathSeparator}${filename}`,
        content
    );

    runtime:sleep(3);

    test:assertEquals((check file:readDir(mvOnSuccessPath)).length(), successfulFileCount + 1);
    test:assertEquals((check file:readDir(mvOnFailurePath)).length(), failedFileCount);

    test:assertTrue(
        check file:test(string `${mvOnSuccessPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertFalse(
        check file:test(string `${inPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertFalse(
        check file:test(string `${mvOnFailurePath}${file:pathSeparator}${filename}`, file:EXISTS));

    string[] readLines = check io:fileReadLines(string `${mvOnSuccessPath}${file:pathSeparator}${filename}`);
    test:assertEquals(readLines, content);

    stream<DatabasePerson, sql:Error?> personStream = db->query(`SELECT * FROM Persons;`);
    DatabasePerson[] personArr = check from DatabasePerson person in personStream select person;
    test:assertTrue(personArr.length() >= content.length() - 1);
    foreach int i in 1 ..< content.length() {
        test:assertTrue(personArr.some(p => p == getPerson(content[i])));
    }
}

function getPerson(string content) returns DatabasePerson {
    string[] split = re `,`.split(content);
    test:assertTrue(split.length() == 3);
    return {
        firstName: split[0].trim(),
        lastName: split[1].trim(),
        phone: split[2].trim()
    };
}

@test:Config {
    dependsOn: [testValidFileProcessing]
}
function testInvalidCSVFileProcessing() returns error? {
    int successfulFileCount = (check file:readDir(mvOnSuccessPath)).length();
    int failedFileCount = (check file:readDir(mvOnFailurePath)).length();

    string filename = string `testfile_${time:monotonicNow()}.csv`;
    string[] content = [
        "First Name, Phone",
        "Joy, 0111111111",
        "Amy, 0112222222"
    ];

    check io:fileWriteLines(
        string `${inPath}${file:pathSeparator}${filename}`,
        content
    );

    runtime:sleep(3);

    test:assertEquals((check file:readDir(mvOnSuccessPath)).length(), successfulFileCount);
    test:assertEquals((check file:readDir(mvOnFailurePath)).length(), failedFileCount + 1);

    test:assertFalse(
        check file:test(string `${mvOnSuccessPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertFalse(
        check file:test(string `${inPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertTrue(
        check file:test(string `${mvOnFailurePath}${file:pathSeparator}${filename}`, file:EXISTS));
}


@test:Config {
    dependsOn: [testInvalidCSVFileProcessing]
}
function testNonCSVFileProcessing() returns error? {
    int inDirFileCount = (check file:readDir(inPath)).length();
    int successfulFileCount = (check file:readDir(mvOnSuccessPath)).length();
    int failedFileCount = (check file:readDir(mvOnFailurePath)).length();

    string filename = string `testfile_${time:monotonicNow()}.txt`;
    string[] content = [
        "First Name, Last Name, Phone",
        "Amy, Roy, 0112222222",
        "Joy, Williams, 0111111111"
    ];

    check io:fileWriteLines(
        string `${inPath}${file:pathSeparator}${filename}`,
        content
    );

    runtime:sleep(3);

    test:assertEquals((check file:readDir(inPath)).length(), inDirFileCount + 1);
    test:assertEquals((check file:readDir(mvOnSuccessPath)).length(), successfulFileCount);
    test:assertEquals((check file:readDir(mvOnFailurePath)).length(), failedFileCount);

    test:assertTrue(
        check file:test(string `${inPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertFalse(
        check file:test(string `${mvOnSuccessPath}${file:pathSeparator}${filename}`, file:EXISTS));
    test:assertFalse(
        check file:test(string `${mvOnFailurePath}${file:pathSeparator}${filename}`, file:EXISTS));
}
