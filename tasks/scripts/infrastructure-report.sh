#!/bin/bash

set -e

# for gcloud cli
export GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp.key.json
cat > $GOOGLE_APPLICATION_CREDENTIALS <<EOF
$GCP_JSON_KEY
EOF

# for terraform smoke
cat > ci/deployments/smoke/keys/gcp.json <<EOF
$GCP_JSON_KEY
EOF

project=$(echo $GCP_JSON_KEY | jq -r '.project_id')
gcloud auth activate-service-account --key-file $GOOGLE_APPLICATION_CREDENTIALS --project $project

# FILE=report.txt

# usage: info "msg"
info () {
  # echo "$@" > $FILE
  echo "$@"
}

# usage: warn "msg"
warn () {
  info -n "$@"
  info -e " \033[0;31m!!WARNING!!\033[0m"
}

# poke gke and figure out if the number of nodes they're reporting matches the number of vm instances using the `gke-$cluster_name-` pattern
report_vm_gke () {
  gce_gke=$(gcloud compute instances list --filter=name~gke- --format=json)
  info "$(echo $gce_gke | jq 'length') of which follow the GKE node naming scheme \"gke-\" (number reported by GCE and GKE should be the same)"
  gke=$(gcloud container clusters list --format=json)
  for cluster in $(echo $gke | jq -r '.[] | { name:.name, count:.currentNodeCount } | @json')
  do
    name=$(echo $cluster | jq -r '.name')
    gke_count=$(echo $cluster | jq '.count')
    gce_count=$(echo $gce_gke | jq --arg name "${name}" '[ .[] | select(.name | contains("gke-"+$name) )] | length')

    if [ $gke_count -ne $gce_count ]
    then
      warn "  - GKE cluster \"${name}\" reports ${gke_count} nodes and GCE reports ${gce_count} VM instances"
    else
      info "  - GKE cluster \"${name}\" reports ${gke_count} nodes and GCE reports ${gce_count} VM instances"
    fi
  done
  info ""
}

# go through all the ci/deployments/smoke workspaces and make sure there's one vm per known workspace
report_vm_tf () {
  gce_smoke=$(gcloud compute instances list --filter=name~smoke- --format=json)
  info "$(echo $gce_smoke | jq 'length') of which follow the Terraform smoke naming scheme \"smoke-\", each workspace should correspond to 1 VM"
  pushd ci/deployments/smoke > /dev/null
    terraform init > /dev/null

    # var to keep track of vms we've accounted for (any vms leftover after we've iterated through the workspaces are unaccounted for)
    unused_vms=$(echo $gce_smoke | jq '[ .[].name ]')

    workspaces=($(terraform workspace list | sed s/\*//g))
    info "  There are ${#workspaces[@]} terraform workspaces (Make sure these workspaces are all valid, they will need to be destroyed manually if they're no longer in use)"
    for w in ${workspaces[@]}
    do
      terraform workspace select $w > /dev/null
      tf_state=$(terraform show -json)

      if (echo $tf_state | jq -e '.values.root_module.resources' > /dev/null) # skip if workspace has no terraform resources (aka never ran 'terraform apply')
      then
        instance_id=$(echo $tf_state | jq -r '.values.root_module.resources[] | select(.address == "google_compute_instance.smoke") | .values.name')
        unused_vms=$(echo $unused_vms | jq --arg instance "${instance_id}" '[ .[] | select( . == $instance | not ) ]')
        info "  - $w [VM: \"${instance_id}\"]"
      else
        info "  - $w (no VM)"
      fi
    done

    # unaccounted for vms
    if [[ $(echo $unused_vms | jq -r 'length') != "0" ]]
    then
      info ""
      warn "  There are some VMs that fit the Terraform smoke naming scheme but are not associated to a workspace (These VMs probably shouldn't exist and needs to be deleted manually)"
      info $unused_vms | jq -r '.[] | "    - " + .'
    fi
  popd > /dev/null
  info ""
}

report_vm_bosh () {
  gce_bosh=$(gcloud compute instances list --filter=name~vm- --format=json)
  info "$(echo $gce_bosh | jq 'length') of which follow the BOSH naming scheme \"vm-\""

  # Topgun BOSH environment
  topgun_director="bosh-bbl-env-caspian-2021-10-07t03-59z" # hard coded for now
  gce_topgun_bosh=$(echo $gce_bosh | jq --arg director $topgun_director '[ .[] | select (.labels.director ==  $director) ]')

  # unknown_vms=$(echo $gce_bosh | jq '[ .[].name ]')
  unknown_vms=$gce_bosh

  gsutil -m cp -r gs://bosh-topgun-bbl-state/ . > /dev/null 2>&1
  pushd bosh-topgun-bbl-state > /dev/null
    eval "$(bbl print-env)"
    topgun_vms=$(bosh vms --json | jq '[ .Tables[].Rows[].vm_cid ]')
    info "  There are $(echo $topgun_vms | jq 'length') VMs managed by the Topgun BOSH director ($topgun_director) and GCE reports $(echo $gce_topgun_bosh | jq 'length') VM instances"
    info ""
    echo "$topgun_vms" > /tmp/topgun_vms
    unknown_vms=$(echo $unknown_vms | jq --slurpfile used /tmp/topgun_vms '[ .[] | select( [.name] | inside($used) | not) ]')
  popd > /dev/null

  # BOSH director and jumpbox vms
  toplevel_vms=$(echo $unknown_vms | jq '[ .[] | select( .labels.director == "bosh-init" ) ]')
  info "  There are $(echo $toplevel_vms | jq 'length') top level VMs, i.e. BOSH directors and jumpboxes (There should only really be one environment, \"$topgun_director\" which is used for Topgun. Any others should be investigated)"
  info $toplevel_vms | jq -r '.[] | "  - " + .name + " [type: " + .labels.name + ", tags: " + ( .tags.items | join(",") ) + "]"'
  info ""
  echo "$toplevel_vms" > /tmp/toplevel_vms
  unknown_vms=$(echo $unknown_vms | jq --slurpfile used /tmp/toplevel_vms '. - $used')

  # unknown BOSH directors
  vms_with_unknown_directors=$(echo $unknown_vms | jq '[ .[] | select( .labels.director != null ) ]')
  vms_with_unknown_directors_count=$(echo $vms_with_unknown_directors | jq 'length')
  if [ $vms_with_unknown_directors_count -ne 0 ]
  then
    warn "  There are ${vms_with_unknown_directors_count} VMs managed by other BOSH directors (Any non-Topgun environment needs to be investigated to see why they exist. Note: Topgun VMs might show up here if they're deleted recently, you can ignore any that has $topgun_director as the director)"
    info $vms_with_unknown_directors | jq -r '.[] | "  - " + .name + " [director: " + .labels.director + "]"'
    info ""
    echo "$vms_with_unknown_directors" > /tmp/vms_with_unknown_directors
    unknown_vms=$(echo $unknown_vms | jq --slurpfile used /tmp/vms_with_unknown_directors '. - $used')
  fi

  # unknown BOSH vms
  unknown_vms_count=$(echo $unknown_vms | jq 'length')
  if [ $unknown_vms_count -ne 0 ]
  then
    warn "  There are $(echo $unknown_vms | jq 'length') VMs that follow the BOSH naming scheme but does not fit into any of the previous groups. (These can almost always be safely deleted)"
    info $unknown_vms | jq -r '.[] | "  - " + .name'
    info ""
  fi
}

report_vms () {
  gce=$(gcloud compute instances list --format=json)
  info "Total of $(echo $gce | jq 'length') VM instances"

  report_vm_gke
  report_vm_tf
  report_vm_bosh

  # unknown vms, some of this, like `nats` and `ci-windows-worker` has legit use cases
  unknowns=$(echo $gce | jq -r ' [ .[] | select( ((.name|contains("gke-")) or (.name|contains("smoke")) or (.name|contains("vm-"))) | not ) ]')
  unknowns_count=$(echo $unknowns | jq 'length')
  if [ $unknowns_count -ne 0 ]
  then
    warn "$(echo $unknowns | jq 'length') of which do not match any naming schemes (Investigate and figure out if they have a legitimate use case and update this script it does)"
    info $unknowns | jq -r '.[] | "  - " + .name'
    info "  VMs with legitimate use:"
    info "  - nat: used by BOSH VMs to access the external internet. Otherwise each BOSH VM will require an external IP"
    info "  - windows-worker-ci: Windows worker for ci.concourse-ci.org"
  fi
}


# gke disks is the sum of number of nodes (each nodes gets a disk) and the number of pvcs in that cluster
report_disks_gke () {
  gce=$1
  unused_disks=$(echo $gce | jq -r ' [ .[] | select( .name | contains("gke-") )]')
  info "$(echo $unused_disks | jq 'length') of which follow the GKE node naming scheme \"gke-\" (number reported by GCE and GKE should be the same)"

  gke=$(gcloud container clusters list --format=json)
  for cluster in $(echo $gke | jq -r '.[] | { name:.name, count:.currentNodeCount, zone: .zone } | @json')
  do
    name=$(echo $cluster | jq -r '.name')
    zone=$(echo $cluster | jq -r '.zone')
    gce_disks=$(echo $gce | jq -r --arg cluster $name '[ .[] | select( .name | contains("gke-"+$cluster))]')
    gce_count=$(echo $gce_disks | jq 'length')

    # var to keep track of disks that doesn't belong to any active cluster
    unused_disks=$(echo $unused_disks | jq --arg cluster $name '[ .[] | select(.name | contains("gke-"+$cluster) | not) ]')

    gcloud container clusters get-credentials --zone $zone $name> /dev/null 2>&1
    pvs=$(kubectl get pv --all-namespaces --output=json | jq '.items')

    nodes_count=$(echo $cluster | jq -r '.count')
    pv_count=$(echo $pvs | jq 'length')
    gke_count=$(($nodes_count + $pv_count))

    if [ $gke_count -ne $gce_count ]
    then
      warn "  - GKE ${name} cluster has ${nodes_count} nodes + ${pv_count} PVs = ${gke_count} disks, but GCE reported ${gce_count} persistant disks (This will require some manual investigation)"

      # XXX: we're making a somewhat ballsy assumption that the diff will be in the persistent volume count
      # it kinda makes logical sense the number of nodes should equal number of node disks (since it's created/destroyed by google), but this can come back to bite us
      # it also assumes the real count will always be higher than the expected count (since it's gke that creates these, it should never fail to create disks)
      info "    Assuming the difference is in the PV count, these disks are found in GCE but not in the GKE PVs list:"
      pv_disks=$(echo $pvs | jq '[ .[].spec.gcePersistentDisk.pdName ]')
      unused_pvs=$gce_disks
      unused_pvs=$(echo $unused_pvs | jq '[ .[] | select(.labels."goog-gke-node" == null ) ]') # filter out node disks
      echo "$pv_disks" > /tmp/pv_disks
      unused_pvs=$(echo $unused_pvs | jq --slurpfile used /tmp/pv_disks '[ .[] | select( [.name] | inside($used) | not) ]') # filter out pv disks
      info $unused_pvs | jq -r '.[] | "    * " + .name'
    else
      info "  - GKE ${name} cluster has ${nodes_count} nodes + ${pv_count} PVs = ${gke_count} disks, and GCE reported ${gce_count} persistant disks"
    fi
  done
  info ""

  unused_disk_count=$(echo $unused_disks | jq 'length')
  if [ $unused_disk_count -ne 0 ]
  then
    warn "  There are $(echo $unused_disks | jq 'length') disks were used by clusters that no longer exist. (These can almost always be safely deleted if the cluster is truly gone)"
    info $unused_disks | jq -r '.[] | "  - " + .name'
  fi
  info ""
}

# terraform smoke should create a disk for every vm
report_disks_tf () {
  gce=$1
  gce_smoke=$(echo $gce | jq ' [ .[] | select( .name | contains("smoke-") ) ]')
  info "$(echo $gce_smoke | jq 'length') of which follow the Terraform smoke naming scheme \"smoke-\" (please see the Terraform VM section as each VM equates to 1 disk)"

  unused_disks=$(echo $gce_smoke | jq '[ .[] | select( (.users | length) == 0 ) ]')
  unused_disk_count=$(echo $unused_disks | jq 'length')
  if [ $unused_disk_count -eq 0 ]
  then
    info "  All disks are accounted for (they're in use by a VM)"
  else
    warn "  Some disks are not in use by a VM (usually means they're safe to delete)"
    info $unused_disks | jq -r '.[] | "  - " + .name'
  fi
  info ""

}

# can't really do much with BOSH disks since the CLI doesn't expose much info
# best we can do is to make sure every disk is in use
report_disks_bosh () {
  gce=$1
  gce_bosh=$(echo $gce | jq ' [ .[] | select( (.name | contains("vm-")) or (.name | contains("disk-")) ) ]')
  info "$(echo $gce_bosh | jq 'length') of which follow the BOSH naming scheme \"disk-\" or \"vm-\""

  unused_disks=$(echo $gce_bosh | jq '[ .[] | select( (.users | length) == 0 ) ]')
  unused_disk_count=$(echo $unused_disks | jq 'length')
  if [ $unused_disk_count -eq 0 ]
  then
    info "  All disks are accounted for (they're in use by a VM)"
  else
    warn "  Some disks are not in use by a VM (usually means they're safe to delete)"
    info $unused_disks | jq -r '.[] | "  - " + .name'
  fi
  info ""
}

report_disks () {
  gce=$(gcloud compute disks list --format=json)
  info "Total of $(echo $gce | jq 'length') disks"

  report_disks_gke "$gce"
  report_disks_tf "$gce"
  report_disks_bosh "$gce"

  # unknown disks
  unknowns=$(echo $gce | jq -r ' [ .[] | select( ((.name|contains("gke-")) or (.name|contains("smoke")) or (.name|contains("vm-")) or (.name|contains("disk-")) ) | not ) ]')
  unknowns_count=$(echo $unknowns | jq 'length')
  if [ $unknowns_count -ne 0 ]
  then
    warn "$(echo $unknowns | jq 'length') of which do not match any naming schemes (These should correspond to unknown VMs in the previous section, otherwise investigation will be needed)"
    info $unknowns | jq -r '.[] | "  - " + .name'
  fi
}

report_vms
info ""
info ""
report_disks
