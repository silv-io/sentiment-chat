# Real-Time Sentiment Chat Service

This project implements a real-time sentiment chat service on AWS. Clients connect over WebSocket via API Gateway. Each incoming message is analyzed for sentiment by a Bedrock model. Session state and recent messages are stored in MemoryDB for Redis. Negative sentiment triggers alerts via SNS. Data is secured with KMS, and access is controlled by Verified Permissions.

## Architecture

- **Frontend:** A simple HTML/CSS/JavaScript single-page application hosted on S3.
- **API:** A WebSocket API managed by Amazon API Gateway.
- **Backend Logic:** Three AWS Lambda functions (Python) for handling WebSocket connections, disconnections, and messages.
- **Sentiment Analysis:** Amazon Bedrock is used for real-time sentiment analysis of chat messages.
- **Database:** Amazon MemoryDB for Redis stores session information and recent messages.
- **Alerting:** Amazon SNS is used to send notifications when negative sentiment is detected.
- **Security:**
    - AWS Key Management Service (KMS) for data encryption at rest.
    - Amazon Verified Permissions for fine-grained access control.
- **Infrastructure as Code:** AWS resources are managed by Terraform.

## Deployment

### Prerequisites

- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed and configured with AWS credentials.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured.
- [Python 3.9](https://www.python.org/downloads/) and `pip`.

### Steps

1.  **Initialize Terraform:**
    Open a terminal in the root of the project and run:
    ```bash
    terraform init
    ```

2.  **Install Lambda Dependencies & Deploy Infrastructure:**
    Navigate into each Lambda function's directory and install the Python dependencies into that same directory:
    ```bash
    cd lambda/connect
    pip install -r requirements.txt -t .
    cd ../../lambda/disconnect
    pip install -r requirements.txt -t .
    cd ../../lambda/sendmessage
    pip install -r requirements.txt -t .
    cd ../..
    ```
    Then, apply the Terraform configuration to create the AWS resources:
    ```bash
    terraform apply
    ```
    This command will package the lambda functions, and provision all the necessary resources. Review the plan and type `yes` to confirm. After the deployment is complete, Terraform will output the WebSocket API URL and the S3 bucket website endpoint.

3.  **Update Frontend Configuration:**
    - The `terraform apply` command will output a `websocket_uri`. It will look like `wss://<api_id>.execute-api.<region>.amazonaws.com/prod`.
    - Open `frontend/app.js` and replace the placeholder `YOUR_WEBSOCKET_URI` with the `websocket_uri` from the terraform output.

4.  **Upload Frontend to S3:**
    - The `terraform apply` command will also output an `s3_bucket_website_endpoint`.
    - Upload the contents of the `frontend` directory to the S3 bucket created by Terraform. You can find the bucket name in the output as well.
    ```bash
    aws s3 sync frontend/ s3://<your-s3-bucket-name>/
    ```
    Replace `<your-s3-bucket-name>` with the actual name of your S3 bucket.

5.  **Access the Application:**
    Open the `s3_bucket_website_endpoint` URL in your browser to use the chat application. You will be prompted to enter a user ID.

## Cleanup

To remove all the created resources, run:
```bash
terraform destroy
```
Type `yes` to confirm the destruction of all resources.
