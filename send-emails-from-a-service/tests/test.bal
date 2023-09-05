import ballerina/http;
import ballerina/test;

final http:Client cl = check new (string `http://localhost:${port}/healthcare/categories`);

@test:Config
function testSuccessfulRequest() returns error? {
    ReservationResponse res = check cl->/surgery/reserve.post({
        "patient": {
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": ""
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
    test:assertEquals(res, <ReservationResponse> {
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

isolated Appointment? & readonly appointment = ();
