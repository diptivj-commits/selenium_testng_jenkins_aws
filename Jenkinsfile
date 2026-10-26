pipeline {
  agent { label 'aws-selenium' }
  options {
    disableConcurrentBuilds()
    timeout(time: 20, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '10'))
    skipDefaultCheckout(true)
  }
  parameters {
    booleanParam(name: 'UPLOAD_TO_S3', defaultValue: false, description: 'Upload reports using the EC2 instance role')
    string(name: 'S3_BUCKET', defaultValue: '', description: 'Existing private bucket name only')
    string(name: 'AWS_REGION', defaultValue: 'ap-south-1', description: 'Bucket region')
  }
  stages {
    stage('Checkout') {
      steps { deleteDir(); checkout scm }
    }
    stage('Check tools') {
      steps { sh 'java -version && mvn -version && google-chrome --version' }
    }
    stage('Test') {
      steps { sh 'mvn -B -ntp clean test -Dheadless=true' }
    }
  }
  post {
    always {
      junit testResults: 'reports/testng/TEST-*.xml', allowEmptyResults: true
      archiveArtifacts artifacts: 'reports/**/*', allowEmptyArchive: true
      script {
        if (params.UPLOAD_TO_S3 && fileExists('reports')) {
          if (!(params.S3_BUCKET ==~ /[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]/)) {
            error('S3_BUCKET must be a bucket name, without s3:// or a path')
          }
          withEnv(["REPORT_BUCKET=${params.S3_BUCKET}", "AWS_DEFAULT_REGION=${params.AWS_REGION}"]) {
            // An upload failure marks the build unsuccessful; a failed test stays failed.
            sh 'aws s3 cp reports/ "s3://$REPORT_BUCKET/selenium/$JOB_NAME/$BUILD_NUMBER/" --recursive --only-show-errors'
          }
        }
      }
    }
  }
}
