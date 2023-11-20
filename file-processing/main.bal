import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

const string CSV_EXT = ".csv";

configurable string inPath = "./in";
configurable string mvOnSuccessPath = "./out";
configurable string mvOnFailurePath = "./failed";
configurable string host = ?;
configurable string user = ?;
configurable string password = ?;
configurable string database = ?;
configurable int port = ?;

type Person record {|
    string First\ Name;
    string Last\ Name;
    string Phone;
|};

function createDirIfNotExists(string dir) returns error? {
    if !(check file:test(dir, file:EXISTS)) {
        check file:createDir(dir);
    }
}

function move(string inFilePath, string outFolder) {
    do {
        string file = inFilePath.substring(inPath.length(), inFilePath.length());
        check file:copy(inFilePath, string `${outFolder}${file}`);
        check file:remove(inFilePath);
    } on fail file:Error err {
        log:printError("Error moving file", err, filename = inFilePath);
    }
}

listener file:Listener fileListener = createFileListener();

function createFileListener() returns file:Listener|error {
    check createDirIfNotExists(inPath);
    return new (({path: inPath}));
}

final mysql:Client db = 
    check new mysql:Client(host, user, password, database, port);

function init() returns error? {
    check createDirIfNotExists(mvOnSuccessPath);
    check createDirIfNotExists(mvOnFailurePath);

    _ = check db->execute(`CREATE TABLE IF NOT EXISTS Persons (
                                        firstName VARCHAR(50) NOT NULL,
                                        lastName VARCHAR(50) NOT NULL,
                                        phone VARCHAR(10) NOT NULL
                                    );`);
}

service on fileListener {
    remote function onCreate(file:FileEvent event) {
        string file = event.name;

        if !file.endsWith(CSV_EXT) {
            return;
        }

        do {
            Person[] persons = check io:fileReadCsv(file);
            sql:ParameterizedQuery[] insertQueries = from Person person in persons
                select `INSERT INTO Persons (firstName, lastName, phone)
                        VALUES (${person.First\ Name}, ${person.Last\ Name}, ${person.Phone})`;
            _ = check db->batchExecute(insertQueries);
            move(file, mvOnSuccessPath);
        } on fail io:Error|sql:Error err {
            if err is io:Error {
                log:printError("Error occured while reading file", err, filename = file);
            } else {
                log:printError("Error persisting data to database", err, filename = file);
            }
            move(file, mvOnFailurePath);
        }
    }
}
