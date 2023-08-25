import ballerina/http;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare/querydoctor`);

isolated function getSurgeryResponsePayload() returns map<json>[] & readonly => [
    {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0d
    },
    {
        "name": "anne clement",
        "hospital": "clemency medical center",
        "category": "surgery",
        "availability": "8.00 a.m - 10.00 a.m",
        "fee": 12000.0d
    },
    {
        "name": "seth mears",
        "hospital": "pine valley community hospital",
        "category": "surgery",
        "availability": "3.00 p.m - 5.00 p.m",
        "fee": 8000.0d
    }
];

public client class MockHttpClient {
    isolated resource function get [string... path](map<string|string[]>? headers = (), http:TargetType targetType = http:Response,
            *http:QueryParams params) returns http:Response|anydata|http:ClientError {
        match path[0] {
            "surgery" => {
                return getSurgeryResponsePayload();
            }
        }
        return <http:ClientRequestError> error ("unknown specialization", 
                                            body = string `unknown specialization: ${path[0]}`, 
                                            headers = {}, 
                                            statusCode = http:STATUS_NOT_FOUND);
    }
}

@test:Mock {
    functionName: "initializeHttpClient"
}
function initializeHttpClientMock() returns http:Client|error =>
    test:mock(http:Client, new MockHttpClient());

@test:Config
function testSuccessfulRequest() returns error? {
    Doctor[] doctors = check cl->/surgery;
    test:assertEquals(doctors, getSurgeryResponsePayload());
}

@test:Config
function testUnknownCaregory() returns error? {
    Doctor[]|http:ClientError doctors = cl->/rheumatology;
    
    if doctors !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof doctors).toString());
    }

    test:assertEquals(doctors.message(), "Not Found");
    var detail = doctors.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "category not found: rheumatology");
}
