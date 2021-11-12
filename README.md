# Tallinn Temperature displaying project

I have used :
   1) terraform cmdline tool version 0.14.11
   2) azure-cli version 2.30 
   3) python  version 3.8.2
   4) promtheus latest docker-image
   5) grafana latest docker-image
   6) existing Azure account and subscription(s) with privileges to create VM's and azure location that would support ubuntu 20_04-lts-gen2 image

Probably some components newer version(s) would work with my project here aswell.

After you have pulled the source from current repo, take a look at the parameters configuration-file "terraform/variables.tf".
In there, you should set your desired:
     1) Azure resource group (terraform will create it aswell), 
     2) resource group location
     3) VM-name 
     4) ubuntu minor version, or you could leave those all as they are.

Then you should (using powershell or bash) cd to "terraform" and execute those steps:

1) az login
//since the tenamt, i have logged into, had many subscriptions attached, now needed to set appropriate one: 
2) az account set --subscription "<my_subscription_name>"
3) terraform init
// could skip this step, if no changes made to main.tf 
4) terraform fmt
5) terraform validate
// this is the main operation
6) terraform apply

In the end of the apply-process, you should see something like that
------------------------------------------
Outputs:

new_VM_IP = "<new_ip>" 
-----------------------------------------
Then head to your favourite browser and with that ip:  168.63.**.**:3000 you should see a grafana login-interface, the default username/password there 
are "admin/admin", then it prompts you to change the password to something more secure.
Now, at the left-pane of the grafana-interface, choose "Dashboards > Manage".
There you should see dashboard named "PreProvisionedDash", after opening it, you should see graph "Tallinn temperature" where some data is already trickling in and drawing lines.  


Few shortcomings of the project created and things should re-consider:
   1) i was not able to configure grafana in a way, that it would not need an public IP and portprometheus interface, something like localhost:9090.
      Instead, i have used the public ip there
   2) maybe api-key would not been so publicly available at the python3 conf 
   3) maybe would noy need an empty "new_vm.pem" file there, but since "terraform validate" gave an error for this private-key file still not there (before APPLY step)
   4) maybe not use python here at all ?  Since im not fully aware of all Prometheus possibilities or how/if it could make reequest to some weather-API itself?
