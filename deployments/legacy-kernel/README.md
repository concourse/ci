# Deploy a VM on GCP with Legacy Kernel

The idea is to use [packer](http://packer.io) to create an image based on legacy linux kernel and then use terraform to create a VM based on that image.

Step 1: Prepare kernel files

Download kernel files of desired version from [Ubuntu kernal mainline](https://kernel.ubuntu.com/~kernel-ppa/mainline). For example, kernel 4.4 needs headers-\*-generic, headers-\*-all, image-unsigned-\* and modules-\*-generic. Rename downloaded files to match the file names listed as `"type": "file"` in `packer.json`, respectively.

Step 2: Create the GCP compute engine image by running
```sh
packer build -var region="us-west1" -var machine_type="n1-standard-1" -var zone="us-west1-b" -var project_id="cf-concourse-production" -force packer.json
```
note:
Follow [how to authenticate packer with Google Cloud](https://www.packer.io/docs/builders/googlecompute#precedence-of-authentication-methods) to login GCP by `gcloud auth application-default login` and set the env var `GOOGLE_APPLICATION_CREDENTIALS` to the file path first.

Step 3: Create the VM
```sh
terraform apply
```

Step 4: Verify the VM with name `terraform-instance` is created and can be connected via SSH
```sh
gcloud beta compute ssh --zone "us-central1-c" "terraform-instance" --project "cf-concourse-production"
```

Step 5: Verify the VM is running with the desired kernel version
```sh
uname -a
```

