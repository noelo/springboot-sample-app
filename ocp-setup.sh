#!/bin/bash

# TODO: Think about using dictonary to store possible arguments
#declare -A args

declare ocp_cluster_url
declare ocp_token
declare app_name
declare git_user
declare git_pass

# Capture named arguments for later use
for ((i=1;i<=$#;i++));
do

  if [ ${!i} = "--help" ] || [ ${!i} = "-h" ];
  then
    # Print out required arguments
    echo "Required arguments for ocp-project-setup: ";
    echo "--ocp-cluster-url URL of the target OpenShift cluster";
    echo "--ocp-token Token used for login to OpenShift cluster";
    echo "--app-name Name of the application to use as a prefix for all generated OpenShift projects";
    echo "--git-user Username of git account to be stored as a secret in the generated develop project";
    echo "--git-pass Password of git account to be stored as a secret in the generated develop project";
    # Exit the script
    exit 0;

  elif [ ${!i} = "--ocp-cluster-url" ];
  then ((i++))
      ocp_cluster_url=${!i};

  elif [ ${!i} = "--ocp-token" ];
  then ((i++))
      ocp_token=${!i};

  elif [ ${!i} = "--app-name" ];
  then ((i++))
      app_name=${!i};

  elif [ ${!i} = "--git-user" ];
  then ((i++))
      git_user=${!i};

  elif [ ${!i} = "--git-pass" ];
  then ((i++))
      git_pass=${!i};
  fi

done;

# Ensure that all required arguments are present
if [ -z "$ocp_cluster_url" ] || \
  [ -z "$ocp_token" ] || \
  [ -z "$app_name" ] || \
  [ -z "$git_user" ] || \
  [ -z "$git_pass" ];
  then
    echo "Not all required arguments are present.";
    echo "Required arguments for ocp-project-setup: ";
    echo "--ocp-cluster-url URL of the target OpenShift cluster";
    echo "--ocp-token Token used for login to OpenShift cluster";
    echo "--app-name Name of the application to use as a prefix for all generated OpenShift projects";
    echo "--git-user Username of git account to be stored as a secret in the generated develop project";
    echo "--git-pass Password of git account to be stored as a secret in the generated develop project";
    echo "Exiting..."
    exit 1;
fi

# Log into OpenShift cluster.
# echo
# echo "What is your OpenShift token?"
# echo -n
# read TOKEN
oc login $ocp_cluster_url --token=$ocp_token

# echo
# echo "What name would you like to preface your projects?"
# echo "(i.e. ____-dev, ____-int, ____-stress, etc.)"
# echo -n
# read app_name

# Create new projects for each stage of the pipeline.
# Development, integration, UAT, stress, production.
echo
echo ================================================
echo
echo "Creating new projects in OpenShift..."
echo
echo ================================================
echo
oc new-project $app_name-develop
oc new-project $app_name-integration
oc new-project $app_name-uat
oc new-project $app_name-stress
oc new-project $app_name-prod

# Create cicd service account for Jenkins.
echo
echo ================================================
echo
echo "Creating cicd service account for Jenkins..."
echo
echo ================================================
echo
oc project $app_name-develop
oc create serviceaccount cicd

# Give edit access to service account in each projectUAT
echo
echo ================================================
echo
echo "Giving edit access to cicd service account..."
echo
echo ================================================
echo
oc policy add-role-to-user edit system:serviceaccount:$app_name-develop:cicd -n $app_name-develop
oc policy add-role-to-user edit system:serviceaccount:$app_name-develop:cicd -n $app_name-integration
oc policy add-role-to-user edit system:serviceaccount:$app_name-develop:cicd -n $app_name-uat
oc policy add-role-to-user edit system:serviceaccount:$app_name-develop:cicd -n $app_name-stress
oc policy add-role-to-user edit system:serviceaccount:$app_name-develop:cicd -n $app_name-prod
oc policy add-role-to-user self-provisioner system:serviceaccount:$app_name-develop:cicd

# Give image-pulling role to service account
# to pull images from development project
echo
echo ================================================
echo
echo "Giving image-puller access to cicd service account..."
echo
echo ================================================
echo
oc policy add-role-to-group system:image-puller system:serviceaccounts:$app_name-integration -n $app_name-develop
oc policy add-role-to-group system:image-puller system:serviceaccounts:$app_name-uat -n $app_name-integration
oc policy add-role-to-group system:image-puller system:serviceaccounts:$app_name-stress -n $app_name-uat
oc policy add-role-to-group system:image-puller system:serviceaccounts:$app_name-prod -n $app_name-stress

# Create gitsecret for dev project.
echo
echo ================================================
echo
echo "Creating git secret for dev project..."
echo
echo ================================================
echo

# echo -n "What is your TFS username? "
# read GIT_USERNAME
# echo -n "What is your TFS password? "
# read GIT_PASSWORD

oc project $app_name-develop
oc secrets new-basicauth gitsecret --username=$git_user --password=$git_pass

# TODO add application label to secret
# oc label secret gitsecret applicationName=cipe

# In order to use this within your Jenkins pipeline,
# you will need to retrieve the service account's token
# and place it in your Jenkinsfile for authTokenDev.
echo
echo ================================================
echo
echo "Retrieving auth token for service account..."
echo
echo ================================================
echo
oc project $app_name-develop
declare ocp_sa_token=`oc serviceaccounts get-token cicd`

echo
echo ================================================
echo
echo "Additional changes are required in your Jenkinsfile."
echo
echo "Please enter this auth token in your Jenkinsfile."
echo "-- authTokenDev = $ocp_sa_token"
echo
echo "Make sure to change the project names as well."
echo "Your dev project will be $app_name-develop, etc."
echo
echo ================================================
echo
