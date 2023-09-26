import ballerina/http;
import ballerina/log;

configurable int port = 8290;
configurable string hospitalServicesBackend = "http://localhost:9090";
configurable string paymentBackend = "http://localhost:9090/healthcare/payments";

final http:Client hospitalServicesEP = check initializeHttpClient(hospitalServicesBackend);
final http:Client paymentEP = check initializeHttpClient(paymentBackend);

function initializeHttpClient(string url) returns http:Client|error => new (url);

type Patient record {|
    string name;
    string dob;
    string ssn;
    string address;
    string phone;
    string email;
|};

type ReservationRequest record {|
    record {|
        *Patient;
        string cardNo;
    |} patient;
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
    decimal fee;
|};

type Appointment record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    boolean confirmed;
    string hospital;
    string appointmentDate;
|};

type Fee record {|
    string patientName;
    string doctorName;
    string actualFee;
|};

type ReservationStatus record {|
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID;
    string status;
|};

service /healthcare on new http:Listener(port) {
    resource function post categories/[string category]/reserve(ReservationRequest payload) 
            returns ReservationStatus|http:NotFound|http:InternalServerError {
        ReservationRequest {
            patient: {cardNo, ...patient},
            doctor, 
            hospital,
            hospital_id,
            appointment_date
        } = payload;

        log:printDebug("Initiating reservation process", 
                       specialization = category, 
                       doctor = doctor,
                       patient = patient.name);

        Appointment|http:ClientError appointment =
                hospitalServicesEP->/[hospital_id]/categories/[category]/reserve.post({
            patient,
            doctor,
            hospital,
            appointment_date
        });

        if appointment !is Appointment {
            log:printError("Appointment reservation failed", appointment);
            if appointment is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown hospital, doctor, or category`};
            }
            return <http:InternalServerError> {body: appointment.message()};
        }

        int appointmentNumber = appointment.appointmentNumber;

        Fee|http:ClientError fee = 
                hospitalServicesEP->/[hospital_id]/categories/appointments/[appointmentNumber]/fee;

        if fee !is Fee {
            log:printError("Retrieving fee failed", fee);
            if fee is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown appointment ID`};
            }
            return <http:InternalServerError> {body: fee.message()};
        }

        decimal|error actualFee = decimal:fromString(fee.actualFee);
        if actualFee is error {
            return <http:InternalServerError> {body: "fee retrieval failed"};
        }

        ReservationStatus|http:ClientError status = paymentEP->/.post({
            appointmentNumber,
            doctor: appointment.doctor,
            patient,
            fee: actualFee,
            confirmed: false,
            card_number: cardNo
        });

        if status !is ReservationStatus {
            log:printError("Payment failed", status);
            if status is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown appointment ID`};
            }
            return <http:InternalServerError> {body: status.message()};
        }

        log:printDebug("Appointment reservation successful", 
                       name = patient.name, 
                       appointmentNumber = appointmentNumber);
        return status;
    }
}
