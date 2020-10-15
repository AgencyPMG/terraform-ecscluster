"""
ECS Instance Health
~~~~~~~~~~~~~~~~~~~

It's not uncoming for the ECS service to "loose touch" with an EC2 instance. When
that happens ECS can't place tasks, but the auto scaling group still views the
instance as healthy and doesn't remove it.

This fixes that problem. It looks up container instances and if the agent is no
longer connected marks them as unhealthy.
"""

import logging
import os
import boto3 as aws
import pprint


def create_default_logger():
    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    return logger


class EcsInstanceHealth(object):
    _logger = None

    #: An AWS session object.
    _session = None

    def __init__(self, logger=None, session=None):
        self._logger = logger or create_default_logger()
        self._session = session or aws.Session()


    def __call__(self, cluster):
        unhealthy = list(filter(lambda i: self._is_unhealthy(i), self._find_instances(cluster)))
        pprint.pprint(unhealthy)
        if not unhealthy:
            return self._logger.info('No unhealthy instances found')

        autos = self._session.client('autoscaling')
        for uh in unhealthy:
            uhid = uh['ec2InstanceId']
            self._logger.info('marking %s as unhealthy', uhid)
            try:
                autos.set_instance_health(
                    InstanceId=uhid,
                    HealthStatus='Unhealthy',
                    ShouldRespectGracePeriod=False
                )
            except Exception as e:
                self._logger.exception(e)

    def _find_instances(self, cluster):
        ecs = self._session.client('ecs')
        ids = ecs.list_container_instances(cluster=cluster, maxResults=100)
        resp = ecs.describe_container_instances(
            cluster=cluster,
            containerInstances=ids['containerInstanceArns']
        )

        return resp['containerInstances']

    def _is_unhealthy(self, instance):
        """
        Any instance not in an `ACTIVE` state isn't eligible to be unhealthy.

        Otherwise our health check depends on if the agent is connected.
        """
        if 'ACTIVE' != instance['status']:
            return False

        return not instance['agentConnected']


def handle(event, context=None):
    logger = create_default_logger()
    ecscheck = EcsInstanceHealth(logger=logger)
    try:
        ecscheck(os.environ['CLUSTER_NAME'])
    except Exception as e:
        logger.exception(e)
    finally:
        logging.shutdown()


if __name__ == '__main__':
    handle({})
