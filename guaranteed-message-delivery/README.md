# Guaranteed Message Delivery

## Overview

In this tutorial, you will develop a service via which you can reserve appointments at a hospital. The requests are forwarded to a message broker. The message will be consumed by another service and perform the appointment reservation by calling the hospital backend.

To implement this use case, you will develop a REST service with a single resource using Visual Studio Code with the Ballerina Swan Lake extension. This resource will receive the user request, reserve the appointment, push the message to the message broker. The consuming service will recieve the message, make the reservation and send an SMS to the patient phone number.

The flow is as follows.

1. Receive a request with a JSON payload in the following form.

    ```json
    {
        "patient": {
            "name": "John Doe",
            "dob": "1940-03-19",
            "ssn": "234-23-525",
            "address": "California",
            "phone": "8770586755",
            "email": "johndoe@gmail.com",
            "cardNo": "7844481124110331"
        },
        "doctor": "thomas collins",
        "hospital_id": "grandoaks",
        "hospital": "grand oak community hospital",
        "appointment_date": "2023-10-02"
    }
    ```

2. Publish the recieving payload in message broker

3. 

