import ballerina/http;
import ballerina/log;
import ballerina/email;
import ballerina/jballerina.java;
import ballerina/uuid;

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

type Appointment record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    boolean confirmed;
    string hospital;
    string appointmentDate;
|};

type PaymentSettlement record {|
    int appointmentNumber;
    Doctor doctor;
    Patient patient;
    decimal fee;
    boolean confirmed;
    string card_number;
|};

type Payment record {|
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID = uuid:createType4AsString();
    string status;
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

type ReservationResponse record {|
    int appointmentNo;
    string doctorName;
    string patient;
    decimal actualFee;
    int discount;
    decimal discounted;
    string paymentID;
    string status;
|};

configurable int port = 8290;
configurable string hospitalServicesBackend = "http://localhost:9090";
final http:Client hospitalServicesEP = check new(hospitalServicesBackend);

service /healthcare on new http:Listener(port) {

    function init() returns error? {
        check startSendWithOptionsSmtpServer();
    }
        
    resource function post categories/[string category]/reserve(@http:Payload ReservationRequest reservationRequest) 
        returns http:InternalServerError|http:NotFound|error? {

        email:SmtpConfiguration config = {
        port: 3025,
        security: email:START_TLS_NEVER
    };
        email:SmtpClient smtpClient = check new("127.0.0.1", "hascode", "Askl@7809", config);

        ReservationRequest {
            patient: {cardNo, ...patient},
            doctor, 
            hospital,
            hospital_id,
            appointment_date
        } = reservationRequest;


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

        PaymentSettlement paymentSettlement = {
            appointmentNumber: appointment.appointmentNumber,
            doctor: appointment.doctor,
            patient: appointment.patient,
            fee: appointment.doctor.fee,
            confirmed: appointment.confirmed,
            card_number: cardNo
        };

        Payment|http:ClientError payment =
                hospitalServicesEP->/healthcare/payments.post(paymentSettlement);

        if payment !is Payment {
            log:printError("Payment settlement failed", payment);
            if payment is http:ClientRequestError {
                return <http:NotFound> {body: string `unknown hospital, patient, or category`};
            }
            return <http:InternalServerError> {body: payment.message()};
        }

        ReservationResponse reservationResponse = {
            appointmentNo: appointment.appointmentNumber,
            doctorName: reservationRequest.doctor,
            patient: reservationRequest.patient.name,
            actualFee: payment.actualFee,
            discount: payment.discount,
            discounted: payment.discounted,
            paymentID: payment.paymentID,
            status: payment.status
        };

        email:Message email = {
            to: reservationRequest.patient.email,
            subject: "Payment Status",
            body: reservationResponse.toString()
        };

        check smtpClient->sendMessage(email);
        log:printInfo("Email sent successfully");
        return;
    }
}

public function startSendWithOptionsSmtpServer() returns error? = @java:Method {
    'class: "org.example.SmtpServer"
} external;
