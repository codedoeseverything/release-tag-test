#!/usr/bin/env bash

# 1. Query s3 ls to check if this repo csv exist.
# 2. if no csv then create new one or download old one.
STATUSREPORTS3Bucket=reporting123  #Remove later
GITHUB_REPOSITORY=codedoeseverything/release-tag-test #Remove later
ENV=sandbox #Remove later
AWS_ID=P1-SANDBOX #Remove later
STATUS=Deployed #Remove later
GITHUB_REF=refs/heads/main #Remove later
GITHUB_SHA=21586d92266fd93d223f1f612dde75b7a60a6f66 #Remove later
GITHUB_ACTOR=codedoeseverything
GITHUB_EVENT_NAME=push
REGION=ap-southeast-2
ENDPOINT=https://admin.beta.practera.com
 
aws s3 ls s3://$STATUSREPORTS3Bucket | awk '{print $4}' | grep ${GITHUB_REPOSITORY##*/} >> /dev/null 2>&1
if [ $? == 0 ]
then
  echo ${GITHUB_REPOSITORY##*/}".csv already exist..!! Download existing one to modify"
  aws s3 cp s3://reporting123/${GITHUB_REPOSITORY##*/}.csv ${GITHUB_REPOSITORY##*/}.csv
else
  echo ${GITHUB_REPOSITORY##*/}".csv doesn't exist..!! Sample csv download to modify"
  aws s3 cp s3://reporting123/sample.csv ${GITHUB_REPOSITORY##*/}.csv
fi

# 3. give permission to new file
chmod +x ${GITHUB_REPOSITORY##*/}.csv

# 4. perform variable value retrival. 
REPO_URL=${GITHUB_REPOSITORY##*/}
BRANCH=${GITHUB_REF##*/}
COMMIT_SHA=${GITHUB_SHA:0:10}
DATE=$(date +%D)
TIME=$(date +%T)
STATUSREPORT=$GITHUB_REPOSITORY,$BRANCH,$COMMIT_SHA,$GITHUB_ACTOR,$GITHUB_EVENT_NAME,$ENV,$AWS_ID,$REGION,$STATUS,$DATE,$TIME,$ENDPOINT
PRACTERA_LOGO1='<section class="image-container">'
PRACTERA_LOGO2='<img alt="Practera Logo" src="https://practera.com/wp-content/uploads/2020/11/Practera-logo-2.svg">'
PRACTERA_LOGO3='</section>'

# 5. update to csv file 
sed -i -e "2i$STATUSREPORT" ${GITHUB_REPOSITORY##*/}.csv

# 6. convert to html file 
csvtotable ${GITHUB_REPOSITORY##*/}.csv ${GITHUB_REPOSITORY##*/}.html

# 7. check to modif html file as well for header part
sed -i -e 's/\<Table\>/Practera DevOps Deployment Status/g' ${GITHUB_REPOSITORY##*/}.html
sed -i -e "3i$PRACTERA_LOGO1" ${GITHUB_REPOSITORY##*/}.html
sed -i -e "4i$PRACTERA_LOGO2" ${GITHUB_REPOSITORY##*/}.html
sed -i -e "5i$PRACTERA_LOGO3" ${GITHUB_REPOSITORY##*/}.html

# 8. copy back csv and html file
aws s3 cp ${GITHUB_REPOSITORY##*/}.csv s3://reporting123/${GITHUB_REPOSITORY##*/}.csv --acl public-read-write
aws s3 cp ${GITHUB_REPOSITORY##*/}.html s3://reporting123/${GITHUB_REPOSITORY##*/}.html --acl public-read-write

