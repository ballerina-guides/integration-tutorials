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

final http:Client grandOaksEP = check initializeHttpClient("http://localhost:9090/grandoaks/categories");
final http:Client clemencyEP = check initializeHttpClient("http://localhost:9090/clemency/categories");
final http:Client pineValleyEP = check initializeHttpClient("http://localhost:9090/pinevalley/categories");

function initializeHttpClient(string url) returns http:Client|error => new (url);

service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(
            @http:Payload ReservationRequest reservationRequest
        ) returns ReservationResponse|http:NotFound|http:InternalServerError? {

        http:Client hospitalEP = grandOaksEP; // default

        string hospital = reservationRequest.hospital;
        match hospital {
            "grand oak community hospital" => {
                log:printInfo("Routed to grand oak community hospital");
            }
            "clemency medical center" => {
                log:printInfo("Routed to clemency medical center");
                hospitalEP = clemencyEP;
            }
            "pine valley community hospital" => {
                log:printInfo("Routed to pine valley community hospital");
                hospitalEP = pineValleyEP;
            }
            _ => {
                log:printError(string `Routed to none. Hospital not found: ${hospital}`);
                return <http:NotFound>{body: string `Hospital not found: ${hospital}`};
            }
        }

        ReservationResponse|http:ClientError resp = hospitalEP->/[category]/reserve.post(reservationRequest);

        if resp is ReservationResponse {
            log:printInfo("Reservation request confirmed");
            return resp;
        }

        if resp is http:ClientRequestError {
            log:printError("Reservation request failed", resp);
            return <http:NotFound>{body: "Invalid doctor or hospital"};
        }

        log:printError("Reservation request failed", resp);
        return <http:InternalServerError>{body: resp.message()};
    }
}
