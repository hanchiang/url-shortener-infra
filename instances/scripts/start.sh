#! /bin/bash
set -eu

dir=$(dirname $0)
cd $dir

source ./helper/ec2-helper.sh
source ./helper/wait_for_dns_propagation.sh
source ./helper/timer.sh

GITHUB_TOKEN=$1
SSH_USER=$2
SSH_PRIVATE_KEY_PATH=$3

usage () {
    echo "Invalid $1. usage: <path/to/script> <github token> <ssh user> <ssh private key path>"
    exit 1
}

if [ -z "$GITHUB_TOKEN"  ];
then
    usage "github token"
fi

if [ -z "$SSH_USER"  ];
then
    usage "ssh user"
fi

if [ -z "$SSH_PRIVATE_KEY_PATH"  ];
then
    usage "ssh private key path"
fi


#### Start EC2

wait_for_ec2_stop () {
    instance_info=$(get_instance_info)
    echo $instance_info
    instance_ip_address=$(echo $instance_info | jq -r '.ip_address')
    instance_state=$(echo $instance_info | jq -r '.state')
    instance_id=$(echo $instance_info | jq -r .'id')
    
    if [ "$instance_state" = "running" ] || [ "$instance_state" = "terminated" ] || [ "$instance_state" = "shutting-down" ]
    then
        echo "Instance cannot be started because it is either running, terminated or going to be terminated"
        return 0
    elif [ "$instance_state" == "stopped" ] 
    then
        echo "Instance is already stopped"
        return 0
    else
        local seconds_to_wait=120

        start=$(date +%s)
        time_elapsed=$(get_time_elapsed $start | tail -n 1)

        while [ "$instance_state" != "stopped" ] && [ "$time_elapsed" -lt "$seconds_to_wait" ];
        do
            echo "Waiting for instance $instance_id to be stopped"
            sleep 10
            instance_info=$(get_instance_info)
            instance_state=$(echo $instance_info | jq -r '.state')

            if [ "$instance_state" == "stopped" ]
            then
                echo "Instance $instance_id has stopped"
                printf "\n"
                return 0
            fi
            time_elapsed=$(get_time_elapsed $start | tail -n 1)
        done
        echo "Instance $instance_id did not stop after $seconds_to_wait seconds"
    fi
    printf "\n"
}


start_ec2() {
    instance_info=$(get_instance_info)
    instance_state=$(echo $instance_info | jq -r '.state')
    instance_id=$(echo $instance_info | jq -r .'id')
    instance_ip_address=$(echo $instance_info | jq -r '.ip_address')

    if [ "$instance_state" == "running" ]
    then
        echo "Instance $instance_id is already running. Ip address $instance_ip_address"
        printf "\n"
        return 0
    fi

    local seconds_to_wait=120

    start=$(date +%s)
    time_elapsed=$(get_time_elapsed $start | tail -n 1)

    echo "Starting ec2 $instance_id"
    aws ec2 start-instances --instance-ids $instance_id > /dev/null

    while [ "$instance_state" != "running" ] && [ "$time_elapsed" -lt "$seconds_to_wait" ];
    do
        echo "Waiting for instance $instance_id to be running"
        sleep 10

        instance_info=$(get_instance_info)
        instance_state=$(echo $instance_info | jq -r '.state')
        instance_id=$(echo $instance_info | jq -r .'id')
        instance_ip_address=$(echo $instance_info | jq -r '.ip_address')

        if [ "$instance_state" == "running" ]
        then
            echo "Instance $instance_id is running. Ip address $instance_ip_address"
            printf "\n"
            return 0
        fi
        time_elapsed=$(get_time_elapsed $start | tail -n 1)
    done
    echo "Instance $instance_id is not running after $seconds_to_wait seconds"
    printf "\n"
}

#### Trigger github action deployment
get_latest_github_workflow () {
    echo "Trigger deploy on github actions"
    echo "Getting the latest github actions workflow"

    local latest_workflow
    local workflow_id
    local workflow_url
    local workflow_created_at
    local commit_message
    local jobs_url

    latest_workflow=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/hanchiang/url-shortener-backend/actions/runs\?branch=master\&per_page=100 | jq '[.workflow_runs[] | select(.name | ascii_downcase | contains("build and deploy"))][0]')
    if [ "$?" -ne 0 ]
    then
        return 1
    fi

    workflow_id=$(echo $latest_workflow | jq '.id')
    workflow_url=$(echo $latest_workflow | jq -r '.url')
    workflow_created_at=$(echo $latest_workflow | jq -r '.created_at')
    commit_message=$(echo $latest_workflow | jq -r '.head_commit.message')
    jobs_url=$(echo $latest_workflow | jq -r '.jobs_url')

    echo "workflow url: $workflow_url, created at: $workflow_created_at"
    echo $jobs_url
}

get_latest_deploy_job () {
    local job_url
    job_url=$1

    local deploy_job
    local job_name
    local job_conclusion
    local job_id

    echo -e "Getting the latest deploy job"
    deploy_job=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" $jobs_url | jq '[.jobs[] | select(.name | ascii_downcase | contains("deploy"))][0]')
    if [ "$?" -ne 0 ]
    then
        return 1
    fi

    job_name=$(echo $deploy_job | jq -r '.name')
    job_conclusion=$(echo $deploy_job | jq -r '.conclusion')
    job_url=$(echo $deploy_job | jq -r '.url')
    job_id=$(echo $deploy_job | jq -r '.id')

    echo -e "job url: $job_url, job name: $job_name, conclusion: $job_conclusion"
    echo $job_id
}

rerun_job () {
    local job_id
    job_id=$1

    echo "Re-run job $job_id"
    curl -X POST  -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/repos/hanchiang/url-shortener-backend/actions/jobs/$job_id/rerun
    printf "\n"
}

wait_for_deploy_success () {
    jobs_url=$1

    local seconds_to_wait=180

    start=$(date +%s)
    time_elapsed=$(get_time_elapsed $start | tail -n 1)

    deploy_job=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" $jobs_url | jq '[.jobs[] | select(.name | ascii_downcase | contains("deploy"))][0]')
    job_conclusion=$(echo $deploy_job | jq -r '.conclusion')

    while [ "$job_conclusion" != "success" ] && [ "$time_elapsed" -lt "$seconds_to_wait" ];
    do
        echo -e "Getting the deploy job: $jobs_url"

        deploy_job=$(curl -H "Accept: application/vnd.github+json" -H "Authorization: token $GITHUB_TOKEN" $jobs_url | jq '[.jobs[] | select(.name | ascii_downcase | contains("deploy"))][0]')
        job_name=$(echo $deploy_job | jq -r '.name')
        job_conclusion=$(echo $deploy_job | jq -r '.conclusion')
        job_url=$(echo $deploy_job | jq -r '.url')
        job_id=$(echo $deploy_job | jq -r '.id')
        echo -e "job url: $job_url, job name: $job_name, conclusion: $job_conclusion"

        if [ "$job_conclusion" != "success" ]
        then
            echo "Latest deploy job status: $job_conclusion"
            echo "Waiting for deploy to be successful"
            echo "job url: $job_url"
            sleep 15
            time_elapsed=$(get_time_elapsed $start | tail -n 1)
        else
            echo "URL shortener deployment is successful!"
            printf "\n"
            return 0
        fi
    done
    printf "\n"
    return 1
}

# Start EC2
wait_for_ec2_stop
start_ec2

# Update route53 record
DOMAINS=("api.urlshortener.yaphc.com" "go.yaphc.com")
for domain in "${DOMAINS[@]}"
do
    ./route53/update-ec2-route53.sh $domain "UPSERT"
    wait_for_dns_propagation $domain $instance_ip_address
    printf "\n"
done

# Configure and mount EBS volume
../ansible/setup-file-system.sh $SSH_USER $SSH_PRIVATE_KEY_PATH

# Copy postgres data to volume
../ansible/copy-postgres-data.sh $SSH_USER $SSH_PRIVATE_KEY_PATH

# Configure ssl for nginx
../ansible/nginx-https.sh $SSH_USER $SSH_PRIVATE_KEY_PATH

# Rerun deploy job
jobs_url=$(get_latest_github_workflow | tail -n 1)
job_id=$(get_latest_deploy_job $jobs_url | tail -n 1)
rerun_job $job_id 

# Get deploy job status
jobs_url=$(get_latest_github_workflow | tail -n 1)
wait_for_deploy_success $jobs_url

echo "Script completed in $SECONDS seconds"
