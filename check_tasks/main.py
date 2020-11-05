# -*- coding: utf-8 -*-

import os
import re
import json
import socket
import boto3 as aws
from time import time,ctime
from hashlib import sha1

ecs = aws.client('ecs')
sns = aws.client('sns')
dynamo = aws.client('dynamodb', region_name='us-east-1')

def get_sns_topic_arn():
    return os.environ['SNS_TOPIC_ARN']

def get_dynamodb_table_name():
    return os.environ['DYNAMO_TABLE_NAME']

def check_running_tasks(clustername):
    revisions = get_task_definition_revisions()
    old_tasks = [arn.split('/')[1] for arn in get_running_tasks(clustername) if arn not in revisions]

    if len(old_tasks) > 0:
        send_notification(old_tasks)

def get_task_definition_revisions():
    paginator = ecs.get_paginator('list_task_definition_families')
    task_def_families = paginator.paginate(status='ACTIVE', PaginationConfig={'MaxItems':100})

    latest_revisions = []
    for families in task_def_families:
        for family in families['families']:
            task_def = ecs.describe_task_definition(taskDefinition=family)['taskDefinition']
            latest_revisions.append(task_def['taskDefinitionArn'])

    return latest_revisions

def get_running_tasks(clustername):
    paginator = ecs.get_paginator('list_tasks')
    running_tasks = paginator.paginate(cluster=clustername, PaginationConfig={'MaxItems':100})

    for task_arns in running_tasks:
        for task in ecs.describe_tasks(cluster=clustername, tasks=task_arns['taskArns'])['tasks']:
            yield task['taskDefinitionArn']

def send_notification(old_tasks):

    old_tasks.sort()
    detail = "\n".join(old_tasks)
    message = json.dumps({
        "time": ctime(),
        "summary": "Tasks running outdated task definitions",
        "detail": detail
    })

    if not message_was_sent(detail):
        sns.publish(
            TopicArn=get_sns_topic_arn(),
            Message=message
        )

def message_was_sent(detail):
    detail_hash = sha1(detail.encode('utf-8')).hexdigest()

    response = dynamo.get_item(
        TableName=get_dynamodb_table_name(),
        Key={
            'detail_hash': {
                'S': detail_hash
            }
        }
    )

    if not 'Item' in response:
        dynamo.put_item(
            TableName=get_dynamodb_table_name(),
            Item={
                'detail_hash': {
                    'S': detail_hash
                },
                'expires_ts': {
                    'N': str(time() + 86400)
                }
            }
        )
        return False

    return True

def record_task_counts(clustername):
    families = {}
    for task in get_running_tasks(clustername):

        family = re.search('/([^:]+):[0-9]+$', task)[1]
        if family in families:
            families[family] += 1
        else:
            families[family] = 1

    print(families)

def handle(event, context=None):
    clustername = os.environ['CLUSTER_NAME']

    check_running_tasks(clustername)
    record_task_counts(clustername)

if __name__ == '__main__':
    handle({})
