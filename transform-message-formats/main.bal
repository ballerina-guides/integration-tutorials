import ballerina/log;
import ballerina/http;

type Details record {|
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
    string card_no;
|};

type ReservationRequest record {|
    Patient patient;
    string doctor;
    string hospital_id;
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

configurable int port = 8290;
configurable string hospitalBackendUrl = "http://localhost:9090";

final http:Client hospitalBE = check initializeHttpClient();

service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(
            @http:Payload Details details
        ) returns ReservationResponse|http:NotFound|http:BadRequest {
        string hospitalId = details.hospital_id;
        ReservationRequest req = transform(details);
        ReservationResponse|http:ClientError resp = hospitalBE->/[hospitalId]/categories/[category]/reserve.post(req);

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = details.name,
                            appointmentNumber = resp.appointmentNumber);
            return resp;
        }

        log:printError("Reservation failed. Wrong hospital or doctor", resp);
        return <http:NotFound>{body: "Reservation failed. Wrong hospital or doctor"};
    }
}

function initializeHttpClient() returns http:Client|error => new (hospitalBackendUrl);

function transform(Details details) returns ReservationRequest => {
    patient: {
        name: details.name,
        dob: details.dob,
        ssn: details.ssn,
        address: details.address,
        phone: details.phone,
        email: details.email,
        card_no: details.card_no
    },
    doctor: details.doctor,
    hospital_id: details.hospital_id,
    hospital: details.hospital,
    appointment_date: details.appointment_date
};
