// Set SKIP_TLS true for Kubernetes API access
properties([
  [$class: 'ParametersDefinitionProperty', parameterDefinitions:
    [
      [$class: 'StringParameterDefinition', name: 'SKIP_TLS', defaultValue: 'true']
    ]
  ]
])

devClusterAuthToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6ImplbmtpbnMtdG9rZW4tOHk3OWsiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoiamVua2lucyIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImM4NDE3Zjg0LTAyOGEtMTFlNy05NmFmLTJjYzI2MDJmODc5NCIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OmplbmtpbnMifQ.UBn2-N8fkBLZekTXwhAWbcRu-YfqbJbdNmb4I9Q3YEZH_hqkXVVIl3RpT14CJ_kpSeomGKXmfcOr77Y58Q63HuHwxYQffciWM0VfaskBxGy0i1vI4VIqHij-lTCMvntghk6L4c5I7RKCIWOfmroCIYPpCI0NaZjifpO4E-V_hW5oWNOF4sMN_hwfTn3A1smkZaHQ4ax7KIUCdqG0serpDMLiuX0basBKGQBFF7fde0NrbT3WH8D0G2saayeZEehOq31IDDnN_1Q9WBTI4429x2bDBiRUJWLJ-2H7lVBDSeyANYmZ4CPL44Y_2sfOmq8G1btQedKYjxVMuWtk0c8s9w'

stressRRClusterAuthToken = devClusterAuthToken
stressWWClusterAuthToken = devClusterAuthToken
prodRRClusterAuthToken = devClusterAuthToken
prodWWClusterAuthToken = devClusterAuthToken

devClusterAPIURL = 'https://master1-be43.oslab.opentlc.com:8443'

stressRRClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'
stressWWCluster = 'https://master-vip1.paasdev.ams1907.com:8443'
prodRRClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'
prodWWClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'

// Declare OpenShift project names
projectDev = 'hello-develop'
projectInt = 'hello-integration'
projectUAT = 'hello-uat'
projectStress = 'hello-stress'
projectProd = 'hello-prod'

// Declare microservice name
microservice = 'springboot-hello'
applicationName = 'cipe'

// Collect the git info
//gitURL = "http://tfs.ups.com:8080/tfs/UpsProd/P08SGIT_EA_CDP/_git/springboot-hello"
gitURL = "https://github.com/domenicbove/springboot-sample-app"
gitContextDir = "/"
gitBranch = env.BRANCH_NAME
gitCommit = env.GIT_COMMIT
gitCredentialsId = 'nicks-new-pass'
// gitCredentialsId = 'icdc-jenkins-build'

print "microservice: ${microservice}"

// Define the name of the microservice's template in OpenShift
templatePath = "${microservice}/infra/ocp-templates/ups-maven-s2i-routed-template.json"
buildConfigTemplatePath = "${microservice}/infra/ocp-templates/build-config-template.json"
template = "openshift//ups-maven-s2i-routed"

if (gitBranch == 'develop') {
  // Build into the develop OpenShift project
  stage ('Build and Unit Test in Develop') {
    print "----------------------------------------------------------------------"
    print "                   Build and Unit Test in Develop                     "
    print "----------------------------------------------------------------------"

    node() {

      // login to the project's cluster
      login(devClusterAPIURL, devClusterAuthToken)

      createOCPObjects(microservice, projectDev, devClusterAPIURL, devClusterAuthToken, true)

      print "Starting build..."
      openshiftBuild(namespace: projectDev,
        buildConfig: microservice,
        showBuildLogs: 'true',
        apiURL: devClusterAPIURL,
        authToken: devClusterAuthToken)
      print "Build started"

      print "Verify Deployment in develop"
      openshiftVerifyDeployment(
        depCfg: microservice,
        namespace: projectDev,
        replicaCount: '1',
        verbose: 'false',
        verifyReplicaCount: 'true',
        waitTime: '60',
        waitUnit: 'sec',
        apiURL: devClusterAPIURL,
        authToken: devClusterAuthToken)
      print "Deployment to develop verified!"

    }

  }

  stage ('Promote to Integration') {
    promoteImageBetweenProjectsSameCluster(projectDev, projectInt, devClusterAPIURL, devClusterAuthToken)
  }

  input 'Promote to UAT?'
  // input message: "Promote to UAT?", submitter: "Jenkins Admin"
  stage ('Promote to UAT') {
    promoteImageBetweenProjectsSameCluster(projectInt, projectUAT, devClusterAPIURL, devClusterAuthToken)
  }

  input 'Promote to Stress?'
  // input message: "Promote to Stress?", submitter: "Jenkins Admin"
  stage ('Promote to Stress') {
    promoteImageBetweenProjectsSameCluster(projectUAT, projectStress, devClusterAPIURL, devClusterAuthToken)
  }

} else {
    // feature branch pipeline
    print "Kicking off feature pipeline for feature branch ${gitBranch}"

    featureProject = applicationName + "-" + gitBranch
    featureProject.toLowerCase()
    print featureProject


    try {
      node() {
        login(devClusterAPIURL, "olulotvKMI4p-d17znVL8jkxQjFmP7SQOur0vTLsRQ8")

        sh """
        # Deletes existing feature branch project if it exists
        oc delete project ${featureProject} --ignore-not-found
        sleep 60

        # Adds self-provisioner access to jenkins service account
        oc policy add-role-to-user self-provisioner system:serviceaccount:default:jenkins

        # Creates new feature branch project
        oc new-project ${featureProject}

        # TODO delete for ups, also make sure build config uses openshift/maven-s2i...
        oc import-image fabric8/s2i-java -n ${featureProject} --confirm

        oc policy add-role-to-user edit system:serviceaccount:default:jenkins -n ${featureProject}
        oc policy add-role-to-group system:image-puller system:serviceaccounts:${featureProject} -n ${projectDev}
        """

        // Checks if microservices exist in dev project already
        // If they do, exports them to feature branch project
        // Otherwise, moves forward
        String queryResults = sh (
          script:"""
            oc get all -l applicationName=${applicationName} -n ${projectDev}
          """,
          returnStdout: true
          )
          if(queryResults.length() > 1) {
            sh """
              oc export dc,svc,is,secret -l applicationName=${applicationName} -n ${projectDev} > export.yaml
              oc apply -f export.yaml -n ${featureProject}
              oc delete all -l microservice=${microservice} -n ${featureProject} --cascade=false
            """

            // Get all routes by name
            String routeList = sh (
              script: """
                  oc get routes -l applicationName=${applicationName} -n ${projectDev} --output=name
                """,
              returnStdout: true
            )
            print "routes: ${routeList}"
            stringArray = routeList.split("\n")

            // Loop through list of routes and expose associated service
            for (int i = 0; i < stringArray.size(); i++){
              routeName = stringArray[i]
              String serviceName = sh (
                script: """
                    oc get ${routeName} -n ${projectDev} --output=jsonpath={.spec.to.name}
                  """,
                returnStdout: true
              )
              print "exposing ${serviceName}"
              if(serviceName != microservice){
                sh """
                  oc expose svc/${serviceName} -n ${featureProject}
                """
              }
            }
          }

        createOCPObjects(microservice, featureProject, devClusterAPIURL, devClusterAuthToken, true)

        print "Starting build..."
        openshiftBuild(namespace: featureProject,
          buildConfig: microservice,
          showBuildLogs: 'true',
          apiURL: devClusterAPIURL,
          authToken: devClusterAuthToken)
        print "Build started"

    }
  } finally {
    print "got to finally block"

    sh """
      sleep 10
      echo "slept"
    """
  }

}

/*
* Logs in, creates all OCP objects, tags image into destination project,
* then verifies the deployment in destination project
*/
def promoteImageBetweenProjectsSameCluster(String startProject, String endProject, String clusterAPIURL, String clusterAuthToken) {
  print "----------------------------------------------------------------------"
  print "                     Promoting to ${endProject}                       "
  print "----------------------------------------------------------------------"

  node() {
    // login to the project's cluster
    login(clusterAPIURL, clusterAuthToken)

    createOCPObjects(microservice, endProject, clusterAPIURL, clusterAuthToken, false)

    print "Tagging ${microservice} image into ${endProject}"
    openshiftTag(namespace: startProject,
      sourceStream: microservice,
      sourceTag: 'latest',
      destinationNamespace: endProject,
      destinationStream: microservice,
      destinationTag: 'latest',
      apiURL: clusterAPIURL,
      authToken: clusterAuthToken)

    print "Verify Deployment in ${endProject}"
    openshiftVerifyDeployment(
      depCfg: microservice,
      namespace: endProject,
      replicaCount: '1',
      verbose: 'false',
      verifyReplicaCount: 'true',
      waitTime: '60',
      waitUnit: 'sec',
      apiURL: clusterAPIURL,
      authToken: clusterAuthToken)
    print "Deployment to ${endProject} verified!"

  }
}

/**
* Creates/configures OCP objects in destination project using 'oc apply'
* Uses main template to create dc,svc,is,route and bc template just for Dev
*/
def createOCPObjects(String microservice, String project, String apiURL,
  String authToken, boolean createBuildConfig) {

    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    print "Creating OCP objects for ${microservice} in ${project} with oc apply."

    // Process the microservice's template and create the objects
    sh """
    # Process the template and create resources
    oc process -f ${templatePath} \
    MICROSERVICE_NAME=${microservice} \
    GIT_REPO_URL=${gitURL} \
    GIT_REPO_BRANCH=${gitBranch} \
    GIT_CONTEXT_DIR=${gitContextDir} -n ${project} | oc apply -f - \
    -n ${project}
    """

    // If in Develop Project create the BuildConfig as well
    if(createBuildConfig) {
    //if (project.equals(projectDev)) {
      sh """
      oc process -f ${buildConfigTemplatePath} \
      MICROSERVICE_NAME=${microservice} \
      GIT_REPO_URL=${gitURL} \
      GIT_REPO_BRANCH=${gitBranch} \
      GIT_CONTEXT_DIR=${gitContextDir} -n ${project} | oc apply -f - \
      -n ${project}
      """
    }

    print "Objects created!"
}

/**
* Logs in to destination cluster
*/
def login(String apiURL, String authToken) {
  print "Logging in..."

  sh """
  set +x
  oc login --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  --token=${authToken} ${apiURL} >/dev/null 2>&1 || echo 'OpenShift login failed'
  """
  //echo "Logged in as $(oc whoami)"
}

/**
* Checks out specified branch to retrieve template files
*/
def gitCheckout(String url, String branch, String targetDir, String credentialsId) {
  print "Git cloning..."

  sh """
  # Ensure the targetDir is deleted before we clone
  rm -rf ${targetDir}
  git clone -b ${branch} ${url} ${targetDir}
  """

  //withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: "${credentialsId}",
  //  passwordVariable: 'pass', usernameVariable: 'user']]) {
  // Checkout the code and navigate to the target directory
  //  int slashIdx = url.indexOf("://")
  //  String urlWithCreds = url.substring(0, slashIdx + 3) +
  //    "\"${user}:${pass}\"@" + url.substring(slashIdx + 3);
  //  sh """
  //    # Ensure the targetDir is deleted before we clone
  //    rm -rf ${targetDir}
  //    git clone -b ${branch} ${urlWithCreds} ${targetDir}
  //    echo `pwd && ls -l`
  //  """
  //}
}
