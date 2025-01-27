pipeline {
    agent any
    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "maven_new"
    }
    environment {
        serviceName = "devsecops-svc"
        applicationURL="http://172.25.232.136"
        applicationURI="increment/99"
    }

    stages {
        stage('Build') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archive 'target/*.jar'
            }
        }
           stage('Test') {
            steps {
                sh "ls ; mvn test"
            }
            post{
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco (execPattern: 'target/jacoco.exec')
                  }
             }
        }
        stage('Mutation Tests - PIT') {
         steps {
          sh "mvn org.pitest:pitest-maven:mutationCoverage"
         }
        post {
          always{
          pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
              }
          }
       }
       
       stage('SonarQube - SAST') {
         steps {
         withSonarQubeEnv('SonarQube') {
          sh "mvn sonar:sonar \
                               -Dsonar.projectKey=DevSecOps\
                               -Dsonar.host.url=http://localhost:9000"
        }
        timeout(time: 2, unit: 'MINUTES') {
          script {
            waitForQualityGate abortPipeline: true
          }
         }
       }
    }
    stage('Vulnerability Scan - Docker') {
            steps {
                parallel(
                    "Dependency Scan": {
                        sh "mvn dependency-check:check"
                    },
                    "Trivy Scan":{
                        sh "bash trivy-docker-image-scan.sh"
                    }
                 )
              }
                post {
                   always {
                      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
                }
             }
          }
           stage('Docker Build and Push') {
            steps {
              withDockerRegistry([credentialsId: "docker-hub", url: "https://quay.io/"]) {
                sh 'printenv'
                sh 'sudo docker build -t quay.io/glyimo/numeric-app:""$GIT_COMMIT"" .'
                sh 'docker push quay.io/glyimo/numeric-app:""$GIT_COMMIT""'
            }
         }
      }
      
           stage('K8S Deployment - DEV') {
               steps {  
                 withKubeConfig([credentialsId: 'kubeconfig']) {
                 sh "sed -i 's#replace#quay.io/glyimo/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                 sh "kubectl apply -f k8s_deployment_service.yaml"
             }
          }
      }   
    stage('Integration Tests - DEV') {
            steps {
              script {
                 try {
                   withKubeConfig([credentialsId: 'kubeconfig']) {
                   sh "bash integration-test.sh"
                  }
             } catch (e) {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "kubectl -n default rollout undo deploy ${deploymentName}"
             }
             throw e
             }
          }
       }
     }   
   }
}