add-content -path ~/.ssh/config -value @'

Host ${host}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
'@