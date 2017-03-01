// Set SKIP_TLS true for Kubernetes API access
properties([
  [$class: 'ParametersDefinitionProperty', parameterDefinitions:
    [
      [$class: 'StringParameterDefinition', name: 'SKIP_TLS', defaultValue: 'true']
    ]
  ]
])

devClusterAuthToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJzYW1wbGUtZGV2ZWxvcCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJjaWNkLXRva2VuLWU5NXNkIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImNpY2QiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI0OTUxODZkZC1mZGMyLTExZTYtYjNmOS0yY2MyNjAyZjg3OTQiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6c2FtcGxlLWRldmVsb3A6Y2ljZCJ9.SiPnCTSbpG0RcT-iNsoG2w5bPRziK0Rgjv1X7pJErN4O9BVwx5k5aJemyh0HM9imBW4gIDFOfdi2OOlmtj9I0qYlaO3sGlnI1wtP3nPV1a-IE8pU-q1ZjfwyivpGzYYVgXwUo8RI0RNBGF6Bqrw9N6ixiJsK60heFhnQQkxzXQuzOTRJ2ACAyG_oeaS72MqeJrwdYwypSudg-3szW4dtRMrcV1dD_1hwx2DV0McdAxs2ch-Se6ZrYaCvT0oEubPPAe3cnBbZNN3A8gID8Vup9MrBceVf1DWFT1t9ABrQBmKu9xDjS-OM0kbZ4BDIO_yIyuS7Cu86bR4oVcocA6PQAw'

stressRRClusterAuthToken = devClusterAuthToken
stressWWClusterAuthToken = devClusterAuthToken
prodRRClusterAuthToken = devClusterAuthToken
prodWWClusterAuthToken = devClusterAuthToken

devClusterAPIURL = 'https://master1-6e16.oslab.opentlc.com:8443'
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
      sh """
      oc version
      """
      input 'Version good?'

      gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

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
  stage ('Promote to UAT') {
    promoteImageBetweenProjectsSameCluster(projectInt, projectUAT, devClusterAPIURL, devClusterAuthToken)
  }

  input 'Promote to Stress?'
  stage ('Promote to Stress') {
    promoteImageBetweenProjectsSameCluster(projectUAT, projectStress, devClusterAPIURL, devClusterAuthToken)
  }

} else {
  // feature branch pipeline
  print "Kicking of feature pipeline for feature branch ${gitBranch}"

  //TODO no caps
  featureProject = applicationName + "-" + gitBranch
  print featureProject

  node() {

    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

    login(devClusterAPIURL, "Epnot9pK4lIwWHgKNvS_vYPgGwyg6jffhzZDAKKH_yI")

    sh """
    oc export dc,svc,is -l applicationName=${applicationName} -n ${projectDev} > export.yaml
    oc new-project ${featureProject}

    # TODO figure out if need to do this w ups builder image
    oc import-image fabric8/s2i-java

    oc policy add-role-to-user edit system:serviceaccount:${projectDev}:cicd -n ${featureProject}
    oc policy add-role-to-group system:image-puller system:serviceaccounts:${featureProject} -n ${projectDev}

    oc apply -f export.yaml -n ${featureProject}
    # TODO expose the routes

    # Delete the feature microservice
    oc delete all -l microservice=${microservice} -n ${featureProject}
    """

    createOCPObjects(microservice, featureProject, devClusterAPIURL, devClusterAuthToken, true)

    print "Starting build..."
    openshiftBuild(namespace: featureProject,
      buildConfig: microservice,
      showBuildLogs: 'true',
      apiURL: devClusterAPIURL,
      authToken: devClusterAuthToken)
    print "Build started"
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
    gitCheckout(gitURL, gitBranch, microservice, gitCredentialsId)

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
    print "Deployment to develop verified!"

  }
}

/**
* Creates/configures OCP objects in destination project using 'oc apply'
* Uses main template to create dc,svc,is,route and bc template just for Dev
*/
def createOCPObjects(String microservice, String project, String apiURL,
  String authToken, boolean createBuildConfig) {
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
