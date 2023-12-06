import ballerina/http;
import ballerina/lang.runtime;
import ballerina/test;
import ballerinax/twilio;

const GRAND_OAK_COMMUNITY_HOSPITAL = "grand oak community hospital";
const CLEMENCY_MEDICAL_CENTER = "clemency medical center";
const PINE_VALLEY_COMMUNITY_HOSPITAL = "pine valley community hospital";
const THOMAS_COLLINS = "thomas collins";

const EXPECTED_SUCCESS_MESSAGE = "Dear John Doe, " +
                                 "your appointment has been accepted at grand oak community hospital. " +
                                 "Appointment No: 1";
const EXPECTED_FAIL_MESSAGE = "Dear John Doe, " +
                              "your appointment request at grand oak community hospital failed. " +
                              "Please try again.";

isolated string smsBody = "";

final http:Client cl = check new ("http://localhost:8290/healthcare/categories");

@test:Config
isolated function testSuccessfulReservation() returns error? {
    http:Response response = check cl->/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "+1234567890",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoak",
        appointment_date: "2025-04-02"
    });
    test:assertEquals(response.statusCode, http:STATUS_CREATED);
    runtime:sleep(5);
    lock {
        test:assertEquals(smsBody, EXPECTED_SUCCESS_MESSAGE);
    }
}

@test:Config
isolated function testUnknownCategory() returns error? {
    http:Response response = check cl->/rheumatology/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "+1234567890",
            email: "johndoe@gmail.com"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoak",
        appointment_date: "2025-04-02"
    });
    test:assertEquals(response.statusCode, http:STATUS_CREATED);
    runtime:sleep(5);
    lock {
        test:assertEquals(smsBody, EXPECTED_FAIL_MESSAGE);
    }
}

public client class MockHttpClient {

    isolated resource function post [http:PathParamType... path](http:RequestMessage message,
            map<string|string[]>? headers = (),
            string? mediaType = (),
            http:TargetType targetType = http:Response,
            *http:QueryParams params) returns http:Response|anydata|http:ClientError {
        if path[2] != "surgery" {
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

        if THOMAS_COLLINS != payload.doctor {
            return getInvalidHospitalOrDoctorErrorResponse();
        }

        if payload.hospital is GRAND_OAK_COMMUNITY_HOSPITAL|CLEMENCY_MEDICAL_CENTER|PINE_VALLEY_COMMUNITY_HOSPITAL {
            return getSuccessAppointmentResponse(payload.hospital);
        }

        return getInvalidHospitalOrDoctorErrorResponse();
    }
}

public client class MockTwilioClient {
    isolated remote function sendSms(
            string fromNo,
            string toNo,
            string message,
            string? statusCallbackUrl) returns twilio:SmsResponse|error {

        lock {
            smsBody = message;
        }

        return <twilio:SmsResponse>{};
    }
}

isolated function getSuccessAppointmentResponse(string hospital) returns ReservationResponse & readonly => {
    appointmentNumber: 1,
    doctor: {
        name: "thomas collins",
        hospital,
        category: "surgery",
        availability: "9.00 a.m - 11.00 a.m",
        fee: 7000
    },
    patient: {
        name: "John Doe",
        dob: "1940-03-19",
        ssn: "234-23-525",
        address: "California",
        phone: "8770586755",
        email: "johndoe@gmail.com"
    },
    hospital,
    confirmed: false,
    appointmentDate: "2025-04-02"
};

isolated function getInvalidHospitalOrDoctorErrorResponse() returns http:ClientRequestError
    => error("Not Found", body = "requested doctor is not available at the requested hospital",
                          headers = {},
                          statusCode = http:STATUS_NOT_FOUND);

@test:Mock {
    functionName: "initializeHttpClient"
}
function initializeHttpClientMock() returns http:Client|error =>
    test:mock(http:Client, new MockHttpClient());

@test:Mock {
    functionName: "initializeTwilioClient"
}
function initializeTwilioClientMock() returns twilio:Client|error =>
    test:mock(twilio:Client, new MockTwilioClient());
