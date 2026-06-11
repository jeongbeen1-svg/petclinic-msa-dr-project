#!/bin/bash
RG="tf-core-tfstate-jaebok1205"
SA="tfcoretfstatejaebok1205"
CONTAINER="tfstate"
LOCATION="koreacentral"

#1) 리소스 그룹 생성
az group create --name $RG --location $LOCATION

#2) Storage Account 생성
az storage account create --name $SA --resource-group $RG \
  --location $LOCATION --sku Standard_LRS --kind StorageV2

#3) Blob Container 생성
az storage container create --name $CONTAINER --account-name $SA

echo "✅ Backend 리소스 생성 완료"