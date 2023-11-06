import ballerina/http;
import ballerina/random;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare/categories`);

@test:Config
function testSuccessfulRequest() returns error? {
    ReservationStatus status = check cl->/surgery/reserve.post({
        "patient": {
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": "johndoe@gmail.com",
            "cardNo": "7844481124110331"
        },
        "doctor": "thomas collins",
        "hospital_id": "grandoaks",
        "hospital": "grand oak community hospital",
        "appointment_date": "2023-10-02"
    });

    final Appointment & readonly app;
    lock {
        app = <Appointment & readonly> appointment;
    }
    test:assertEquals(status, <ReservationStatus> {
        "appointmentNo": app.appointmentNumber,
        "doctorName": app.doctor.name,
        "patient": app.patient.name,
        "actualFee": app.doctor.fee,
        "discount": 20,
        "discounted": 5600.0,
        "paymentID": "f130e2ed-a34e-4434-9b40-6a0a8054ee6b",
        "status": "settled"
    });
}

@test:Config
function testUnknownCategory() returns error? {
    ReservationStatus|http:ClientError status = cl->/rheumatology/reserve.post({
        "patient": {
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": "johndoe@gmail.com",
            "cardNo": "7844481124110331"
        },
        "doctor": "thomas collins",
        "hospital_id": "grandoaks",
        "hospital": "grand oak community hospital",
        "appointment_date": "2023-10-02"
    });

    if status !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof status).toString());
    }

    test:assertEquals(status.message(), "Not Found");
    var detail = status.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "unknown hospital, doctor, or category");
}

isolated Appointment? & readonly appointment = ();

public client class MockHttpClient {
    private final string url;

    isolated function init(string url) {
        self.url = url;
    }

    isolated resource function post [http:PathParamType... path](
            http:RequestMessage message, map<string|string[]>? headers = (), string?
            mediaType = (), http:TargetType targetType = http:Response, *http:QueryParams params) 
                returns http:Response|anydata|http:ClientError {
        if self.url == hospitalServicesBackend {
            return handleAppointment(path, message);
        }

        if self.url == paymentBackend {
            return handlePayment(message);
        }

        return <http:ClientRequestError>error("unexpected request",
                                            body = "unexpected request",
                                            headers = {},
                                            statusCode = http:STATUS_BAD_REQUEST);
    }

    isolated resource function get [http:PathParamType... path](map<string|string[]>? headers = (), http:TargetType targetType = http:Response,
            *http:QueryParams params) returns http:Response|anydata|http:ClientError {
        if self.url != hospitalServicesBackend || path.length() != 5 || path[4] != "fee" {
            return <http:ClientRequestError>error("unexpected request",
                                            body = "unexpected request",
                                            headers = {},
                                            statusCode = http:STATUS_BAD_REQUEST);
        }

        http:PathParamType hospitalId = path[0];
        http:PathParamType appNumber = path[4];

        final int appointmentNumber;
        final string patient;
        final string doctor;
        lock {
            Appointment app = checkpanic appointment.ensureType();
            appointmentNumber = app.appointmentNumber;
            patient = app.patient.name;
            doctor = app.doctor.name;
        }

        if hospitalId != "grandoaks" && appNumber != appointmentNumber.toString() {
            return <http:ClientRequestError>error("unknown appointment",
                                                    body = "unknown appointment",
                                                    headers = {},
                                                    statusCode = http:STATUS_NOT_FOUND);
        }

        return {
            "patientName": patient,
            "doctorName": doctor,
            "actualFee": "7000"
        };
    }
}

isolated function handleAppointment(http:PathParamType[] path, http:RequestMessage message) 
        returns Appointment|http:ClientRequestError {

    if path.length() != 4 || path[3] != "reserve" {
        return <http:ClientRequestError>error("unexpected request",
                                        body = "unexpected request",
                                        headers = {},
                                        statusCode = http:STATUS_BAD_REQUEST);
    }

    record {|
        Patient patient;
        string doctor;
        string hospital;
        string appointment_date;
    |} payload;

    do {
        payload = check (check message.ensureType(anydata)).cloneWithType();
    } on fail {
        return <http:ClientRequestError>error("invalid payload",
                                                body = "invalid payload",
                                                headers = {},
                                                statusCode = http:STATUS_BAD_REQUEST);
    }

    match path[2] {
        "surgery" => {
            lock {
                appointment = {
                    "appointmentNumber": checkpanic random:createIntInRange(1, 1500),
                    "doctor": {
                        "name": payload.doctor,
                        "hospital": "grand oak community hospital",
                        "category": "surgery",
                        "availability": "9.00 a.m - 11.00 a.m",
                        "fee": 7000
                    },
                    "patient": payload.patient.cloneReadOnly(),
                    "hospital": payload.hospital,
                    "confirmed": false,
                    "appointmentDate": payload.appointment_date
                };
                return <Appointment & readonly> appointment;
            }
        }
    }
    return <http:ClientRequestError>error("unknown specialization",
                                        body = string `unknown specialization: ${path[0]}`,
                                        headers = {},
                                        statusCode = http:STATUS_NOT_FOUND);    
}

isolated function handlePayment(http:RequestMessage message) 
        returns ReservationStatus|http:ClientRequestError {
    record {|
        int appointmentNumber;
        Doctor doctor;
        Patient patient;
        decimal fee;
        boolean confirmed;
        string card_number;
    |} payload;

    do {
        payload = check (check message.ensureType(anydata)).cloneWithType();
    } on fail {
        return <http:ClientRequestError>error("invalid payload",
                                                body = "invalid payload",
                                                headers = {},
                                                statusCode = http:STATUS_BAD_REQUEST);
    }

    final Appointment & readonly app;
    lock {
        app = checkpanic appointment.ensureType();
    }

    int appointmentNumber = payload.appointmentNumber;
    if app.appointmentNumber != appointmentNumber {
        return <http:ClientRequestError>error("unknown appointment number",
                                    body = string `unknown appointment number: ${appointmentNumber}`,
                                    headers = {},
                                    statusCode = http:STATUS_NOT_FOUND);  
    }

    return {
        "appointmentNo": appointmentNumber,
        "doctorName": app.doctor.name,
        "patient": app.patient.name,
        "actualFee": app.doctor.fee,
        "discount": 20,
        "discounted": 5600.0,
        "paymentID": "f130e2ed-a34e-4434-9b40-6a0a8054ee6b",
        "status": "settled"
    };  
}

@test:Mock {
    functionName: "initializeHttpClient"
}
function initializeHttpClientMock(string url) returns http:Client|error =>
    test:mock(http:Client, new MockHttpClient(url));
