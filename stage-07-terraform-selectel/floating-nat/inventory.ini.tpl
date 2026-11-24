[k3s_cluster:children]
master
workers

[master]
${master_ip} ansible_user=root ansible_ssh_private_key_file=${ssh_private_key}

[workers]
${worker1_ip} ansible_user=root ansible_ssh_private_key_file=${ssh_private_key}
${worker2_ip} ansible_user=root ansible_ssh_private_key_file=${ssh_private_key}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
