import ballerina/http;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare`);

const GRAND_OAKS_HOSPITAL = "grand oak community hospital";
const CLEMENCY_MEDICAL_CENTER = "clemency medical center";
const PINE_VALLEY_COMMUNITY_HOSPITAL = "pine valley community hospital";
const DEFAULT_DOCTOR = "thomas collins";

@test:Config
function testSuccessfullReservation() returns error? {
    ReservationResponse resp = check cl->/categories/surgery/reserve.post({
        name: "John Doe",
        dob: "1940-03-19",
        ssn: "234-23-525",
        address: "California",
        phone: "8770586755",
        email: "johndoe@gmail.com",
        doctor: "thomas collins",
        hospital_id: "grandoaks",
        hospital: "grand oak community hospital",
        card_no: "7844481124110331",
        appointment_date: "2025-04-02"
    });
    ReservationResponse expResp = getSuccessAppointmentResponse(GRAND_OAKS_HOSPITAL);
    test:assertEquals(resp, expResp, "Response mismatched");
}

@test:Config
function testInvalidDoctor() {
    ReservationResponse|http:ClientError resp = cl->/categories/surgery/reserve.post({
        name: "John Doe",
        dob: "1940-03-19",
        ssn: "234-23-525",
        address: "California",
        phone: "8770586755",
        email: "johndoe@gmail.com",
        doctor: "thomas chandler",
        hospital_id: "grandoaks",
        hospital: "grand oak community hospital",
        card_no: "7844481124110331",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "Reservation failed. Wrong hospital or doctor");
}

@test:Config
function testMissingPatientData() {
    ReservationResponse|http:ClientError resp = cl->/categories/surgery/reserve.post({
        dob: "1940-03-19",
        ssn: "234-23-525",
        address: "California",
        phone: "8770586755",
        email: "johndoe@gmail.com",
        doctor: "thomas collins",
        hospital_id: "grandoaks",
        hospital: "grand oak community hospital",
        card_no: "7844481124110331",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Bad Request");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_BAD_REQUEST);
}

@test:Config
function testWrongCategory() {
    ReservationResponse|http:ClientError resp = cl->/categories/chickenpox/reserve.post({
        name: "John Doe",
        dob: "1940-03-19",
        ssn: "234-23-525",
        address: "California",
        phone: "8770586755",
        email: "johndoe@gmail.com",
        doctor: "thomas chandler",
        hospital_id: "grandoaks",
        hospital: "grand oak community hospital",
        card_no: "7844481124110331",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
}

isolated function getSuccessAppointmentResponse(string hospital) returns ReservationResponse & readonly => {
    "appointmentNumber": 1,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "hospital": "grand oak community hospital",
    "fee": 7000,
    "confirmed": false,
    "appointmentDate": "2025-04-02"
};

isolated function getWrongHospitalOrDoctorResponse() returns http:ClientRequestError
    => <http:ClientRequestError>error("Not Found",
                                        body = "requested doctor is not available at the requested hospital",
                                        headers = {},
                                        statusCode = http:STATUS_NOT_FOUND);

public client class MockHttpClient {
    isolated resource function post [http:PathParamType... path](http:RequestMessage message,
            map<string|string[]>? headers = (),
            string? mediaType = (),
            http:TargetType targetType = http:Response,
            *http:QueryParams params) returns http:Response|anydata|http:ClientError {
        record {
            string doctor;
            string hospital;
        } payload;

        if path[2] != "surgery" {
            return <http:ClientRequestError>error("unknown specialization",
                                        body = string `unknown specialization: ${path[2]}`,
                                        headers = {},
                                        statusCode = http:STATUS_NOT_FOUND); 
        }

        do {
            payload = check (check message.ensureType(anydata)).cloneWithType();
        } on fail {
            return <http:ClientRequestError>error("invalid payload",
                                                body = "invalid payload",
                                                headers = {},
                                                statusCode =  http:STATUS_BAD_REQUEST);
        }

        if DEFAULT_DOCTOR != payload.doctor {
            return getWrongHospitalOrDoctorResponse();
        }

        match payload.hospital {
            GRAND_OAKS_HOSPITAL => {
                return getSuccessAppointmentResponse(GRAND_OAKS_HOSPITAL);
            }
            CLEMENCY_MEDICAL_CENTER => {
                return getSuccessAppointmentResponse(CLEMENCY_MEDICAL_CENTER);
            }
            PINE_VALLEY_COMMUNITY_HOSPITAL => {
                return getSuccessAppointmentResponse(PINE_VALLEY_COMMUNITY_HOSPITAL);
            }
            _ => {
                return getWrongHospitalOrDoctorResponse();
            }
        }
    }
}

@test:Mock {
    functionName: "initializeHttpClient"
}
function initializeHttpClientMock() returns http:Client|error =>
    test:mock(http:Client, new MockHttpClient());
