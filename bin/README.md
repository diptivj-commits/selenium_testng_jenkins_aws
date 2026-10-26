# Selenium + TestNG + Jenkins on AWS

Java Maven project with Page Object Model, a self-contained login practice website, failure screenshots, TestNG XML/HTML reports, Jenkins pipeline and optional private S3 report upload. No public demo website dependency. The fixture uses a random localhost port; no inbound test-site port is required.

## Tests
- Valid login displays success and logout button.
- Invalid login displays error and hides logout.
- Logout returns to the signed-out state.
- Three browser-free configuration/HTTP checks.

## Local Windows run
Install JDK 21, Maven and Google Chrome. Extract the folder and import in Eclipse using File > Import > Existing Maven Projects.

```bat
cd /d "C:\Users\dipti\eclipse-workspace\SeleniumTestNGJenkinsAWS"
mvn -version
mvn clean test
```
Run visibly: `mvn test -Dheadless=false`. Selenium Manager resolves ChromeDriver automatically; internet access is required on first use. Do not set webdriver.chrome.driver to chrome.exe. Config: src/test/resources/config.properties; Java -D overrides environment variables and file values. Reports: reports/testng/index.html and reports/testng/TEST-*.xml; failure screenshots: reports/screenshots.

## AWS EC2 setup (learning environment)
1. Launch Ubuntu Server 24.04 LTS **x86_64**, for example a t3.medium with 20 GB disk. EC2, storage and S3 may incur charges; stop/terminate unused resources.
2. Security group: SSH 22 and Jenkins 8080 from **your public IP /32 only**. No inbound ChromeDriver/test fixture ports. Outbound internet is needed for apt, GitHub, Maven and browser driver downloads. Use a public subnet/public IP with internet gateway, or an appropriate private network/NAT setup.
3. Connect using the EC2 console's SSH instructions. Copy this project to EC2 or clone your GitHub repository. Run:

```bash
cd SeleniumTestNGJenkinsAWS
bash aws/install-ubuntu.sh
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

4. Open `http://EC2_PUBLIC_IP:8080`, unlock Jenkins, install suggested plugins, create an administrator. Ensure Pipeline (including Declarative), Git and JUnit plugins are installed. Do not put secrets into this repository.
5. For this single-machine learning setup, Manage Jenkins > Nodes > Built-In Node > Configure: label **aws-selenium**, one executor. The Jenkinsfile uses system Java/Maven from the install script, so named Jenkins tool installations are not needed. Jenkins runs as its non-root `jenkins` user with Chrome sandbox enabled. Production: use a separate EC2 agent with the same label/tools, leave controller executors at zero, and use HTTPS/private access.
6. New Item > Pipeline > Pipeline script from SCM > Git. Enter the actual repository URL, credentials for a private repository, branch `*/main`, script path `Jenkinsfile`.
7. Build Now. Jenkins checks tools, executes tests and publishes Test Result and build artifacts. Subsequent builds offer Build with Parameters. Keep UPLOAD_TO_S3 false until optional S3 setup is complete.

## Optional S3 reports using an instance role
1. Create a private S3 bucket in your chosen region with Block Public Access enabled. Default S3 encryption is sufficient for this example; customer-managed KMS keys require additional KMS permissions.
2. IAM > Roles > Create role > AWS service > EC2. Trust policy example: aws/ec2-trust-policy.json.
3. Replace REPLACE_WITH_BUCKET_NAME in aws/s3-report-policy.json and attach it as an inline policy to that role. This grants writes only under selenium/. It does not grant read, delete or bucket administration.
4. EC2 > instance > Actions > Security > Modify IAM role: attach the role to the **machine executing the Jenkins build**. No access keys or `aws configure` are needed.
5. Build with Parameters: UPLOAD_TO_S3=true, S3_BUCKET=actual-bucket-name, AWS_REGION=bucket-region.
6. Reports upload to `s3://BUCKET/selenium/JOB_NAME/BUILD_NUMBER/`, including reports after test failures. Upload failures fail the build. View/download via your own authorized AWS console identity; the instance role intentionally has no read permission. Configure a bucket lifecycle expiration for old reports if desired.

## Execution sequence
Checkout -> verify Java/Maven/Chrome -> Maven -> TestNG @BeforeSuite starts the practice HTTP server -> @BeforeMethod opens Chrome -> test -> @AfterMethod captures failure and closes Chrome -> @AfterSuite stops server -> Jenkins publishes JUnit-compatible XML and artifacts -> optional S3 upload.

## Troubleshooting
- Maven not recognized locally: add the actual Maven bin directory to PATH, reopen CMD, verify mvn -version.
- Jenkins pending: node must be online with label aws-selenium and an executor.
- Chrome fails: verify google-chrome --version as the Jenkins user; inspect build log. Do not run Jenkins as root or disable browser sandbox by default.
- Driver download fails: allow Selenium Manager/browser-driver download hosts through outbound proxy/firewall; Jenkins has its own HOME/cache and environment.
- S3 AccessDenied: check role attached to build agent, exact bucket/prefix, bucket policy and any KMS key requirements.
- Jenkins unavailable: inspect sudo systemctl status jenkins, EC2 security group and current public IP.

## References
https://www.jenkins.io/doc/book/installing/linux/
https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-role.html
https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AmazonS3.html

## Verification
See VERIFICATION.txt. AWS resources are not provisioned automatically. Installation script and pipeline must be run in your AWS account; no account credentials are included.
