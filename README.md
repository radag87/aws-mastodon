# aws-mastodon

WIP mastodon running on aws serverless

## about me

* I know AWS. In my opinion, I have a working knowlege of AWS. I am not an "expert".
* I am not an employee of Amazon.com or AWS.
* I am not looking for a job. There are other folks out there who are, seek them out. If this ever changes, I will update this bullet point.
* I do not know Azure or Google Cloud Plaform. If you do and want to translate into those plafoms, feel free. You won't hurt my feelings. I know there are other cloud platforms out there, but I only have a little free time.
* I don't know mastodon. I did not even know about mastodon before my wife said she wanted to look into standing up a mastodon site. If you have issues about why mastodon behaves a certain way, then find someone who knows mastodon.
* I don't know ruby. See mastodon bullet point.
* I did not make this terraform template to please anyone other than my wife. If you have recommendations, or notice issues, feel free to bring them up. github lets anyone create an issue. I may work on it, or a may choose to ignore it. github lets anyone ignore issues.
* There are many ways to drive down costs. This template is not one of them. Review the toggles to see what can be turned off to save money. I made this template with the focus on having AWS be your "IT resource". Everything that can be serverless is. If you have an IT resource, then spend money on him/her/them. Bezos is rich enough.
* I am what can be charitably be described as a curmudgeon. However, I love my wife. And she wants a mastodon site. So...

## windows

I have managed to avoid using a Windows computer since Windows XP. That means that all of my examples are meant to be run from bash. If you have a Windows machine with WSL, you may be sucessful using this Terraform. Otherwise feel free to invest some time in figuring out what the equivalent Windows commands are to achive the same result.

## pre work

### get an aws account

1. [get an aws account] (<https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/>)
1. [get the aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
1. [configure aws credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
1. test your access - If you can run this command `aws account get-contact-information` and get back familiar information, then you have cleared the first hurdle.

### get and configure Terraform

1. [get terraform](https://developer.hashicorp.com/terraform/downloads)
1. test your install - If you can run this command `terraform --version` and get back a valid response, then you have cleared the second hurdle.

### set up your domain

1. [register a .social domain](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-register.html#domain-register-procedure) - this will cost 32USD per year
    * **NOTE** If you have a domain already, then [migrate DNS to AWS](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html). If you do not, then this module may not be for you.
1. [enable dnssec in the Route53 hosted zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec.html) record. This step requires the purchase of a [Customer Managed Key](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/dns-configuring-dnssec-cmk-requirements.html) that costs 1 USD per month
1. test your domain - If you can run this command `dig -t SOA mydomain.social` where mydomain.social is replaced with your domain and get back reasonable results, then you have cleared the third hurdle.

## work

### set up workspace

Now that the prework is done, you are ready to create your environment.

create a folder

```bash
mkdir -p ~/myapp
cd ~/myapp

```

## resources

* s3 bucket
* s3 log bucket
* efs
* rds postgres

## toggles

| variable              | description                                    | default |
|-----------------------|------------------------------------------------|---------|
| enable_bucket_logging | create an s3 bucket to log access to s3 bucket | true    |
