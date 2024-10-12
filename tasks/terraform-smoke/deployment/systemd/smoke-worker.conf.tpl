[Service]
Environment=CONCOURSE_WORK_DIR=/etc/concourse/work-dir
Environment=CONCOURSE_TSA_PUBLIC_KEY=/etc/concourse/host_key.pub
Environment=CONCOURSE_TSA_WORKER_PRIVATE_KEY=/etc/concourse/worker_key
%{ if runtime == "containerd" ~}
Environment=CONCOURSE_RUNTIME=containerd
Environment=CONCOURSE_CONTAINERD_DNS_SERVER=8.8.8.8,4.4.4.4
%{ else ~}
Environment=CONCOURSE_RUNTIME=guardian
Environment=CONCOURSE_GARDEN_CONFIG=/etc/concourse/garden.ini
%{ endif ~}
