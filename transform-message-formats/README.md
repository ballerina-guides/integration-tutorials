# Transform message formats

## What you'll build

Let's develop a service that accepts requests to make an appointment at a hospital, takes the reuqest in one format, tranform that into another format and forwward to a backend hospital service. This integrates a backend service and successfully transform a meesage into another format.

To implement this use case, you will develop a REST service with single resource using Visual Studio Code with Ballerina Swan Lake extension. The resource will recieve the user request, transform it into acceptable format, sends to the hospital backend service and retrive the response with the correct reservation details.

The flow is as follows

1. Receive a request with a JSON payload in the following form.
```json
{
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "doctor": "thomas collins",
    "hospital_id": "grandoaks",
    "hospital": "grand oak community hospital",
    "card_no": "7844481124110331",
    "appointment_date": "2017-04-02"
}
```
2. Transform the data into the following form.
```json
{
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com",
        "card_no": "1111111"
    },
    "doctor": "thomas collins",
    "hospital": "grand oak community hospital",
    "appointment_date": "2025-04-02"
}
```
3. Extract the `hospital_id` and send the POST reuqest to the correct URL to make the reservation.

4. Retrive the response from the hospital backend in the following form
```json
{
    "appointmentNumber": 8,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "fee": 7000.0,
    "hospital": "grand oak community hospital",
    "confirmed": false,
    "appointmentDate": "2017-04-02"
}
```

### Concepts covered

- REST API
- HTTP client
- Data Mapper

## Let's get started!

### Step 1: Set up the workspace

Install [Ballerina Swan Lake](https://ballerina.io/downloads/) and the [Ballerina Swan Lake VSCode extension](https://marketplace.visualstudio.com/items?itemName=wso2.ballerina) on VSCode.

### Step 2: Develop the service

// TODO: Write the development process

### Step 3: Build and run the service

```bash
transform-message-formats$ bal run
Compiling source
        integration_tutorials/transform-message-formats:0.1.0

Running executable
```

### Step 4: Try out the use case

Let's test the use case by sending a request to the service.

#### Start the backend service

Download the JAR file for the backend service from [here](https://github.com/ballerina-guides/integration-tutorials/blob/main/backends/hospital-service/) and execute the following command to start the service:

```bash
bal run hospitalservice.jar
```

#### Send a request

Let's send a request to the service using cURL as follows.

1. Install and set up [cURL](https://curl.se/) as your client.

2. Create a file named `request.json` with the request payload.

```json
{
    "name": "John Doe",
    "dob": "1940-03-19",
    "ssn": "234-23-525",
    "address": "California",
    "phone": "8770586755",
    "email": "johndoe@gmail.com",
    "doctor": "thomas collins",
    "hospital_id": "grandoaks",
    "hospital": "grand oak community hospital",
    "card_no": "7844481124110331",
    "appointment_date": "2017-04-02"
}
```

3. Execute the following command.

```bash
curl -v -X POST --data @request.json http://localhost:8290/healthcare/categories/surgery/reserve --header "Content-Type:application/json"
```

#### Verify the response

You will see a response similar to the following for a successful appointment reservation.

```json
{
    "appointmentNumber": 8,
    "doctor": {
        "name": "thomas collins",
        "hospital": "grand oak community hospital",
        "category": "surgery",
        "availability": "9.00 a.m - 11.00 a.m",
        "fee": 7000.0
    },
    "patient": {
        "name": "John Doe",
        "dob": "1940-03-19",
        "ssn": "234-23-525",
        "address": "California",
        "phone": "8770586755",
        "email": "johndoe@gmail.com"
    },
    "fee": 7000.0,
    "hospital": "grand oak community hospital",
    "confirmed": false,
    "appointmentDate": "2017-04-02"
}
```

## References

- [`ballerina/http` API docs](https://lib.ballerina.io/ballerina/http/latest)
- [`ballerina/log` API docs](https://lib.ballerina.io/ballerina/log/latest)
