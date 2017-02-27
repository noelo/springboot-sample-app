// Set SKIP_TLS true for Kubernetes API access
properties([
  [$class: 'ParametersDefinitionProperty', parameterDefinitions:
    [
      [$class: 'StringParameterDefinition', name: 'SKIP_TLS', defaultValue: 'true']
    ]
  ]
])

devClusterAuthToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJzYW1wbGUtZGV2ZWxvcCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjaWNkLXRva2VuLXhveHhwIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNpY2QiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJiODBlNzJlNS1mZDFlLTExZTYtYjhkMC01MjU0MDBlZTljOGYiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6c2FtcGxlLWRldmVsb3A6Y2ljZCJ9.QKnkxkvGbhxt81lxKRmcMmTwifJ5Eb6IucBQotiuUM_xgoaB4InW6jzqZXHmqaajskELvNL7LumF_c3WR1pEFoDzCL3LZ9C2M-1cGwD-pcTVVk1fXY-K4ruSjFdXubO9zmR716eC80Zusrw7ShSjBizI7x2OsXDUSBjAAuBkMrRs1D2aE-QaJgolLyusfCp2-i1mKLKbPeO7TxF8iAEiHAjyVwQnv5Y98CwdDIjYSCMOMckvyR2FbL9bBZQSsCbfUoWN6Fy-seYMi7OxJwyRg07LVjGnaViorL5u8uKDSJsOTu4pMw_bVDuW9HrSe626ugp04yc55S1Ui11IsE4Qmw'

stressRRClusterAuthToken = devClusterAuthToken
stressWWClusterAuthToken = devClusterAuthToken
prodRRClusterAuthToken = devClusterAuthToken
prodWWClusterAuthToken = devClusterAuthToken

devClusterAPIURL = 'https://10.1.2.2:8443'
stressRRClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'
stressWWCluster = 'https://master-vip1.paasdev.ams1907.com:8443'
prodRRClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'
prodWWClusterAPIURL = 'https://master-vip1.paasdev.ams1907.com:8443'


// Declare OpenShift project names
projectDev = 'sample-develop'
projectInt = 'sample-integration'
projectUAT = 'sample-uat'
projectStress = 'sample-stress'
projectProd = 'sample-prod'

// Declare microservice name
microservice = 'springboot-hello'

// Collect the git info
//gitURL = "http://tfs.ups.com:8080/tfs/UpsProd/P08SGIT_EA_CDP/_git/springboot-hello"
gitURL = "https://github.com/domenicbove/springboot-sample-app"
gitContextDir = "/"
gitBranch = "develop"
gitCommit = env.GIT_COMMIT
gitCredentialsId = 'nicks-new-pass'
// gitCredentialsId = 'icdc-jenkins-build'

print "microservice: ${microservice}"

// Define the name of the microservice's template in OpenShift
templatePath = "${microservice}/infra/ocp-templates/ups-maven-s2i-routed-template.json"
template = "openshift//ups-maven-s2i-routed"

// Check if we are in the main dev gitBranch
//if (gitBranch == 'develop') {
  // We are in the dev gitBranch. Time to start the main pipeline.

  // Build into the develop OpenShift project
  stage ('Build and Unit Test in Develop') {
    buildAndUnitTestInDev()
  }

  // oc policy add-role-to-group system:image-puller system:serviceaccounts:hello-integration -n hello-develop
  stage ('Promote to Integration') {
    promoteToInt()
  }

  input 'Promote to UAT?'
  stage ("Promote to UAT") {
    promoteToUAT()
  }

  input 'Promote to Stress?'
  stage('Promote to Stress') {
    promoteToStress()
  }

  input 'Promote to Production'
  stage('Promote to Production') {
    promoteToProduction()
  }

//} else {
  // We are in a feature gitBranch
  //print "Not the develop gitBranch"

//  node() {
//    print "The jenkins-agent-base works!"
//    print "results: " + existsInProject(microservice, projectDev)
//    print "Agent work completed."
//  }

//}

/**
 * [ocpObjectsExist description]
 * @param  String microservice  [description]
 * @param  String project       [description]
 * @return        [description]
 */
def boolean ocpObjectsExist(String microservice, String project, String apiURL,
  String authToken) {
  // login to the dev cluster
  login(apiURL, authToken)

  // TODO: Fix issue where any non-empty/null result string is a true case
  // Capture results of label queried get all to a string
  String queryResults = sh (
      script: """
          oc get all -l microservice=${microservice} -n ${project}
        """,
      returnStdout: true
    )
  print "queryResults: ${queryResults}"
  // If the string is empty/null, the OpenShift objects do not exist
  if (queryResults == null || queryResults.length() == 0) {
    return false;
  }
  return true;
}

/**
 * [createOCPObjects description]
 * @param  boolean buildConfig   [description]
 * @return         [description]
 */
def createOCPObjects(String microservice, String project, String apiURL,
  String authToken) {
  print "Logging in..."
  // login to the project's cluster
  login(apiURL, authToken)
  print "Logged in."

  // Process the microservice's template
  sh """
    # Process the template and create resources
    oc process -f ${templatePath} \
      MICROSERVICE_NAME=${microservice} \
      GIT_REPO_URL=${gitURL} \
      GIT_REPO_BRANCH=${gitBranch} \
      GIT_CONTEXT_DIR=${gitContextDir} -n ${project} | oc create -f - \
      -n ${project} --save-config
  """

}

/**
 * [replaceOCPObjects description]
 * @param  String project       [description]
 * @param  String apiURL        [description]
 * @param  String authToken     [description]
 * @return        [description]
 */
def replaceOCPObjects(String microservice, String project, String apiURL,
  String authToken) {
  print "Logging in..."
  // login to the project's cluster
  login(apiURL, authToken)
  print "Logged in."

  // Process the microservice's template
  sh """
   # Delete old builds
   #oc delete builds -l microservice=${microservice} -n ${project}
   #oc delete dc/${microservice} -n ${project}
   # Process the template
   oc process -f ${templatePath} \
    MICROSERVICE_NAME=${microservice} \
    GIT_REPO_URL=${gitURL} \
    GIT_REPO_BRANCH=${gitBranch} \
    GIT_CONTEXT_DIR=${gitContextDir} -n ${project} | oc replace -n ${project} \
    --force  --cascade -f -
  """

  // if (!keepBuildConfig) {
  //   print 'Deleting build config...'
  //   sh """
  //     oc delete bc -l microservice=${microservice} --grace-period=0
  //   """
  //   print 'Build config deleted'
  // } else {
  //   print 'Keeping build config'
  // }

}

/**
 * [promoteOCPObjects description]
 * @param  String microservice  [description]
 * @param  String srcProject    [description]
 * @param  String srcAPIURL     [description]
 * @param  String srcAuthToken  [description]
 * @param  String destProject   [description]
 * @param  String destAPIURL    [description]
 * @param  String destAuthToken [description]
 * @return        [description]
 */
def promoteOCPObjects(String microservice, String srcProject, String srcAPIURL,
  String srcAuthToken, String destProject, String destAPIURL, String destAuthToken) {

  // login to the source project cluster
  login(srcAPIURL, srcAuthToken)

  // Export the source objects for the microservice as a file
  sh """
    # Export contents of project for a microservice into a yaml file
    oc export dc,is,svc,secret,route -l microservice=${microservice}  \
      -n ${srcProject} -o yaml > objects.yaml

    cat objects.yaml
  """
      //      -l template=app-template \


  // TODO: Check to see if apply changes route host in OpenShift 3.4
  // Attempt to correct the auto generated route
  File objects = new File('objects.yaml')
  String corrected = correctRoute(objects.text)
  objects.text = corrected

  // Login to the dest project cluster
  login(destAPIURL, destAuthToken)

  // Check if the objects exist in the destination project
  if (!ocpObjectsExist(microservice, destProject, destAPIURL,
    destAuthToken)) {
      // Create the objects in the destination project
      sh """
        oc create -n ${destProject} -f objects.yaml --save-config
      """
      //createOCPObjects(microservice, destProject, destAPIURL, destAuthToken)
  } else {
    // apply the objects in the destination project
    sh """
      oc apply -n ${destProject} -f objects.yaml
    """
  }

  // Delete the objects yaml file
  sh """
    cat objects.yaml
    rm objects.yaml
  """
}

/**
 * [correctRoute description]
 * @param  String microservice  [description]
 * @param  String srcProject    [description]
 * @param  String destProject   [description]
 * @param  String exports       [description]
 * @return        [description]
 */
def String correctRoute(String microservice, String srcProject, String destProject,
  String objects) {

  if (objects.contains("kind: Route")) {
    String corrected = objects.replaceAll("host: ${microservice}-${srcProject}",
      "host: ${microservice}-${destProject}")
    return corrected
  }
  // There's no route
  return objects
}

/**
 * [copyAllOCPObjects description]
 * @param  String srcProject    [description]
 * @param  String srcAPIURL     [description]
 * @param  String srcAuthToken  [description]
 * @param  String destProject   [description]
 * @param  String destAPIURL    [description]
 * @param  String destAuthToken [description]
 * @return        [description]
 */
def copyAllOCPObjects(String srcProject, String srcAPIURL, String srcAuthToken,
  String destProject, String destAPIURL, String destAuthToken) {

  // login to the source project cluster
  login(srcAPIURL, srcAuthToken)

  // Export the source objects for the microservice as a file
  sh """
    # Export contents of project into a yaml file
    oc export dc,is,svc,secret,routes --all  \
      -n ${srcProject} -o yaml > objects.yaml
  """

  // Login to the dest project cluster
  login(destAPIURL, destAuthToken)

  // Create the objects in the destination project
  sh """
    oc create -n ${destProject} -f objects.yaml
    # Delete the objects file
    rm objects.yaml
  """
}



/**
 * [login description]
 * @param  String apiURL        [description]
 * @param  String authToken         [description]
 * @return        [description]
 */
def login(String apiURL, String authToken) {
    sh """
        set +x
        oc login --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
          --token=${authToken} ${apiURL} >/dev/null 2>&1 || echo 'OpenShift login failed'
        oc whoami
       """
}

/**
 * [gitCheckout description]
 * @param  String url           [description]
 * @param  String branch        [description]
 * @param  String targetDir     [description]
 * @return        [description]
 */
 def gitCheckout(String url, String branch, String targetDir, String credentialsId) {

 sh """
   # Ensure the targetDir is deleted before we clone
   rm -rf ${targetDir}
   git clone -b ${branch} ${url} ${targetDir}
   echo `pwd && ls -l`
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


/**
 * [buildAndUnitTestInDev description]
 * @return [description]
 */
def buildAndUnitTestInDev() {
  print "----------------------------------------------------------------------"
  print "                   Build and Unit Test in Develop                     "
  print "----------------------------------------------------------------------"
  // Fire up a jenkins agent to execute in
  node() {
    sh """
      oc version
    """
    input 'Version good?'
    // Checkout the code
    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    // Check if the OPC Objects exist in project
    if (!ocpObjectsExist(microservice, projectDev, devClusterAPIURL,
      devClusterAuthToken)) {
      // Create the objects
      print "Creating OCP objects for ${microservice} in ${projectDev}"
      createOCPObjects(microservice, projectDev, devClusterAPIURL, devClusterAuthToken)
      print "Objects created!"
    } else {
      // Replace the objects
      print "Replacing OCP objects for ${microservice} in ${projectDev}"
    //  replaceOCPObjects(microservice, projectDev, devClusterAPIURL, devClusterAuthToken)
      print "OCP objects replaced!"
    }

    print "Starting build..."
  //  openshiftBuild(namespace: projectDev,
  //    buildConfig: microservice,
  //    showBuildLogs: 'true',
  //    apiURL: devClusterAPIURL,
  //    authToken: devClusterAuthToken)
    print "Build skipped!"


    print "Verify Deployment in develop"

    // Verify the Deployment into dev
    openshiftVerifyDeployment(
      depCfg: microservice,
      namespace: projectDev,
      replicaCount: '1',
      verbose: 'false',
      verifyReplicaCount: 'true',
      waitTime: '32',
      waitUnit: 'sec',
      apiURL: devClusterAPIURL,
      authToken: devClusterAuthToken)

    print "Deployment to develop verified!"
  }
}

/**
 * [promoteToInt description]
 * @return [description]
 */
def promoteToInt() {
  print "----------------------------------------------------------------------"
  print "                      Promoting to Integration                        "
  print "----------------------------------------------------------------------"
  // Fire up a jenkins agent to execute in
  node() {

    // Checkout the code
    //gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    print "Promoting to integration..."
    // Copy objects from develop -> integration
    print "Promoting OCP objects for ${microservice} in ${projectInt}"
    promoteOCPObjects(microservice, projectDev, devClusterAPIURL,
      devClusterAuthToken, projectInt, devClusterAPIURL, devClusterAuthToken)
    print "Objects promoted!"


    // Tag microservice image into the integration OpenShift project
    openshiftTag(namespace: projectDev,
      sourceStream: microservice,
      sourceTag: 'latest',
      destinationNamespace: projectInt,
      destinationStream: microservice,
      destinationTag: 'latest',
      apiURL: devClusterAPIURL,
      authToken: devClusterAuthToken)

    print "Promotion completed!"

    print "Verify Deployment in integration"

    // Verify the Deployment into integration
    openshiftVerifyDeployment(
      depCfg: microservice,
      namespace: projectInt,
      replicaCount: '1',
      verbose: 'false',
      verifyReplicaCount: 'true',
      waitTime: '32',
      waitUnit: 'sec',
      apiURL: devClusterAPIURL,
      authToken: devClusterAuthToken)

    print "Deployment to integration verified!"
  }
}

/**
 * [promoteToUAT description]
 * @return [description]
 */
def promoteToUAT() {
  print "----------------------------------------------------------------------"
  print "                         Promoting to UAT                             "
  print "----------------------------------------------------------------------"
  // Fire up a jenkins agent to execute in
  node() {
    // Checkout the code
    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    // Fire up jenkins-agent pod for promotion to UAT
      print "Promotion to UAT commencing..."

      // Copy objects from integration -> UAT
      print "Promoting OCP objects for ${microservice} in ${projectUAT}"
      promoteOCPObjects(microservice, projectInt, devClusterAPIURL,
        devClusterAuthToken, projectUAT, devClusterAPIURL, devClusterAuthToken)
      print "Objects promoted!"

      // Tag microservice image into the UAT OpenShift project
      openshiftTag(namespace: projectInt,
        sourceStream: microservice,
        sourceTag: 'latest',
        destinationNamespace: projectUAT,
        destinationStream: microservice,
        destinationTag: 'latest',
        apiURL: devClusterAPIURL,
        authToken: devClusterAuthToken)

      print "Promotion completed!"

      print "Verify Deployment in UAT"

      // Verify the Deployment into UAT

      openshiftVerifyDeployment(
        depCfg: microservice,
        namespace: projectUAT,
        replicaCount: '1',
        verbose: 'false',
        verifyReplicaCount: 'true',
        waitTime: '32',
        waitUnit: 'sec',
        apiURL: devClusterAPIURL,
        authToken: devClusterAuthToken)

      print "Deployment to UAT verified!"

  }
}

/**
 * [promoteToStress description]
 * @return [description]
 */
def promoteToStress() {
  print "----------------------------------------------------------------------"
  print "                        Promoting to Stress                           "
  print "----------------------------------------------------------------------"
  // Fire up a jenkins agent to execute in
  node() {
    // Checkout the code
    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    print "Promotion to Stress commencing..."
    // TODO: Handle both RR and WW clusters
    // Copy objects from UAT -> stress
    print "Promoting OCP objects for ${microservice} in ${projectStress}"
    // copyOCPObjects(microservice, projectUAT, devClusterAPIURL,
    //   devClusterAuthToken, projectStress, stressRRClusterAPIURL, stressRRClusterAuthToken)
    promoteOCPObjects(microservice, projectUAT, devClusterAPIURL,
      devClusterAuthToken, projectStress, devClusterAPIURL, devClusterAuthToken)
    print "Objects promoted!"

    // TODO: Switch from tagging to importing inter cluster
    // Tag microservice image into the Stress OpenShift project
    openshiftTag(namespace: projectUAT,
      sourceStream: microservice,
      sourceTag: 'latest',
      destinationNamespace: projectStress,
      destinationStream: microservice,
      destinationTag: 'latest',
      apiURL:devClusterAPIURL,
      authToken: devClusterAuthToken)

     print "Promotion completed!"

     print "Verify Deployment in Stress"

     // Verify the Deployment into Stress
     openshiftVerifyDeployment(
       depCfg: microservice,
       namespace: projectStress,
       replicaCount: '1',
       verbose: 'false',
       verifyReplicaCount: 'true',
       waitTime: '32',
       waitUnit: 'sec',
       apiURL: devClusterAPIURL,
       authToken: devClusterAuthToken)

     print "Deployment to Stress verified!"
  }
}

/**
 * [promoteToProd description]
 * @return [description]
 */
def promoteToProd() {
  print "----------------------------------------------------------------------"
  print "                         Promoting to Prod                            "
  print "----------------------------------------------------------------------"
  // Fire up a jenkins agent to execute in
  node() {
    // Checkout the code
    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    print "Promotion to Production commencing..."
    // TODO: Handle both RR and WW clusters
    // Copy objects from stress -> prod
    print "Promoting OCP objects for ${microservice} in ${projectStress}"
    //  copyOCPObjects(microservice, projectStress, stressRRClusterAPIURL,
    //    stressRRClusterAuthToken, projectProd, prodRRClusterAPIURL, prodRRClusterAuthToken)
    promoteOCPObjects(microservice, projectStress, stressRRClusterAPIURL,
      stressRRClusterAuthToken, projectProd, devClusterAPIURL, devClusterAuthToken)
    print "Objects promoted!"

    // TODO: Switch from tagging to import inter cluster
    // Tag microservice image into the Stress OpenShift project
    openshiftTag(namespace: projectStress,
     sourceStream: microservice,
     sourceTag: 'latest',
     destinationNamespace: projectProd,
     destinationStream: microservice,
     destinationTag: 'latest',
     apiURL: devClusterAPIURL,
     authToken: devClusterAuthToken)


   print "Promotion completed!"

   print "Verify Deployment in Production"

   // Verify the Deployment into Production
   openshiftVerifyDeployment(
     depCfg: microservice,
     namespace: projectProd,
     replicaCount: '1',
     verbose: 'false',
     verifyReplicaCount: 'true',
     waitTime: '32',
     waitUnit: 'sec',
     apiURL: devClusterAPIURL,
     authToken: devClusterAuthToken)

     print "Deployment to Production verified!"
  }
}

// stage 'Promote to Integration'
// openshiftTag(namespace: 'development', sourceStream: 'myapp',  sourceTag: 'latest', destinationStream: 'myapp', destinationTag: 'latest')
//
// stage 'Integration Test'
// openshiftBuild(namespace: 'integration', buildConfig: 'myappIntegrationTest', showBuildLogs: 'true')
//
// stage 'Promote to QA Dev Gate'
// input message: "Promote to QA Dev?", ok: "Promote"
//
// stage 'Promote to QA Dev'
// openshiftTag(namespace: 'integration', sourceStream: 'myapp',  sourceTag: 'latest', destinationStream: 'myapp', destinationTag: 'latest')
//
// stage 'Run Integration Tests Gate'
// input message: "Run Integration Tests?", ok: "Promote"
//
// stage 'Final Integration Test'
// openshiftBuild(namespace: 'qaDev', buildConfig: 'myappIntegrationTest', showBuildLogs: 'true')
//
// stage 'Promote to UAT Gate'
// input message: "Promote to UAT?", ok: "Promote"
//
// stage 'Promote to QA Dev'
// openshiftTag(namespace: 'qaDev', sourceStream: 'myapp',  sourceTag: 'latest', destinationStream: 'myapp', destinationTag: 'latest')
//
// stage 'UAT Approve Gate'
// input message: "Promote to Stress?", ok: "Promote"
//
// stage 'Promote to Stress'
// openshiftTag(namespace: 'uat', sourceStream: 'myapp',  sourceTag: 'latest', destinationStream: 'myapp', destinationTag: 'latest')
//
// stage 'Change Control Approve Gate'
// input message: "Promote to Production?", ok: "Promote"
//
// stage 'Promote to Production'
// openshiftTag(namespace: 'stress', sourceStream: 'myapp',  sourceTag: 'latest', destinationStream: 'myapp', destinationTag: 'latest')


// https://blog.openshift.com/create-build-pipelines-openshift-3-3/
// need all these namespaces, build configs, deployment configs in openshift
// oc policy add-role-to-group system:image-puller system:serviceaccounts:testing -n development
