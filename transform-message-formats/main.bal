import ballerina/http;
import ballerina/log;

configurable int port = 8290;
configurable string hospitalServicesUrl = "http://localhost:9090";

final http:Client hospitalServicesEP = check initializeHttpClient();

function initializeHttpClient() returns http:Client|error => new (hospitalServicesUrl);

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type RequestData record {|
    *Patient;
    string doctor;
    string hospital_id;
    string hospital;
    string card_no;
    string appointment_date;
|};

type ReservationRequest record {|
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
    isolated resource function post categories/[string category]/reserve(
            RequestData payload
        ) returns ReservationResponse|http:NotFound|http:BadRequest|http:InternalServerError {
        string hospitalId = payload.hospital_id;
        ReservationRequest req = transform(payload);
        ReservationResponse|http:ClientError resp =
                    hospitalServicesEP->/[hospitalId]/categories/[category]/reserve.post(req);

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = payload.name,
                            appointmentNumber = resp.appointmentNumber);
            return resp;
        }

        log:printError("Reservation request failed", resp);
        if resp is http:ClientRequestError {
            return <http:NotFound>{body: "Unknown hospital, doctor or category"};
        }

        return <http:InternalServerError>{body: resp.message()};
    }
}

isolated function transform(RequestData details) returns ReservationRequest => {
    patient: {
        name: details.name,
        dob: details.dob,
        ssn: details.ssn,
        address: details.address,
        phone: details.phone,
        email: details.email
    },
    doctor: details.doctor,
    hospital: details.hospital,
    appointment_date: details.appointment_date
};
