import ballerina/http;
import ballerina/log;

final http:Client grandOakEP = check initializeHttpClient("http://localhost:9090/grandoak/categories");
final http:Client clemencyEP = check initializeHttpClient("http://localhost:9090/clemency/categories");
final http:Client pineValleyEP = check initializeHttpClient("http://localhost:9090/pinevalley/categories");

function initializeHttpClient(string url) returns http:Client|error => new (url);

enum HospitalId {
    grandoak,
    clemency,
    pinevalley
};

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type Doctor record {|
    string name;
    string hospital;
    string category;
    string availability;
    decimal fee;
|};

type ReservationResponse record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    string hospital;
    boolean confirmed;
    string appointmentDate;
|};

type ReservationRequest record {|
    Patient patient;
    string doctor;
    HospitalId hospital_id;
    string hospital;
    string appointment_date;
|};

service /healthcare on new http:Listener(8290) {
    resource function post categories/[string category]/reserve(ReservationRequest reservation)
            returns ReservationResponse|http:NotFound|http:InternalServerError {
        http:Client hospitalEP;
        match reservation.hospital_id {
            grandoak => {
                hospitalEP = grandOakEP;
            }
            clemency => {
                hospitalEP = clemencyEP;
            }
            _ => {
                hospitalEP = pineValleyEP;
            }
        }

        ReservationResponse|http:ClientError resp = hospitalEP->/[category]/reserve.post({
            patient: reservation.patient,
            doctor: reservation.doctor,
            hospital: reservation.hospital,
            appointment_date: reservation.appointment_date
        });

        if resp is ReservationResponse {
            return resp;
        }

        log:printError("Reservation request failed", resp);
        if resp is http:ClientRequestError {
            return <http:NotFound> {body: "Unknown hospital, doctor or category"};
        }

        return <http:InternalServerError> {body: resp.message()};
    }
}
