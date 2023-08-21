import ballerina/http;
import ballerina/io;
import ballerina/log;

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};

configurable int port = 8290;
configurable string healthcareBackend = "http://localhost:9090/healthcare";

final http:Client queryDoctorEP = check initializeHttpClient();

function initializeHttpClient() returns http:Client|error => new (healthcareBackend);

service /healthcare on new http:Listener(port) {
    resource function get querydoctor/[string category]() 
            returns Doctor[]|http:NotFound|http:InternalServerError {
        log:printInfo("Retrieving information", specialization = category);
        
        Doctor[]|http:ClientError resp = queryDoctorEP->/[category];
        if resp is Doctor[] {
            return resp;
        }
        io:println(resp);
        if resp is http:ClientRequestError {
            return <http:NotFound> {body: string `category not found: ${category}`};
        }

        return <http:InternalServerError> {body: resp.message()};
    }
}
