#!/bin/bash

# --- VARIABLES --- #

# Creates DESKTOP containing the current desktop environment 
if [ "$XDG_CURRENT_DESKTOP" = "" ]
then
  DESKTOP=$(echo "$XDG_DATA_DIRS" | sed 's/.*\(xfce\|kde\|gnome\).*/\1/')
else
  DESKTOP=$XDG_CURRENT_DESKTOP
fi
DESKTOP=${DESKTOP,,}

# Date and time
TIME=$(date +"%H:%M:%S")

# System information
USER=$(whoami)
HOST=$(hostname)
OS=$(grep 'PRETTY_NAME' < /etc/os-release | sed 's/"//g' | sed 's/PRETTY_NAME=//')
KERNEL=$(uname -r)
UP=$(uptime -p)
SHELL=$0

# --- FUNCTIONS --- #

# prints home directory file tree
function home_tree {
  find /home -print | sed -e "s;/home;\.;g;s;[^/]*\/;|__;g;s;__|; |;g"
}

# sudoers files
function sudoers {
  echo "/etc/sudoers"
  grep -v '#' /etc/sudoers | awk 'NF'
  if [ -d /etc/sudoers.d ]; then
    for file in /etc/sudoers.d/*; do
      echo "$file"
      grep -v '#' $file | awk 'NF'
    done
  fi
} 

# Lists services on systems with systemd or Upstart
function services {
  if hash systemctl 2>/dev/null; then
    systemctl -r --type service --all
  elif hash service 2>/dev/null; then
    service --status-all
  else
    echo "rosefish is not compatible with your init system"
  fi
}

# Lists mediafiles
function mediafiles {  
  find / -type f \( -iname "*.jpeg" -o -iname "*.jpg" -o -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.flv" -o -iname "*.vob" -o -iname "*.omv" -o -iname "*.ogg" -o -iname "*.drc" -o -iname "*.gif" -o -iname "*.gifv" -o -iname "*.mng" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.qt" -o -iname "*.wmv" -o -iname "*.yuh" -o -iname "*.rm" -o -iname "*.rmvb" -o -iname "*.asf" -o -iname "*.amv" -o -iname "*.mp4" -o -iname "*.m4p" -o -iname "*.m4v" -o -iname "*.mpg" -o -iname "*.m4v" -o -iname "*.mpg" -o -iname "*.mp2" -o -iname "*.mpeg" -o -iname "*.mpe" -o -iname "*.mpv" -o -iname "*.m2v" -o -iname "*.svi" -o -iname "*.3gp" -o -iname "*.3g2" -o -iname "*.mxf" -o -iname "*.roq" -o -iname "*.nsv" -o -iname "*.flv" -o -iname "*.f4p" -o -iname "*.f4a" -o -iname "*.f4b" -o -iname "*.aif" -o -iname "*.iff" -o -iname "*.m3u" -o -iname "*.m4a" -o -iname "*.mid" -o -iname "*.mp3" -o -iname "*.mpa" -o -iname "*.wav" -o -iname "*.wma" -o -iname "*.bmp" -o -iname "*.dds" -o -iname "*.jpg" -o -iname "*.png" -o -iname "*.psd" -o -iname "*.pspimage" -o -iname "*.tga" -o -iname "*.thm" -o -iname "*.tif" -o -iname "*.tiff" -o -iname "*.yuv" -o -iname "*.flac" \) 2>/dev/null | grep -v "^/usr" | grep -v "^/var"
}

# Lists crontabs
function crontabs {
  # user crontabs
  cut -f1 -d: /etc/passwd | while read -r user; do
    if [[ $(crontab -u $user -l) ]]; then
      echo "<bold>$user:</bold>"
      crontab -u $user -l
    fi
  done

  # jobs from /etc/crontab
  echo "<bold>/etc/crontab:</bold>"
  cat /etc/crontab

  # Daily cronjobs
  if [ -d /etc/cron.daily ]; then
    echo "<bold>Daily Jobs:</bold>"
    cat /etc/cron.daily/*
  fi

  # Weekly cronjobs
  if [ -d /etc/cron.weekly ]; then
    echo "<bold>Weekly Jobs:</bold>"
    cat /etc/cron.weekly/*
  fi

  # Monthly cronjobs
  if [ -d /etc/cron.monthly ]; then
    echo "<bold>Monthly Jobs:</bold>"
    cat /etc/cron.monthly/*
  fi

  # package specific cronjobs
  if [ -d /etc/cron.d/ ]; then
    for file in /etc/cron.d/*; do
      echo "<bold>$file:</bold>"
      cat $file
    done
  fi
}

# /etc/passwd file
function users {
  cat /etc/passwd
}

# /etc/group file
function groups {
  cat /etc/group
}

# Processes
function processes {
  ps aux
}

# Apt history
function apt_history {
  if [ -f /var/log/apt/history.log ]; then
    cat /var/log/apt/history.log
  fi
}

# Dpkg history
function dpkg_history {
  if [ -f /var/log/dpkg.log* ]; then
    grep 'install ' /var/log/dpkg.log* | sort | cut -f1,2,4 -d' '
  fi
}

# Package list
function package_list {
  if hash dpkg-query 2>/dev/null; then
    dpkg-query -l
  fi
}

# Scans ports
function port_scanner {
  if hash netstat 2>/dev/null; then
    netstat -tulpn
  else
    echo "net-tools not installed (apt intall net-tools)"
  fi
  if hash nmap 2>/dev/null; then
    echo "****REMOVE NMAP AFTER SCANNING****"
    nmap -sT -O localhost
  else
    echo "nmap not installed (apt install nmap)"
  fi
}

# Firewall information
function firewall {
  if hash ufw 2>/dev/null; then
    ufw status verbose
  else
    echo "ufw not isntalled (apt install ufw)"
  fi
}

# --- HTML PRINT --- #
cat << _EOF_ > ./audit.html
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <link rel="icon" type="image/png" href="./favicon.png"/>
  <link rel="stylesheet" type="text/css" href="./main.css" media="screen">
  <title>System Audit</title>
</head>
<body>
  <!-- HEADER-->
  <div id="header">
    <pre>
<a class=title name="top">System Audit</a>
  <a class="subtitle">Page created $TIME</a>
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	</pre>
  </div>

  
<!--ACTUAL CONTENTS-->
  <div id="main">

  
<!--SYSTEM INFORMATION-->
<pre>
$USER@$HOST
OS: $OS
Kernel: $KERNEL
Uptime: $UP
Shell: $SHELL
DE: $DESKTOP
</pre>


<!--AUTOMATICALLY PLACES FUNCTION OUTPUT-->
$(for func in sudoers services mediafiles home_tree crontabs users groups processes port_scanner apt_history dpkg_history package_list firewall; do
  echo "<button class="collapsible">$func</button>"
  echo "<div class="content">"
  echo "<pre>"
  $func
  echo "</pre>"
  echo "</div>"
done)


<!--MANUALLY ADD SECTIONS HERE-->



  </div>
  <!--FOOTER-->
  <div id="footer">
    <pre>
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

<a class=link href="#top">Top</a> - <a class=link href="https://github.com/Daveed9/rosefish/">GitHub</a>
    </pre>
  </div>

  
<!--SCRIPT TO SHOW AND HIDE SECTIONS-->
<script>
var coll = document.getElementsByClassName("collapsible");
var i;
for (i = 0; i < coll.length; i++) {
  coll[i].addEventListener("click", function() {
    this.classList.toggle("active");
    var content = this.nextElementSibling;
    if (content.style.display === "block") {
      content.style.display = "none";
    } else {
      content.style.display = "block";
    }
  });
}
</script>


</body>
</html>
_EOF_
