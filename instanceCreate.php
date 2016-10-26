<?php

require 'vendor/autoload.php';

use Aws\Ec2\Ec2Client;

$ec2Client = Ec2Client::factory(array(
    'key'    => 'AKIAI5P34RQZWVFANBBQ',
    'secret' => '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',
    'region' => 'us-west-2'
));


$keyPairName = 'web_servers';

$securityGroupName = 'webServer';

// Launch an instance with the key pair and security group
$result = $ec2Client->runInstances(array(
    'ImageId'        => 'ami-b04e92d0',
    'MinCount'       => 1,
    'MaxCount'       => 1,
    'InstanceType'   => 'm1.small',
    'KeyName'        => $keyPairName,
    'SecurityGroups' => array($securityGroupName),
));


$instanceIds = $result->getPath('Instances/*/InstanceId');

