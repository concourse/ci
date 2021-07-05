#!/bin/bash

set -e

# authenticate us to upload to GCS bucket
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp.key.json
cat > $GOOGLE_APPLICATION_CREDENTIALS <<EOF
$GCP_JSON_KEY
EOF

gcloud init > /dev/null 2>&1

FILE=report.txt
log () {
  echo "$@" > $FILE
}

report_vms () {
  gce=$(gcloud compute instances list --format=json)
  log "Total of $(echo $gce | jq 'length') VM instances"

  gce_gke=$(echo $gce | jq -r ' [ .[] | select( .name | contains("gke-") )]')
  log "$(echo $gce_gke | jq 'length') of which follow the GKE node naming scheme \"gke-\" (number reported by GCE and GKE should be the same)"
  gke=$(gcloud container clusters list --format=json)
  for cluster in $(echo $gke | jq -r '.[] | { name:.name, count:.currentNodeCount } | @json')
  do
    name=$(echo $cluster | jq -r '.name')
    gke_count=$(echo $cluster | jq '.count')
    gce_count=$(echo $gce | jq --arg name "${name}" '[ .[] | select(.name | contains("gke-"+$name) )] | length')
    log -n "  - GKE cluster \"${name}\" reports ${gke_count} nodes and GCE reports ${gce_count} VM instances"

    if [ $gke_count -ne $gce_count ]
    then
      log " WARNING"
    else
      log ""
    fi
  done
  log ""


  gce_smoke=$(echo $gce | jq ' [ .[] | select( .name | contains("smoke-") ) ]')
  log "$(echo $gce_smoke | jq 'length') of which follow the Terraform smoke naming scheme \"smoke-\" (each workspace should correspond to 1 VM)"
  pushd ci/deployments/smoke > /dev/null
    terraform init > /dev/null
    workspaces=($(terraform workspace list | sed s/\*//g))
    log "  There are ${#workspaces[@]} terraform workspaces. They will need to be deleted manually if they're no longer being used"
    smoke_vms=$(echo $gce_smoke | jq '[ .[].name ]')
    for w in ${workspaces[@]}
    do
      terraform workspace select $w > /dev/null
      tf_state=$(terraform show -json)
      if (echo $tf_state | jq -e '.values.root_module.resources' > /dev/null)
      then
        instance_id=$(echo $tf_state | jq -r '.values.root_module.resources[] | select(.address == "google_compute_instance.smoke") | .values.name')
        smoke_vms=$(echo $smoke_vms | jq --arg instance "${instance_id}" '[ .[] | select( . == $instance | not ) ]')
        log "  - $w (VM: \"${instance_id}\")"
      else
        log "  - $w (no VM)"
      fi
    done

    if [[ $(echo $smoke_vms | jq -r 'length') != "0" ]]
    then
      log ""
      log "  There are some VMs that fit the Terraform smoke naming scheme but are not associated to a workspace:"
      log $smoke_vms | jq -r '.[] | "    - " + .'
    fi
  popd > /dev/null
  log ""


  log "$(echo $gce | jq ' [ .[] | select( .name | contains("vm-") )] | length') of which follow the BOSH naming scheme \"vm-\""
  # pushd prod/bosh-topgun-bbl-state > /dev/null
  #   eval "$(bbl print-env)"

  # popd > /dev/null
  log ""


  unknowns=$(echo $gce | jq -r ' [ .[] | select( ((.name|contains("gke-")) or (.name|contains("smoke")) or (.name|contains("vm-"))) | not ) ]')
  log "$(echo $unknowns | jq 'length') of which do not match any naming schemes"
  log $unknowns | jq -r '.[] | "  - " + .name'
}


report_disks () {
  gce_disks=$(gcloud compute disks list --format=json)
  log "Total of $(echo $gce_disks | jq 'length') disks"

  unused_disks=$(echo $gce_disks | jq -r ' [ .[] | select( .name | contains("gke-") )]')
  log "$(echo $unused_disks | jq 'length') of which follow the GKE node naming scheme \"gke-\" (number reported by GCE and GKE should be the same)"
  gke=$(gcloud container clusters list --format=json)

  for cluster in $(echo $gke | jq -r '.[] | { name:.name, count:.currentNodeCount } | @json')
  do
    name=$(echo $cluster | jq -r '.name')
    nodes=$(echo $cluster | jq -r '.count')
    gcloud container clusters get-credentials $name > /dev/null 2>&1

    gce_count=$(echo $gce_disks | jq -r --arg cluster $name '[ .[] | select( .name | contains("gke-"+$cluster))] | length')
    pvcs=$(kubectl get pvc --all-namespaces --output=json | jq '.items | length')

    unused_disks=$(echo $unused_disks | jq --arg cluster $name '[ .[] | select(.name | contains("gke-"+$cluster) | not) ]')
    gke_count=$(($nodes + $pvcs))

    log -n "  - GKE ${name} cluster has ${nodes} nodes ${pvcs} pvcs for a total of ${gke_count} disks, and GCE reported ${gce_count} persistant disks"

    if [ $gke_count -ne $gce_count ]
    then
      log " !!WARNING!!"
    else
      log ""
    fi
  done
  log ""
  log "  There are $(echo $unused_disks | jq 'length') disks were used by clusters that no longer exist:"
  log $unused_disks | jq -r '.[] | "  - " + .name'
  log ""


  gce_smoke=$(echo $gce | jq ' [ .[] | select( .name | contains("smoke-") ) ]')
  log "$(echo $gce_smoke | jq 'length') of which follow the Terraform smoke naming scheme \"smoke-\" (please see the Terraform VM section as each VM equates to 1 disk)"
}

report_vms
log ""
log ""
report_disks
