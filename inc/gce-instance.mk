.PHONY: gce-keys
gce-keys: # https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys#project-wide
	@#gcloud compute project-info describe > .tmp/bu_project.yml
	@#grep -oP '(gmack:|core:|grantmacken:).+$$' .tmp/project.yml > .tmp/project.txt
	@gcloud compute project-info add-metadata --metadata-from-file ssh-keys=.tmp/project.txt

PHONEY: gce-instance-info
gce-instance-info: 
	gcloud config get-value compute/zone
	gcloud config get-value compute/region

PHONEY: gce-instance-create
gce-instance-create: 
		@gcloud compute instances create $(GCE_INSTANCE_NAME) \
			--image-project=fedora-coreos-cloud \
			--image-family=$(GCE_IMAGE_FAMILY) \
			--machine-type=$(GCE_MACHINE_TYPE)
		@gcloud compute instances list
		@#gcloud compute project-info describe

PHONEY: gce-instance-delete
gce-instance-delete: 
		@gcloud compute instances delete $(GCE_INSTANCE_NAME)
		@gcloud compute instances list

