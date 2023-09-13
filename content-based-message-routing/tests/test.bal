import ballerina/http;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare`);

const GRAND_OAK_HOSPITAL = "grand oak community hospital";
const CLEMENCY_MEDICAL_CENTER = "clemency medical center";
const PINE_VALLEY_COMMUNITY_HOSPITAL = "pine valley community hospital";
const DEFAULT_DOCTOR = "thomas collins";

@test:Config
function testSuccessfulReservation() returns error? {
    ReservationResponse resp = check cl->/categories/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });
    ReservationResponse expectedResp = getSuccessAppointmentResponse(GRAND_OAK_HOSPITAL);
    test:assertEquals(resp, expectedResp, "Response mismatched");
}

@test:Config
function testInvalidHospital() {
    ReservationResponse|http:ClientError resp = cl->/categories/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas chandler",
        hospital: "monarch hospital",
        hospital_id: "monarch",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "Hospital not found: monarch");
}

@test:Config
function testInvalidDoctor() {
    ReservationResponse|http:ClientError resp = cl->/categories/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas chandler",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "Unknown hospital, doctor or category");
}

@test:Config
function testInvalidCategory() {
    ReservationResponse|http:ClientError resp = cl->/categories/chickenpox/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "Unknown hospital, doctor or category");
}

@test:Config
function testMissingPatientData() {
    ReservationResponse|http:ClientError resp = cl->/categories/chickenpox/reserve.post({
        patient: {
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Bad Request");
    test:assertEquals(resp.detail().statusCode, http:STATUS_BAD_REQUEST);
}

isolated function getSuccessAppointmentResponse(string hospital) returns ReservationResponse & readonly => {
    "appointmentNumber": 4,
    "doctor": {
        "name": "thomas collins",
        "hospital": hospital,
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
    "hospital": hospital,
    "fee": 7000,
    "confirmed": false,
    "appointmentDate": "2025-04-02"
};

isolated function getInvalidHospitalOrDoctorErrorResponse() returns http:ClientRequestError
    => <http:ClientRequestError>error("Not Found",
                                        body = "requested doctor is not available at the requested hospital",
                                        headers = {},
                                        statusCode = http:STATUS_NOT_FOUND);

public client class MockHttpClient {

    private final string url;

    isolated function init(string url) {
        self.url = url;
    }

    isolated resource function post [http:PathParamType... path](http:RequestMessage message,
            map<string|string[]>? headers = (),
            string? mediaType = (),
            http:TargetType targetType = http:Response,
            *http:QueryParams params) returns http:Response|anydata|http:ClientError {
        if path[0] != "surgery" {
            return <http:ClientRequestError>error("unknown specialization",
                                                body = string `unknown specialization: ${path[0]}`,
                                                headers = {},
                                                statusCode = http:STATUS_NOT_FOUND);
        }

        record {
            string doctor;
            string hospital;
        } payload;

        do {
            payload = check (check message.ensureType(anydata)).cloneWithType();
        } on fail {
            return <http:ClientRequestError>error("invalid payload",
                                                body = "invalid payload",
                                                headers = {},
                                                statusCode = http:STATUS_BAD_REQUEST);
        }

        if DEFAULT_DOCTOR != payload.doctor {
            return getInvalidHospitalOrDoctorErrorResponse();
        }

        match payload.hospital {
            GRAND_OAK_HOSPITAL => {
                return getSuccessAppointmentResponse(GRAND_OAK_HOSPITAL);
            }
            CLEMENCY_MEDICAL_CENTER => {
                return getSuccessAppointmentResponse(CLEMENCY_MEDICAL_CENTER);
            }
            PINE_VALLEY_COMMUNITY_HOSPITAL => {
                return getSuccessAppointmentResponse(PINE_VALLEY_COMMUNITY_HOSPITAL);
            }
        }

        return getInvalidHospitalOrDoctorErrorResponse();
    }
}

@test:Mock {
    functionName: "initializeHttpClient"
}
function initializeHttpClientMock(string hospitalId) returns http:Client|error =>
    test:mock(http:Client, new MockHttpClient(hospitalId));
