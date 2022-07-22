#!/bin/bash

#### Create file system on secondary volume, mount it to local directory

file_system=$(lsblk -f | grep xvdf | awk '{print $2}')
if [ -n "$file_system" ]
then
  echo "Disk is already formatted."
  exit 0
fi

sudo mkfs -t ext4 $EBS_DEVICE_PATH
sudo mkdir $FS_MOUNT_PATH

sudo mount $EBS_DEVICE_PATH $FS_MOUNT_PATH

sudo cp /etc/fstab /etc/fstab.orig

# Automatically mount an attached volume after reboot
uuid=$(sudo blkid $EBS_DEVICE_PATH -s UUID -o value)
echo "UUID=$uuid  $FS_MOUNT_PATH  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab > /dev/null

# Verify
sudo umount $FS_MOUNT_PATH
sudo mount -a

sudo file -s $EBS_DEVICE_PATH
sudo lsblk -f
df -h



cat <<EOF | sudo tee -a /etc/postgres/13/main/conf.d/postgresql.conf > /dev/null 
#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------
data_directory = '{{ FS_MOUNT_PATH }}/postgres/data'

#------------------------------------------------------------------------------
# REPORTING AND LOGGING
#------------------------------------------------------------------------------
# - Where to Log -
log_destination = 'stderr'

logging_collector = on

log_directory = 'log'

log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'

log_file_mode = 0600

log_rotation_age = 1d

log_rotation_size = 10MB

# - When to Log -
log_min_messages = warning
log_min_error_statement = error
log_min_duration_sample = 100
log_statement_sample_rate = 0.5

# - What to Log -
log_duration = on
log_line_prefix = '%m [%p] [%d] %u %a'
EOF

sudo mkdir /lib/systemd/system/postgresql.service.d
cat <<EOF | sudo tee -a /lib/systemd/system/postgresql.service.d/postgres.conf > /dev/null
[Service]
Environment=PGDATA={{ FS_MOUNT_PATH }}/postgres/data
EOF

sudo systemctl daemon-reload
sudo systemctl restart postgresql.service