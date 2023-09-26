import file_processing.store;

import ballerina/file;
import ballerina/io;
import ballerina/log;
import ballerina/persist;

const string CSV_EXT = ".csv";

configurable string inPath = "./in";
configurable string mvOnSuccessPath = "./out";
configurable string mvOnFailurePath = "./failed";

type Person record {|
    string First\ Name;
    string Last\ Name;
    string Phone;
|};

function init() returns error? {
    check createDirIfNotExists(mvOnSuccessPath);
    check createDirIfNotExists(mvOnFailurePath);
}

function createFileListener() returns file:Listener|error {
    check createDirIfNotExists(inPath);
    return new (({path: inPath}));
}

final store:Client storeClient = check new;

listener file:Listener fileListener = createFileListener();

service on fileListener {
    remote function onCreate(file:FileEvent event) {
        string file = event.name;

        if !file.endsWith(CSV_EXT) {
            log:printInfo("Ignoring non-CSV file", filename = file);
            return;
        }

        do {
            Person[] csvPersons = check io:fileReadCsv(file);
            store:Person[] storePersons = from Person person in csvPersons
                                            select {
                                                firstName: person.First\ Name,
                                                lastName: person.Last\ Name,
                                                phone: person.Phone
                                            };
            _ = check storeClient->/people.post(storePersons);
            move(file, mvOnSuccessPath);
        } on fail io:Error|persist:Error err {
            if err is io:Error {
                log:printError("Error occured while reading file", err, filename = file);
            } else {
                log:printError("Error persisting data to database", err, filename = file);
            }
            move(file, mvOnFailurePath);
        }
    }
}

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
