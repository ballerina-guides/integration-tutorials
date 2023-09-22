import ballerina/http;
import ballerina/log;

configurable int port = 8290;
configurable string hospitalServiceUrl = "http://localhost:9090";

final http:Client hospitalServiceEP = check initializeHttpClient();

function initializeHttpClient() returns http:Client|error => new (hospitalServiceUrl);

type HealthcareReservation record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
    string doctor;
    string hospital_id;
    string hospital;
    string card_no;
    string appointment_date;
|};

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type HospitalReservation record {|
    Patient patient;
    string doctor;
    string hospital;
    string appointment_date;
|};

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    float fee;
|};

type ReservationResponse record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    float fee;
    string hospital;
    boolean confirmed;
    string appointmentDate;
|};

service /healthcare on new http:Listener(port) {
    isolated resource function post categories/[string category]/reserve(HealthcareReservation payload)
            returns ReservationResponse|http:NotFound|http:BadRequest|http:InternalServerError {
        HospitalReservation reservationReq = transform(payload);

        ReservationResponse|http:ClientError resp =
                    hospitalServiceEP->/[payload.hospital_id]/categories/[category]/reserve.post(reservationReq);

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = payload.name,
                            appointmentNumber = resp.appointmentNumber);
            return resp;
        }

        log:printError("Reservation request failed", resp);
        if resp is http:ClientRequestError {
            return <http:NotFound> {body: "Unknown hospital, doctor or category"};
        }

        return <http:InternalServerError> {body: resp.message()};
    }
}

isolated function transform(HealthcareReservation healthcareReservation) returns HospitalReservation => {
    patient: {
        name: healthcareReservation.name,
        dob: healthcareReservation.dob,
        ssn: healthcareReservation.ssn,
        address: healthcareReservation.address,
        phone: healthcareReservation.phone,
        email: healthcareReservation.email
    },
    doctor: healthcareReservation.doctor,
    hospital: healthcareReservation.hospital,
    appointment_date: healthcareReservation.appointment_date
};
