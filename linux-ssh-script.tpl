cat << EOF >> ~/.ssh/config

Host ${host}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
EOF