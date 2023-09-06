import ballerina/http;
import ballerina/log;

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
    string hospital_id?;
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

final http:Client grandOaksBE = check initializeHttpClient("http://localhost:9090/grandoaks/categories");
final http:Client clemencyBE = check initializeHttpClient("http://localhost:9090/clemency/categories");
final http:Client pineValleyBE = check initializeHttpClient("http://localhost:9090/pinevalley/categories");

function initializeHttpClient(string url) returns http:Client|error => new (url);

service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(
            ReservationRequest reservationRequest
        ) returns ReservationResponse|http:NotFound|http:InternalServerError? {

        http:Client? hospitalBE = ();
        string hospital = reservationRequest.hospital;
        match hospital {
            "grand oak community hospital" => {
                log:printInfo("Routed to Grand Oak Community Hospital");
                hospitalBE = grandOaksBE;
            }
            "clemency medical center" => {
                log:printInfo("Routed to Clemency Medical Center");
                hospitalBE = clemencyBE;
            }
            "pine valley community hospital" => {
                log:printInfo("Routed to Pine Valley Community Hospital");
                hospitalBE = pineValleyBE;
            }
        }

        if hospitalBE is () {
            log:printError(string `Routed to none. Hospital not found: ${hospital}`);
            return <http:NotFound>{body: string `Hospital not found: ${hospital}`};
        }

        ReservationResponse|http:ClientError resp = hospitalBE->/[category]/reserve.post(reservationRequest);

        if resp is ReservationResponse {
            log:printDebug("Reservation request successful",
                            name = reservationRequest.patient.name,
                            appointmentNumber = resp.appointmentNumber);
            return resp;
        }

        if resp is http:ClientRequestError {
            log:printError("Reservation request failed.", resp);
            return <http:NotFound>{body: "Invalid doctor or hospital"};
        }

        log:printError("Reservation request failed", resp);
        return <http:InternalServerError>{body: resp.message()};
    }
}
