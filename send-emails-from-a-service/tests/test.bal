import ballerina/email;
import ballerina/http;
import ballerina/random;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare/categories`);

@test:Config
isolated function testSuccessfulReservation() returns error? {
    http:Response _ = check cl->/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "johndoe@gmail.com",
            cardNo: "7844481124110331"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });

    final Appointment & readonly app;
    lock {
        app = <Appointment & readonly> appointment;
    }

    string expectedResp = string `Appointment Confirmation

    Appointment Details
        Appointment Number : ${app.appointmentNumber}
        Appointment Date: ${app.appointmentDate}

    Patient Details
        Name : ${app.patient.name}
        Contact Number : ${app.patient.phone}

    Doctor Details
        Name : ${app.doctor.name}
        Specialization : ${app.doctor.category}

    Payment Details
        Doctor Fee : ${app.doctor.fee}
        Discount : ${20}
        Total Fee : ${5600.0}
        Payment Status : ${"settled"}`;

    lock {
        test:assertEquals(emailContent, expectedResp, "Response mismatched");
    }
}

@test:Config
function testUnknownCategory() returns error? {
    ReservationResponse|http:ClientError resp = cl->/rheumatology/reserve.post({
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

    if resp !is http:ClientRequestError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Not Found");
    var detail = resp.detail();
    test:assertEquals(detail.statusCode, http:STATUS_NOT_FOUND);
    test:assertEquals(detail.body, "unknown hospital, doctor, or category");
}

@test:Config
function testEmptyEmailAddress() returns error? {
    ReservationResponse|http:ClientError resp = cl->/surgery/reserve.post({
        patient: {
            name: "John Doe",
            dob: "1940-03-19",
            ssn: "234-23-525",
            address: "California",
            phone: "8770586755",
            email: "",
            cardNo: "7844481124110331"
        },
        doctor: "thomas collins",
        hospital: "grand oak community hospital",
        hospital_id: "grandoaks",
        appointment_date: "2025-04-02"
    });

    if resp !is http:RemoteServerError {
        test:assertFail("expected an http:ClientRequestError, found " + (typeof resp).toString());
    }

    test:assertEquals(resp.message(), "Internal Server Error");
}

isolated Appointment? & readonly appointment = ();

public client class MockHttpClient {
    private final string url;

    isolated function init(string url) {
        self.url = url;
    }

    isolated resource function post [http:PathParamType... path](http:RequestMessage message, 
            map<string|string[]>? headers = (), 
            string? mediaType = (), 
            http:TargetType targetType = <>, *http:QueryParams params) 
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

}

isolated string? emailContent = "";

public isolated client class MockEmailClient {
    remote isolated function sendMessage(email:Message message) returns email:Error? {
        lock {
            emailContent = message.body;
        }
        if message.to == "" {
            return error("invalid email address");
        }
        return ();
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
                        "fee": 7000.0
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
        returns Payment|http:ClientRequestError {

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

    return {
        "appointmentNo": payload.appointmentNumber,
        "doctorName": payload.doctor.name,
        "patient": payload.patient.name,
        "actualFee": payload.fee,
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

@test:Mock {
    functionName: "initializeEmailClient"
}
function initializeEmailClientMock() returns email:SmtpClient|error =>
    test:mock(email:SmtpClient, new MockEmailClient());
