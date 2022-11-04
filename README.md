# Terraform for Nightscout running on AWS (free-tier*)

This Terraform project has been developed to deploy a Nightscout instance on AWS using free-tier resources that best replicate the operating experience of Heroku.

While every effort has been made to ensure only free-tier resources are used, this may change as Amazon adjust their offering and we take no responsibility for the services deployed to your own AWS account. You can read more about what services are offered in their [free-tier here](https://aws.amazon.com/free/).

[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](./LICENSE)

---

## Pre-build setup

### Install Terraform 
Detailed instructions on how to install Terraform can be found on their website here: [https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Prepare your nightscout repo
1. Fork the `cgm-remote-monitor` repo into your own account as per these [instructions](https://nightscout.github.io/nightscout/github/#fork-the-nightscout-project) on the official Nightscout website. 
   >If you had Nightscout running on Heroku previously, it's likely you've already done this and can skip this step.
2. Go to your forked repo in your browser (eg. `https://github.com/rajdeut/cgm-remote-monitor`)
3. Click on "*Add file*" & select "*Create new file*"
4. Enter the filename `appspec.yml`
5. Paste the following into the textbox
```
version: 0.0
os: linux
files:
    - source: /
      destination: /srv/cgm-remote-monitor
      overwrite: true

file_exists_behavior: OVERWRITE
hooks:
    AfterInstall:
        - location: ../../../../scripts/after_install.sh
          timeout: 3000
          runas: root
    ApplicationStart:
        - location: ../../../../scripts/app_start.sh
          timeout: 300
          runas: root
    ApplicationStop:
        - location: ../../../../scripts/app_stop.sh
          timeout: 300
          runas: root   
```

5. Ensure "*Commit directly to the main/master branch*" is selected and then click "*Commit new file*"

### Configure AWS
>If you're an experienced AWS and/or Terraform user you'll likely have AWS credentials & config files already on your system. If that's the case you can skip this step, however you'll need to modify the `providers.tf` file based on Terraform's AWS provider [documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs).

1. In the `config` folder, copy the file `aws-credentials.example` and rename it `aws-credentials`
2. Open the file and paste in your own *Access Key* & *Secret Access Key.*
3. In the `config` folder, copy the file `aws-config.example` and rename it `aws-config`
4. Change the region to the one closest to your home. A list of region options is available [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-regions).
	- Be sure to use the region's *Code* value
	   eg. `us-east-1` or `eu-west-1`
---
## Build infrastructure
1. Open a new terminal/shell
	- macOS - Terminal (in Applications/Utilities)
	- Linux - I doubt you're reading this, you already know what you're doing
	- Windows - Command Prompt? ¯\_(ツ)_/¯ 
2. Change into the folder where you have downloaded/cloned the Nightscout Infrastructure repo into
   eg. `cd ~/Documents/terraform-aws-nightscout`
3. Create an SSH key pair for the new server
   `ssh-keygen -f config/nightscout-ec2-key`
   *When asked for a passphrase, leave blank & press enter*
4. Initialise Terraform
   `terraform init`
5. Execute Terraform with your custom variables
   You'll need a few things handy in order to start the process. 
   - GitHub username (eg. `rajdeut`)
   - The forked GitHub repository name that's holding the Nightscout code (likely to be `cgm-remote-monitor` unless you renamed it)
   - Optionally your permanent public IP address for SSH access (eg `222.1.1.1`)

	You will always have to supply your GitHub username as follows:
	`terraform apply --var "git_owner=github_username" `

	If you have changed the name of the GitHub repo or want SSH access add them accordingly. eg.
	`terraform apply --var "git_owner=github_username" --var "git_repo=my-nightscout-repo"`
	or
	`terraform apply --var "git_owner=github_username" --var "git_repo=my-nightscout-repo" --var "my_ip=222.1.1.1"
	
	*Once executed this process can take anywhere between 2-15 minutes to complete.*
6. After running successfully the system will display the new URL that Nightscout will be available at ***after completing the remaining steps***.
   eg. `nightscount_url = "http://3.27.3.2"`

---

## Post-build steps

### Configure Nightscout
Now that the infrastructure has been setup in AWS you can setup Nightscout to your liking.
1. Open the [AWS Console](https://console.aws.amazon.com) and go to the *Systems Manager* service.
2. In the left-hand navigation select "*Parameter Store*".
3. You'll see a list of placeholder configuration options the system has created on your behalf, such as `MONGODB_URI`. **These will need to be updated with the correct values for you!** 
   From here you can either:
	1. Edit one that you already have by clicking on it and changing the value; or
	2. Create a new one by clicking on "*Create parameter*" at the top right.

A list of all of the Nightscout configuration variables and what they do can be found in the  [official Nightscout documentation](https://nightscout.github.io/nightscout/setup_variables/). 

>For `MONGODB_URI` we're assuming you have an existing database setup, likely on Mongo Atlas for free. If you haven't done this yet [instructions on how to do so are here](https://nightscout.github.io/vendors/mongodb/atlas/#create-an-atlas-database).

When creating a new configuration option, make sure that it starts with `/nightscout/` and append the configuration name you're adding. **You must have this for the option to work.**
eg. `/nightscout/BG_HIGH`

The following is an example of what the page should look like:
Name: `/nightscout/BG_HIGH`
Tier: `Standard`
Type: `String`
Data type: `text`
Value: `200`


### Connect GitHub to AWS
Now that Nightscout is configured we need to connect it to GitHub to pull your updated Nightscout code onto the server.
1. Open the [AWS Console](https://console.aws.amazon.com) and go to the *CodePipeline* service.
2. Click on *Settings* in the left hand navigation and select *Connections*.
   You should see a connection with the name `nightscout__github_connection` that has a status of "Pending"
3. Click on the connection's name to load its details.
4. At the top right will be a button labelled "*Updated pending connection"*, click on that to open a popup window. (If you have popups disabled you'll need to manually allow this in your browser when prompted)
5. In the popup window enter your GitHub username & password to log in.
6. After logging in the page will ask you to select a GitHub App, this is a confusing name, it's actually referring to your GitHub account. Just click in the box and it should load a list automatically that has your GitHub username listed. Select it and press "*Connect*".
7. The popup should now close and the status of the connection changed to "Available".

### Kick off pipeline
Now that GitHub is connected we'll kick-off the process to obtain the nightscout code and put it on the server. We only need to do this once, in the future it will be automatic.
1. Open the [AWS Console](https://console.aws.amazon.com) and go to the *CodePipeline* service.
2. Click on "*Pipelines*" in the left-hand navigation
   There should be one pipeline listed called `nightscount__pipeline` with a status of "Failed".
3. Click on the pipeline's name to load its edit page and then click the "*Retry*" button at the top right of the page.
4. The page will refresh in a couple of seconds and the "*Source*" section should now be green with a tick, it will then move onto the below "*Deploy*" stage, which will take 5-10 minutes to execute.

Your Nightscout site should now be visible if you go to the URL previously provided after running `terraform apply`

eg. `http://3.27.3.2`