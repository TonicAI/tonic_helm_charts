@Library('jenkins-shared-library@master')
import com.fool.jenkins.pipeline.deploy.*

properties(foolDeployTargetProps.props())

def deploy = new FoolDeploy()

node(label: 'linux') {
  deploy.wrap {
    stage('Deploy') {
      deploy.withCredentials() {
        withCredentials(
          [string(credentialsId: 'TONIC_LICENSE', variable: 'TONIC_LICENSE'),
           string(credentialsId: 'TONIC_DB_USER', variable: 'TONIC_DB_USER'),
           string(credentialsId: 'TONIC_DB_PASSWORD', variable: 'TONIC_DB_PASSWORD'),
           string(credentialsId: 'TONIC_SMTP_PASSWORD', variable: 'TONIC_SMTP_PASSWORD'),
           string(credentialsId: 'TONIC_DOCKER_AUTH', variable: 'TONIC_DOCKER_AUTH'),
           string(credentialsId: 'TONIC_SSO_CLIENT_ID', variable: 'TONIC_SSO_CLIENT_ID')]) {
        sh """
          ./deploy.sh
        """
       }
      }
    }

  }
}

