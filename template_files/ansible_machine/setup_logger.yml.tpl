---
- name: Setup timestamp logger with systemd timer
  hosts: runners
  become: yes
  
  tasks:
    - name: Copy logging script from Ansible control node
      copy:
        src: ~/testing_script_file.sh
        dest: /usr/local/bin/log_with_timestamp.sh
        mode: '0755'
        owner: root
        group: root
    
    - name: Create log file with proper permissions
      file:
        path: /var/log/timestamp_log.log
        state: touch
        mode: '0644'
        owner: root
        group: root
    
    - name: Create systemd service
      copy:
        dest: /etc/systemd/system/timestamp-logger.service
        content: |
          [Unit]
          Description=Timestamp Logger Service
          
          [Service]
          Type=oneshot
          ExecStart=/usr/local/bin/log_with_timestamp.sh
          
          [Install]
          WantedBy=multi-user.target
        mode: '0644'
    
    - name: Create systemd timer
      copy:
        dest: /etc/systemd/system/timestamp-logger.timer
        content: |
          [Unit]
          Description=Run timestamp logger every 5 seconds
          
          [Timer]
          OnBootSec=5sec
          OnUnitActiveSec=5sec
          
          [Install]
          WantedBy=timers.target
        mode: '0644'
    
    - name: Reload systemd daemon
      systemd:
        daemon_reload: yes
    
    - name: Enable and start the timer
      systemd:
        name: timestamp-logger.timer
        enabled: yes
        state: started