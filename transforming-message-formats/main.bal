import ballerina/http;
import ballerina/log;

configurable int port = 8290;
configurable string hospitalServiceUrl = "http://localhost:9090";

final http:Client hospitalServiceEP = check initializeHttpClient();

function initializeHttpClient() returns http:Client|error => new (hospitalServiceUrl);

type HealthcareReservation record {
    string firstName;
    string lastName;
    string dob;
    int[3] ssn;
    string address;
    string phone;
    string email;
    string doctor;
    string hospitalId;
    string hospital;
    string cardNo;
    string appointmentDate;
};

type Patient record {
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
};

type HospitalReservation record {
    Patient patient;
    string doctor;
    string hospital;
    string appointment_date;
};

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
            returns ReservationResponse|http:NotFound|http:InternalServerError {
        HospitalReservation hospitalReservation = transform(payload);

        ReservationResponse|http:ClientError resp =
                    hospitalServiceEP->/[payload.hospitalId]/categories/[category]/reserve.post(hospitalReservation);

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = hospitalReservation.patient.name,
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

isolated function transform(HealthcareReservation reservation) returns HospitalReservation => 
    let var ssn = reservation.ssn in {
        patient: {
            name: reservation.firstName + " " + reservation.lastName,
            dob: reservation.dob,
            ssn: string `${ssn[0]}-${ssn[1]}-${ssn[2]}`,
            address: reservation.address,
            phone: reservation.phone,
            email: reservation.email
        },
        doctor: reservation.doctor,
        hospital: reservation.hospital,
        appointment_date: reservation.appointmentDate
    };
