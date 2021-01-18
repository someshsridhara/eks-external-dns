#!/bin/bash

echo "Getting policies available to check if the policy being created already exists.."

POLICY_COUNT=`aws iam list-policies | grep $POLICY_NAME | wc -l`

if [ $POLICY_COUNT -gt "0" ]; then
    echo "Policy exists skipping creation";
    exit;
else
    echo "Creating policy as it doesnt exist.."
    POLICY_ARN=`aws iam create-policy \
    --policy-name $POLICY_NAME \
    --policy-document file://templates/policy.json | jq -r '.Policy.Arn'`;
    echo $POLICY_ARN;
fi

# echo "Creating IAM role.."
ROLE_ARN=`aws iam create-role --role-name external-dns --assume-role-policy-document file://templates/trust.json | jq -r '.Role.Arn'`

# echo "Attaching policy.. "
aws iam attach-role-policy --role-name external-dns --policy-arn=$POLICY_ARN

echo "Creating and Annotating the ingress controller service account"

kubectl apply -f ./manifests/service-account.yaml -n kube-system

kubectl annotate --overwrite serviceaccount -n kube-system external-dns \
eks.amazonaws.com/role-arn=$ROLE_ARN

echo "Deploy External-DNS"
kubectl apply -f ./manifests/deployment.yaml -n kube-system

kubectl annotate --overwrite deployment -n kube-system external-dns \
iam.amazonaws.com/role=$ROLE_ARN