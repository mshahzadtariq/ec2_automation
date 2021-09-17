require 'aws'
require 'sinatra'

class InstanceManager
    region = 'us-east-2'
    key_pair_name = '' # AWS => Key Pairs
    security_groups = []
    client_name = ''
    account_id = 'YOUR_EC2_ACCOUNT_ID'
    ec2 = nil

    def initialize access_key='YOUR_EC2_ACCESS_KEY', secret_key='YOUR_EC2_SECRET_KEY'
        Aws.config.update({
          region: region,
          credentials: Aws::Credentials.new(access_key, secret_key)
        })

        @ec2 = Aws::EC2::Resource.new(region: region)
    end

    def get_instance_by_id id=nil
        @ec2.instances.find(instance_id: id).first
    end


    def create_instance
        image = reference_instance.create_image(name: "PROJECTInstance image for #{client_name}")

        script = ''
        encoded_script = Base64.encode64(script)


        instance = ec2.create_instances({
            image_id: image.id,
            min_count: 1,
            max_count: 1,
            key_name: key_name,
            security_group_ids: security_groups,
            user_data: encoded_script,
            instance_type: 't2.micro',
            placement: {
              availability_zone: region
            },
            subnet_id: 'SUBNET_ID',
            iam_instance_profile: {
              arn: 'arn:aws:iam::' +  + ':instance-profile/aws-opsworks-ec2-role'
            }
        })

        # Wait for the instance to be created, running, and passed status checks
        ec2.client.wait_until(:instance_status_ok, {instance_ids: [instance.first.id]})

        instance.create_tags({ tags: [{ key: 'Name', value: "PROJECT-#{client_name}" }, { key: 'Group', value: 'OSB' }]})

        return instance.id
    end
    
end
