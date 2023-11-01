import ballerina/http;
import ballerina/log;

configurable int port = 8290;

final http:Client grandOakEP = check initializeHttpClient("http://localhost:9090/grandoak/categories");
final http:Client clemencyEP = check initializeHttpClient("http://localhost:9090/clemency/categories");
final http:Client pineValleyEP = check initializeHttpClient("http://localhost:9090/pinevalley/categories");

function initializeHttpClient(string url) returns http:Client|error => new (url);

enum HospitalId {
    GRAND_OAK = "grandoak",
    CLEMENCY = "clemency",
    PINE_VALLEY = "pinevalley"
};

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type ReservationRequest record {|
    Patient patient;
    string doctor;
    HospitalId hospital_id;
    string hospital;
    string appointment_date;
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

service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(ReservationRequest payload)
            returns ReservationResponse|http:NotFound|http:InternalServerError {
        ReservationRequest {hospital_id, patient, doctor, ...reservationRequest} = payload;

        log:printDebug("Routing reservation request",
                        hospital_id = hospital_id,
                        patient = patient.name,
                        doctor = doctor);

        http:Client hospitalEP;
        match hospital_id {
            GRAND_OAK => {
                hospitalEP = grandOakEP;
            }
            CLEMENCY => {
                hospitalEP = clemencyEP;
            }
            _ => {
                hospitalEP = pineValleyEP;
            }
        }

        ReservationResponse|http:ClientError resp = hospitalEP->/[category]/reserve.post({
            patient,
            doctor,
            ...reservationRequest
        });

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = patient.name,
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
